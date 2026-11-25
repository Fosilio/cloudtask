output "vm_name" {
  description = "Name of the virtual machine"
  value       = libvirt_domain.vm.name
}

output "vm_ip" {
  description = "IPv4 address of the virtual machine"
  value       = libvirt_domain.vm.network_interface[0].addresses[0]
}

output "vm_user" {
  description = "SSH administrative user"
  value       = var.vm_user
}

output "ssh_command" {
  description = "Command for connecting to the VM"

  value = "ssh -i ${pathexpand("~/.ssh/cloudtask_ed25519")} ${var.vm_user}@${libvirt_domain.vm.network_interface[0].addresses[0]}"
}