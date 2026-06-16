# =============================================================================
# providers.tf
# Architecture  : Hub & Spoke — HUB
# Description   : Terraform version constraints and Azure provider configuration
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

provider "azurerm" {
  features {}
  subscription_id = var.hub_subscription_id
}
