# =============================================================================
# outputs.tf
# Architecture  : Hub & Spoke — SPOKE
# Description   : Spoke outputs for operational reference and cross-stack consumption
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

output "spoke_vnet_id" {
  value       = azurerm_virtual_network.spoke.id
  description = "Resource ID of the spoke virtual network"
}

output "spoke_vnet_name" {
  value       = azurerm_virtual_network.spoke.name
  description = "Name of the spoke virtual network"
}

output "rg_spoke_name" {
  value       = azurerm_resource_group.spoke.name
  description = "Name of the spoke resource group"
}

output "webapp_hostname" {
  value       = azurerm_linux_web_app.webapp.default_hostname
  description = "Default hostname of the Linux Web App"
}

output "webapp_principal_id" {
  value       = azurerm_linux_web_app.webapp.identity[0].principal_id
  description = "System Assigned Managed Identity principal ID of the Web App"
}

output "sql_server_fqdn" {
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
  description = "Fully qualified domain name of the SQL Server"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.spoke.vault_uri
  description = "URI of the Key Vault"
}

output "pe_webapp_private_ip" {
  value       = azurerm_private_endpoint.webapp.private_service_connection[0].private_ip_address
  description = "Private IP address of the webapp private endpoint"
}

output "pe_sql_private_ip" {
  value       = azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address
  description = "Private IP address of the SQL private endpoint"
}
