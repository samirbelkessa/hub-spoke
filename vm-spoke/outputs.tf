# =============================================================================
# outputs.tf
# Architecture  : Hub & Spoke — SPOKE (vm-spoke autonome)
# Description   : Outputs of the vm-spoke root module
# Agent         : architecture
# Dernière MAJ  : 2026-06-18
# =============================================================================

output "resource_group_name" {
  value       = azurerm_resource_group.vm.name
  description = "Name of the VM resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vm.id
  description = "Resource ID of the VM virtual network"
}

output "vm_name" {
  value       = module.vm.vm_name
  description = "Name of the virtual machine"
}

output "vm_private_ip_address" {
  value       = module.vm.vm_private_ip_address
  description = "Private IP address of the VM (reachable via Bastion)"
}

output "bastion_public_ip_address" {
  value       = module.vm.bastion_public_ip_address
  description = "Public IP address of the Azure Bastion host"
}
