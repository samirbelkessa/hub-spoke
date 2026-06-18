# =============================================================================
# providers.tf
# Architecture  : Hub & Spoke — SPOKE (vm-spoke autonome)
# Description   : Terraform version constraints and single Azure provider
# Agent         : architecture
# Dernière MAJ  : 2026-06-18
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
  subscription_id = var.subscription_id
}
