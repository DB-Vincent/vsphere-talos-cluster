data "vsphere_datacenter" "this" {
  name = var.vsphere_datacenter
}

data "vsphere_host" "this" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_resource_pool" "this" {
  name          = var.vsphere_resource_pool == "" ? "${var.vsphere_host}/Resources" : var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_datastore" "this" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_network" "this" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.this.id
}


