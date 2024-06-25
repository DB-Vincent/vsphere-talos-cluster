locals {
  talos_template_url = "https://github.com/talos-systems/talos/releases/download/v${var.talos_version}/vmware-amd64.ova"

  control_plane_node_names = toset([for i in range(var.cluster_control_plane_count) : format("%s%d", "${var.cluster_name}-control-plane-", i + 1)])
  worker_node_names        = toset([for i in range(var.cluster_worker_count) : format("%s%d", "${var.cluster_name}-worker-", i + 1)])
}
