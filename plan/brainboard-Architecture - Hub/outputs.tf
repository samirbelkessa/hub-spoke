output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "hub_subnet_appgw_id" {
  description = "Resource ID of the ApplicationGatewaySubnet"
  value       = azurerm_subnet.appgw.id
}

output "hub_rg_network_name" {
  description = "Name of the hub network resource group"
  value       = azurerm_resource_group.network.name
}

output "hub_rg_appgw_name" {
  description = "Name of the Application Gateway resource group"
  value       = azurerm_resource_group.appgw.name
}

output "hub_rg_pip_name" {
  description = "Name of the public IP resource group"
  value       = azurerm_resource_group.pip.name
}

output "appgw_id" {
  description = "Resource ID of the Application Gateway"
  value       = azurerm_application_gateway.appgw.id
}

output "appgw_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.appgw.name
}

output "appgw_backend_address_pool_id" {
  description = "Resource ID of the default Application Gateway backend address pool"
  value       = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id
}

output "appgw_private_ip" {
  description = "Private IP address of the Application Gateway frontend"
  value       = var.appgw_private_ip
}

output "pip_appgw_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "hub_rg_dns_name" {
  description = "Name of the dedicated Private DNS resource group"
  value       = azurerm_resource_group.dns.name
}

output "private_dns_zone_sql_id" {
  description = "Resource ID of the Azure SQL Private DNS zone"
  value       = azurerm_private_dns_zone.sql.id
}

output "private_dns_zone_webapp_id" {
  description = "Resource ID of the App Service Private DNS zone"
  value       = azurerm_private_dns_zone.webapp.id
}

