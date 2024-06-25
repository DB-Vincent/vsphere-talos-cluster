resource "talos_machine_secrets" "this" {
  talos_version = "v${var.talos_version}"
}

data "talos_machine_configuration" "control_plane" {
  for_each = local.control_plane_node_names

  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
        }
        network = {
          hostname = each.value
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = ["${cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum + index(tolist(local.control_plane_node_names), each.value))}/${tonumber(split("/", var.cluster_network_cidr)[1])}"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = var.cluster_node_network_gateway
                }
              ]
              vip = {
                ip = var.cluster_vip
              }
            }
          ]
          nameservers = var.cluster_node_network_nameservers
        }
      }
      cluster = {
        discovery = {
          enabled = true
          registries = {
            kubernetes = {
              disabled = false
            }
            service = {
              disabled = true
            }
          }
        }
      }
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  for_each = local.worker_node_names

  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
        }
        network = {
          hostname = each.value
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = ["${cidrhost(var.cluster_network_cidr, var.cluster_network_first_worker_hostnum + index(tolist(local.worker_node_names), each.value))}/${tonumber(split("/", var.cluster_network_cidr)[1])}"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = var.cluster_node_network_gateway
                }
              ]
            }
          ]
          nameservers = var.cluster_node_network_nameservers
        }
      }
      cluster = {
        discovery = {
          enabled = true
          registries = {
            kubernetes = {
              disabled = false
            }
            service = {
              disabled = true
            }
          }
        }
      }
    }),
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum)
  node                 = cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum)
  depends_on = [
    vsphere_virtual_machine.control_plane,
  ]
}

data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum)
  node                 = cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum)
  depends_on = [
    talos_machine_bootstrap.this,
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration

  endpoints = [
    for i in range(var.cluster_control_plane_count) : cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum + i)
  ]
  nodes = concat(
    [
      for i in range(var.cluster_control_plane_count) : cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum + i)
    ],
    [
      for i in range(var.cluster_worker_count) : cidrhost(var.cluster_network_cidr, var.cluster_network_first_worker_hostnum + i)
    ]
  )
}

resource "local_file" "kubeconfig" {
  content  = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "kubeconfig"
}

resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "talosconfig"
}

resource "vsphere_folder" "this" {
  path          = var.cluster_name
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.this.id
}

resource "vsphere_virtual_machine" "control_plane" {
  for_each = local.control_plane_node_names
  name     = each.value
  folder   = "${var.vsphere_datacenter}/vm/${var.cluster_name}"

  datastore_id     = data.vsphere_datastore.this.id
  datacenter_id    = data.vsphere_datacenter.this.id
  host_system_id   = data.vsphere_host.this.id
  resource_pool_id = data.vsphere_resource_pool.this.id

  wait_for_guest_net_timeout = -1

  num_cpus = 2
  memory   = 4096

  ovf_deploy {
    remote_ovf_url = local.talos_template_url
  }

  disk {
    label = "disk0"
    size  = 10
  }

  network_interface {
    network_id = data.vsphere_network.this.id
  }

  enable_disk_uuid = "true"

  extra_config = {
    "guestinfo.talos.config" = base64encode(data.talos_machine_configuration.control_plane[each.value].machine_configuration)
  }

  depends_on = [vsphere_folder.this]

  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      folder,
      disk[0].io_share_count,
      disk[0].thin_provisioned
    ]
  }
}

resource "vsphere_virtual_machine" "worker" {
  for_each = local.worker_node_names
  name     = each.value
  folder   = "${var.vsphere_datacenter}/vm/${var.cluster_name}"

  datastore_id     = data.vsphere_datastore.this.id
  datacenter_id    = data.vsphere_datacenter.this.id
  host_system_id   = data.vsphere_host.this.id
  resource_pool_id = data.vsphere_resource_pool.this.id

  wait_for_guest_net_timeout = -1

  num_cpus = 4
  memory   = 8192

  ovf_deploy {
    remote_ovf_url = local.talos_template_url
  }

  disk {
    label = "disk0"
    size  = 10
  }

  network_interface {
    network_id = data.vsphere_network.this.id
  }

  enable_disk_uuid = "true"

  extra_config = {
    "guestinfo.talos.config" = base64encode(data.talos_machine_configuration.worker[each.value].machine_configuration)
  }

  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      folder,
      disk[0].io_share_count,
      disk[0].thin_provisioned
    ]
  }

  depends_on = [vsphere_folder.this]
}