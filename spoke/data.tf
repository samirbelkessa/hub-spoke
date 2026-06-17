# =============================================================================
# data.tf
# Architecture  : Hub & Spoke — SPOKE
# Description   : Hub data sources — never use terraform_remote_state
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

data "azurerm_virtual_network" "hub" {
  provider            = azurerm.hub
  name                = var.hub_vnet_name
  resource_group_name = var.hub_rg_network_name
}

data "azurerm_application_gateway" "hub" {
  provider            = azurerm.hub
  name                = var.hub_appgw_name
  resource_group_name = var.hub_rg_appgw_name
}

data "azurerm_resource_group" "hub_network" {
  provider = azurerm.hub
  name     = var.hub_rg_network_name
}

# Identité courante (déployeur Terraform) — pour lui octroyer une access policy
# permettant d'écrire le secret de connection string dans le Key Vault.
data "azurerm_client_config" "current" {
  provider = azurerm.spoke
}

# Private DNS Zones centralisées dans le hub (RG dédié) — créées avant le spoke.
# Noms imposés par Azure, fournis par le module de nommage partagé.
data "azurerm_private_dns_zone" "sql" {
  provider            = azurerm.hub
  name                = module.naming.pdns_sql
  resource_group_name = var.hub_rg_dns_name
}

data "azurerm_private_dns_zone" "webapp" {
  provider            = azurerm.hub
  name                = module.naming.pdns_webapp
  resource_group_name = var.hub_rg_dns_name
}
