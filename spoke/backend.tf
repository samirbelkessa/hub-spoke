# =============================================================================
# backend.tf
# Architecture  : Hub & Spoke — SPOKE
# Description   : Remote state backend (partial configuration)
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
#
# Terraform backend blocks do not support variable interpolation.
# Pass the values at init time via a backend config file:
#
#   terraform init -backend-config=backend.hcl
#
# backend.hcl (never commit this file):
#   resource_group_name  = "rg-tfstate"
#   storage_account_name = "sttfstatespoke001"
#   container_name       = "tfstate"
#
# =============================================================================

terraform {
  backend "azurerm" {
    key = "spoke.tfstate"
  }
}
