# =============================================================================
# outputs.tf
# Architecture  : Hub & Spoke — MODULE
# Description   : Exposes all naming locals to hub and spoke root modules
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

# ── HUB ──────────────────────────────────────────────────────────────────────

output "rg_network" {
  value       = local.rg_network
  description = "Name of the hub network resource group"
}

output "rg_appgw" {
  value       = local.rg_appgw
  description = "Name of the Application Gateway resource group"
}

output "rg_pip" {
  value       = local.rg_pip
  description = "Name of the public IP resource group"
}

output "vnet_hub" {
  value       = local.vnet_hub
  description = "Name of the hub virtual network"
}

output "subnet_appgw" {
  value       = local.subnet_appgw
  description = "Name of the Application Gateway subnet (Azure-imposed: ApplicationGatewaySubnet)"
}

output "appgw" {
  value       = local.appgw
  description = "Name of the Application Gateway"
}

output "pip_appgw" {
  value       = local.pip_appgw
  description = "Name of the Application Gateway public IP"
}

output "waf_policy" {
  value       = local.waf_policy
  description = "Name of the Application Gateway WAF policy"
}

output "rg_dns" {
  value       = local.rg_dns
  description = "Name of the dedicated Private DNS resource group (hub)"
}

output "pdns_sql" {
  value       = local.pdns_sql
  description = "Name of the Azure SQL Private DNS zone (Azure-imposed)"
}

output "pdns_webapp" {
  value       = local.pdns_webapp
  description = "Name of the App Service Private DNS zone (Azure-imposed)"
}

# ── SPOKE ─────────────────────────────────────────────────────────────────────

output "rg_spoke" {
  value       = local.rg_spoke
  description = "Name of the spoke resource group"
}

output "vnet_spoke" {
  value       = local.vnet_spoke
  description = "Name of the spoke virtual network"
}

output "subnet_app" {
  value       = local.subnet_app
  description = "Name of the application subnet (VNet Integration)"
}

output "subnet_pe" {
  value       = local.subnet_pe
  description = "Name of the private endpoint subnet"
}

output "app_service_plan" {
  value       = local.app_service_plan
  description = "Name of the App Service Plan"
}

output "webapp" {
  value       = local.webapp
  description = "Name of the Linux Web App"
}

output "sql_server" {
  value       = local.sql_server
  description = "Name of the Azure SQL Server"
}

output "sql_database" {
  value       = local.sql_database
  description = "Name of the SQL Database"
}

output "nsg_app" {
  value       = local.nsg_app
  description = "Name of the NSG for the application subnet"
}

output "nsg_pe" {
  value       = local.nsg_pe
  description = "Name of the NSG for the private endpoint subnet"
}

output "pe_sql" {
  value       = local.pe_sql
  description = "Name of the SQL private endpoint"
}

output "pe_webapp" {
  value       = local.pe_webapp
  description = "Name of the webapp private endpoint"
}

output "peering_spoke_to_hub" {
  value       = local.peering_spoke_to_hub
  description = "Name of the VNet peering from spoke to hub"
}

output "peering_hub_to_spoke" {
  value       = local.peering_hub_to_spoke
  description = "Name of the VNet peering from hub to spoke"
}

output "key_vault" {
  value       = local.key_vault
  description = "Name of the Key Vault (truncated to 24 characters)"
}
