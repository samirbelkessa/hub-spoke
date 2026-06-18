# =============================================================================
# providers.tf
# Architecture  : Hub & Spoke — MODULE
# Description   : Provider requirements for the VM + Bastion module
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
