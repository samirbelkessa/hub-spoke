output "spoke_vnet_id" {
  description = "Resource ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.name
}

output "rg_spoke_name" {
  description = "Name of the spoke resource group"
  value       = azurerm_resource_group.spoke.name
}

output "webapp_hostname" {
  description = "Default hostname of the Linux Web App"
  value       = azurerm_linux_web_app.webapp.default_hostname
}

output "webapp_principal_id" {
  description = "System Assigned Managed Identity principal ID of the Web App"
  value       = azurerm_linux_web_app.webapp.identity[0].principal_id
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.spoke.vault_uri
}

output "pe_webapp_private_ip" {
  description = "Private IP address of the webapp private endpoint"
  value       = azurerm_private_endpoint.webapp.private_service_connection[0].private_ip_address
}

output "pe_sql_private_ip" {
  description = "Private IP address of the SQL private endpoint"
  value       = azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address
}

