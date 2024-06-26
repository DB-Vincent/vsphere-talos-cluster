variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "cluster_control_plane_count" {
  type        = number
  default     = 1
  description = "Number of control plane nodes that should be created"
}

variable "cluster_worker_count" {
  type        = number
  default     = 1
  description = "Number of worker nodes that should be created"
}

variable "cluster_vip" {
  type        = string
  description = "The virtual API which should be assigned to the control plane"
}

variable "cluster_endpoint" {
  type        = string
  description = "The kubernetes API server endpoint"
}

variable "cluster_network_cidr" {
  type        = string
  description = "The network CIDR range (in slash notation; e.g 10.0.0.0/24) for the cluster nodes"
}

variable "cluster_node_network_gateway" {
  description = "The gateway through which the cluster nodes should send their traffic"
  type        = string
}

variable "cluster_node_network_nameservers" {
  description = "The nameservers which should be used by the cluster nodes"
  type        = list(string)
}

variable "cluster_network_first_control_plane_hostnum" {
  description = "The first IP address (last octet) that should be used for the control plane nodes"
  type        = number
}

variable "cluster_network_first_worker_hostnum" {
  description = "The first IP address (last octet) that should be used for the worker nodes"
  type        = number
}

#
# Virtual machine configuration
#
variable "control_plane_disk_space" {
  type        = number
  default     = 8
  description = "Disk space (in GB) that should be added to the control plane virtual machines"
}

variable "control_plane_cpu" {
  type        = number
  default     = 2
  description = "CPU cores which should be assigned to the control plane virtual machines"
}

variable "control_plane_memory" {
  type        = number
  default     = 2048
  description = "Memory allocation (in MB) which should be assigned to the control plane virtual machines"
}

variable "worker_disk_space" {
  type        = number
  default     = 8
  description = "Disk space (in GB) that should be added to the worker node virtual machines"
}

variable "worker_cpu" {
  type        = number
  default     = 4
  description = "CPU cores which should be assigned to the worker node virtual machines"
}

variable "worker_memory" {
  type        = number
  default     = 8192
  description = "Memory allocation (in MB) which should be assigned to the worker node virtual machines"
}

#
# vSphere configuration
#
variable "vsphere_username" {
  type        = string
  description = "vSphere username used to authenticate with the target vSphere server"
}

variable "vsphere_password" {
  type        = string
  description = "vSphere password used to authenticate with the target vSphere server"
}

variable "vsphere_server" {
  type        = string
  description = "vSphere server url used to communicate with the target vSphere server"
}

variable "vsphere_datacenter" {
  type        = string
  description = "Name of the vSphere datacenter in which the cluster should be created"
}

variable "vsphere_resource_pool" {
  type        = string
  default     = ""
  description = "Name of the vSphere resource pool in which the cluster should be created"
}

variable "vsphere_host" {
  type        = string
  description = "Name of the vSphere host on which the cluster should be created"
}

variable "vsphere_datastore" {
  type        = string
  description = "Name of the vSphere datastore which should be used for the cluster's storage"
}

variable "vsphere_network" {
  type        = string
  description = "Name of the vSphere network which should be used for the cluster's network access"
}

#
# Talos version
#

variable "talos_version" {
  type        = string
  description = "Talos version used to retrieve the OVF template which will be used to start the nodes"

  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.talos_version))
    error_message = "Must be a version number."
  }
}