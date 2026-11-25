variable "vm_name" {
  description = "Name of the CloudTask virtual machine"
  type        = string
  default     = "cloudtask-server"
}

variable "vm_memory" {
  description = "Virtual machine memory in MiB"
  type        = number
  default     = 4096
}

variable "vm_vcpu" {
  description = "Number of virtual CPU cores"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Virtual disk size in GiB"
  type        = number
  default     = 20
}

variable "vm_user" {
  description = "Administrative user inside the VM"
  type        = string
  default     = "cloudadmin"
}

variable "storage_pool" {
  description = "Libvirt storage pool"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Libvirt virtual network"
  type        = string
  default     = "default"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/cloudtask_ed25519.pub"
}

variable "ubuntu_image_url" {
  description = "Ubuntu 24.04 LTS cloud image URL"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}