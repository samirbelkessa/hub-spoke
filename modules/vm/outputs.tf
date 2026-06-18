# =============================================================================
# outputs.tf
# Architecture  : Hub & Spoke — MODULE
# Description   : Outputs exposed by the VM + Bastion module
# Agent         : architecture
# Dernière MAJ  : 2026-06-18
# =============================================================================

output "vm_id" {
  value       = azurerm_windows_virtual_machine.vm.id
  description = "Resource ID of the virtual machine"
}

output "vm_name" {
  value       = azurerm_windows_virtual_machine.vm.name
  description = "Name of the virtual machine"
}

output "vm_private_ip_address" {
  value       = azurerm_network_interface.vm.private_ip_address
  description = "Private IP address of the VM (reachable via Bastion)"
}

output "subnet_vm_id" {
  value       = azurerm_subnet.vm.id
  description = "Resource ID of the VM subnet"
}

output "nsg_vm_id" {
  value       = azurerm_network_security_group.vm.id
  description = "Resource ID of the VM NSG"
}

output "bastion_id" {
  value       = var.enable_bastion ? azurerm_bastion_host.bastion[0].id : null
  description = "Resource ID of the Azure Bastion host (null when disabled)"
}

output "bastion_public_ip_address" {
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
  description = "Public IP address of the Azure Bastion host (null when disabled)"
}
