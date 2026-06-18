# =============================================================================
# backend.tf
# Architecture  : Hub & Spoke — SPOKE (vm-spoke autonome)
# Description   : Local state backend
# Agent         : architecture
# Dernière MAJ  : 2026-06-18
# =============================================================================

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
