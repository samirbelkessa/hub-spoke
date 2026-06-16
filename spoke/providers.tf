# =============================================================================
# providers.tf
# Architecture  : Hub & Spoke — SPOKE
# Description   : Terraform version constraints and dual Azure provider configuration
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

# Default provider for spoke resources
provider "azurerm" {
  alias           = "spoke"
  features {}
  subscription_id = var.spoke_subscription_id
}

# Hub provider alias — used for cross-subscription VNet peering and data sources
provider "azurerm" {
  alias           = "hub"
  features {}
  subscription_id = var.hub_subscription_id
}
