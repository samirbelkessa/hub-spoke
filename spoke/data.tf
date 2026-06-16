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
