# =============================================================================
# backend.tf
# Architecture  : Hub & Spoke — HUB
# Description   : Local state backend
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
#
# =============================================================================

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
