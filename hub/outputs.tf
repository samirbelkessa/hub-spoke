# =============================================================================
# outputs.tf
# Architecture  : Hub & Spoke — HUB
# Description   : Hub outputs consumed by the spoke root module
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub.id
  description = "Resource ID of the hub virtual network"
}

output "hub_vnet_name" {
  value       = azurerm_virtual_network.hub.name
  description = "Name of the hub virtual network"
}

output "hub_subnet_appgw_id" {
  value       = azurerm_subnet.appgw.id
  description = "Resource ID of the ApplicationGatewaySubnet"
}

output "hub_rg_network_name" {
  value       = azurerm_resource_group.network.name
  description = "Name of the hub network resource group"
}

output "hub_rg_appgw_name" {
  value       = azurerm_resource_group.appgw.name
  description = "Name of the Application Gateway resource group"
}

output "hub_rg_pip_name" {
  value       = azurerm_resource_group.pip.name
  description = "Name of the public IP resource group"
}

output "appgw_id" {
  value       = azurerm_application_gateway.appgw.id
  description = "Resource ID of the Application Gateway"
}

output "appgw_name" {
  value       = azurerm_application_gateway.appgw.name
  description = "Name of the Application Gateway"
}

output "appgw_backend_address_pool_id" {
  value       = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id
  description = "Resource ID of the default Application Gateway backend address pool"
}

output "appgw_private_ip" {
  value       = var.appgw_private_ip
  description = "Private IP address of the Application Gateway frontend"
}

output "pip_appgw_address" {
  value       = azurerm_public_ip.appgw.ip_address
  description = "Public IP address of the Application Gateway"
}
