# Base Ubuntu cloud image
resource "libvirt_volume" "base" {
  name   = "${var.vm_name}-base.qcow2"
  pool   = var.storage_pool
  format = "qcow2"
  source = var.ubuntu_image_url
}

# Virtual machine disk
resource "libvirt_volume" "disk" {
  name           = "${var.vm_name}.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.base.id
  size           = var.vm_disk_size * 1024 * 1024 * 1024
}

# Cloud-init configuration
resource "libvirt_cloudinit_disk" "init" {
  name = "${var.vm_name}-init.iso"
  pool = var.storage_pool

  user_data = templatefile(
    "${path.module}/../../cloud-init/user-data.tftpl",
    {
      hostname = var.vm_name
      username = var.vm_user
      ssh_key  = trimspace(file(pathexpand(var.ssh_public_key_path)))
    }
  )
}

# Virtual machine
resource "libvirt_domain" "vm" {
  name      = var.vm_name
  memory    = var.vm_memory
  vcpu      = var.vm_vcpu
  cloudinit = libvirt_cloudinit_disk.init.id

  disk {
    volume_id = libvirt_volume.disk.id
  }

  network_interface {
    network_name   = var.network_name
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}