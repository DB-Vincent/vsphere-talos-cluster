resource "talos_machine_secrets" "this" {
  talos_version = "v${var.talos_version}"
}

data "talos_machine_configuration" "control_plane" {
  count = var.cluster_control_plane_count

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
          hostname = "${var.cluster_name}-control-plane-${count.index}"
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = ["${cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum + count.index)}/${tonumber(split("/", var.cluster_network_cidr)[1])}"]
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
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  count = var.cluster_control_plane_count

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
          hostname = "${var.cluster_name}-worker-${count.index}"
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = ["${cidrhost(var.cluster_network_cidr, var.cluster_network_first_worker_hostnum + count.index)}/${tonumber(split("/", var.cluster_network_cidr)[1])}"]
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
    }),
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    for i in range(var.cluster_control_plane_count) : cidrhost(var.cluster_network_cidr, var.cluster_network_first_control_plane_hostnum + i)
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

resource "local_file" "kubeconfig" {
  content  = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "kubeconfig"
}

resource "vsphere_folder" "this" {
  path          = var.cluster_name
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.this.id
}

resource "vsphere_virtual_machine" "control_plane" {
  count  = var.cluster_control_plane_count
  name   = "${var.cluster_name}-control-plane-${count.index}"
  folder = "${var.vsphere_datacenter}/vm/${var.cluster_name}"

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
    "guestinfo.talos.config" = base64encode(data.talos_machine_configuration.control_plane[count.index].machine_configuration)
  }

  depends_on = [vsphere_folder.this]

  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      folder,
      disk.0.io_share_count,
      disk.0.thin_provisioned
    ]
  }
}

resource "vsphere_virtual_machine" "worker" {
  count  = var.cluster_worker_count
  name   = "${var.cluster_name}-worker-${count.index}"
  folder = "${var.vsphere_datacenter}/vm/${var.cluster_name}"

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
    "guestinfo.talos.config" = base64encode(data.talos_machine_configuration.worker[count.index].machine_configuration)
  }

  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      folder,
      disk.0.io_share_count,
      disk.0.thin_provisioned
    ]
  }

  depends_on = [vsphere_folder.this]
}