#  vsphere-talos-cluster

This a template for deploying a Kubernetes cluster on a vSphere environment using Talos and Terraform. This project aims to simplify the setup and management of a highly available Kubernetes cluster with the benefits of Talos' secure and immutable operating system.

## Prerequisites

- vSphere user with permissions to create virtual machines
- Terraform installed ([instructions](https://developer.hashicorp.com/terraform/install?product_intent=terraform))
- Talosctl installed ([instructions](https://www.talos.dev/v1.7/talos-guides/install/talosctl/))
- Kubectl installed ([instructions](https://kubernetes.io/docs/tasks/tools/#kubectl))

## Getting started

1. **Clone the repository:**  

```shell
git clone https://github.com/yourusername/vsphere-talos-cluster.git  
cd vsphere-talos-cluster
```

2. **Configure Terraform variables:**  

Create a `terraform.tfvars` file andd fill in the desired configuration based on the required [inputs].(#inputs)  

3. **Initialize Terraform:**  

```shell
terraform init
```
4. **Apply Terraform configuration:**  

```shell
terraform plan -out plan.out # validate that there are no strange issues
terraform apply plan.out
```

5. **Configure Talos:** 

This template automatically creates a `talosconfig` file with the correct configuration. You can configure talosctl to use that by exporting the `TALOSCONFIG` environment variable and pointing it to the file like this:

```shell
export TALOSCONFIG=$(pwd)/talosconfig
```

After this, you should be able to use the talosctl to talk to your nodes (e.g. by executing `talosctl time`).

6. **Access your Kubernetes cluster:**  

Same as with for the `talosconfig` file, the template automatically creates a preconfigured `kubeconfig` file. This file can be used by exporting the KUBECONFIG environment variable and pointing it to the file like this: 

```shell
export KUBECONFIG=$(pwd)/kubeconfig
```

After this, you should be able to use the kubectl to talk to your cluster (e.g. by executing `kubectl get nodes`).

## Terraform code documentation

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | ~> 0.5 |
| <a name="requirement_vsphere"></a> [vsphere](#requirement\_vsphere) | ~> 2.8 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.1 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.5.0 |
| <a name="provider_vsphere"></a> [vsphere](#provider\_vsphere) | 2.8.1 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.talosconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [vsphere_folder.this](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/folder) | resource |
| [vsphere_virtual_machine.control_plane](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine) | resource |
| [vsphere_virtual_machine.worker](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/cluster_kubeconfig) | data source |
| [talos_machine_configuration.control_plane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |
| [vsphere_datacenter.this](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/data-sources/datacenter) | data source |
| [vsphere_datastore.this](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/data-sources/datastore) | data source |
| [vsphere_host.this](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/data-sources/host) | data source |
| [vsphere_network.this](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/data-sources/network) | data source |
| [vsphere_resource_pool.this](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/data-sources/resource_pool) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_control_plane_count"></a> [cluster\_control\_plane\_count](#input\_cluster\_control\_plane\_count) | Number of control plane nodes that should be created | `number` | `1` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | The kubernetes API server endpoint | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster | `string` | n/a | yes |
| <a name="input_cluster_network_cidr"></a> [cluster\_network\_cidr](#input\_cluster\_network\_cidr) | The network CIDR range (in slash notation; e.g 10.0.0.0/24) for the cluster nodes | `string` | n/a | yes |
| <a name="input_cluster_network_first_control_plane_hostnum"></a> [cluster\_network\_first\_control\_plane\_hostnum](#input\_cluster\_network\_first\_control\_plane\_hostnum) | The first IP address (last octet) that should be used for the control plane nodes | `number` | n/a | yes |
| <a name="input_cluster_network_first_worker_hostnum"></a> [cluster\_network\_first\_worker\_hostnum](#input\_cluster\_network\_first\_worker\_hostnum) | The first IP address (last octet) that should be used for the worker nodes | `number` | n/a | yes |
| <a name="input_cluster_node_network_gateway"></a> [cluster\_node\_network\_gateway](#input\_cluster\_node\_network\_gateway) | The gateway through which the cluster nodes should send their traffic | `string` | n/a | yes |
| <a name="input_cluster_node_network_nameservers"></a> [cluster\_node\_network\_nameservers](#input\_cluster\_node\_network\_nameservers) | The nameservers which should be used by the cluster nodes | `list(string)` | n/a | yes |
| <a name="input_cluster_vip"></a> [cluster\_vip](#input\_cluster\_vip) | The virtual API which should be assigned to the control plane | `string` | n/a | yes |
| <a name="input_cluster_worker_count"></a> [cluster\_worker\_count](#input\_cluster\_worker\_count) | Number of worker nodes that should be created | `number` | `1` | no |
| <a name="input_control_plane_cpu"></a> [control\_plane\_cpu](#input\_control\_plane\_cpu) | CPU cores which should be assigned to the control plane virtual machines | `number` | `2` | no |
| <a name="input_control_plane_disk_space"></a> [control\_plane\_disk\_space](#input\_control\_plane\_disk\_space) | Disk space (in GB) that should be added to the control plane virtual machines | `number` | `8` | no |
| <a name="input_control_plane_memory"></a> [control\_plane\_memory](#input\_control\_plane\_memory) | Memory allocation (in MB) which should be assigned to the control plane virtual machines | `number` | `2048` | no |
| <a name="input_talos_version"></a> [talos\_version](#input\_talos\_version) | Talos version used to retrieve the OVF template which will be used to start the nodes | `string` | n/a | yes |
| <a name="input_vsphere_datacenter"></a> [vsphere\_datacenter](#input\_vsphere\_datacenter) | Name of the vSphere datacenter in which the cluster should be created | `string` | n/a | yes |
| <a name="input_vsphere_datastore"></a> [vsphere\_datastore](#input\_vsphere\_datastore) | Name of the vSphere datastore which should be used for the cluster's storage | `string` | n/a | yes |
| <a name="input_vsphere_host"></a> [vsphere\_host](#input\_vsphere\_host) | Name of the vSphere host on which the cluster should be created | `string` | n/a | yes |
| <a name="input_vsphere_network"></a> [vsphere\_network](#input\_vsphere\_network) | Name of the vSphere network which should be used for the cluster's network access | `string` | n/a | yes |
| <a name="input_vsphere_password"></a> [vsphere\_password](#input\_vsphere\_password) | vSphere password used to authenticate with the target vSphere server | `string` | n/a | yes |
| <a name="input_vsphere_resource_pool"></a> [vsphere\_resource\_pool](#input\_vsphere\_resource\_pool) | Name of the vSphere resource pool in which the cluster should be created | `string` | `""` | no |
| <a name="input_vsphere_server"></a> [vsphere\_server](#input\_vsphere\_server) | vSphere server url used to communicate with the target vSphere server | `string` | n/a | yes |
| <a name="input_vsphere_username"></a> [vsphere\_username](#input\_vsphere\_username) | vSphere username used to authenticate with the target vSphere server | `string` | n/a | yes |
| <a name="input_worker_cpu"></a> [worker\_cpu](#input\_worker\_cpu) | CPU cores which should be assigned to the worker node virtual machines | `number` | `4` | no |
| <a name="input_worker_disk_space"></a> [worker\_disk\_space](#input\_worker\_disk\_space) | Disk space (in GB) that should be added to the worker node virtual machines | `number` | `8` | no |
| <a name="input_worker_memory"></a> [worker\_memory](#input\_worker\_memory) | Memory allocation (in MB) which should be assigned to the worker node virtual machines | `number` | `8192` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any changes or enhancements.

## Acknowledgements

- [Talos Systems](https://www.talos.dev/)
- [HashiCorp Terraform](https://www.terraform.io/)

---

Feel free to contact me for any further questions or support. Happy clustering 🖥️!