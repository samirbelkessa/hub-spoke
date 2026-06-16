# =============================================================================
# locals.tf
# Architecture  : Hub & Spoke — MODULE
# Description   : CAF naming locals — single source of truth for all resource names
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

locals {
  suffix = "${var.workload}-${var.environment}-${var.location_short}-${var.instance}"

  # ── HUB ────────────────────────────────────────────────────────────────────
  rg_network   = "rg-${local.suffix}-network"
  rg_appgw     = "rg-${local.suffix}-appgw"
  rg_pip       = "rg-${local.suffix}-pip"
  vnet_hub     = "vnet-${local.suffix}-hub"
  subnet_appgw = "ApplicationGatewaySubnet" # Azure-imposed name — cannot follow CAF pattern
  appgw        = "agw-${local.suffix}"
  pip_appgw    = "pip-agw-${local.suffix}"

  # ── SPOKE ──────────────────────────────────────────────────────────────────
  rg_spoke             = "rg-${local.suffix}-spoke"
  vnet_spoke           = "vnet-${local.suffix}-spoke"
  subnet_app           = "snet-${local.suffix}-app"
  subnet_pe            = "snet-${local.suffix}-pe"
  app_service_plan     = "asp-${local.suffix}"
  webapp               = "app-${local.suffix}"
  sql_server           = "sql-${local.suffix}"
  sql_database         = "sqldb-${local.suffix}"
  nsg_app              = "nsg-${local.suffix}-app"
  nsg_pe               = "nsg-${local.suffix}-pe"
  pe_sql               = "pe-sql-${local.suffix}"
  pe_webapp            = "pe-app-${local.suffix}"
  peering_spoke_to_hub = "peer-spoke-to-hub-${local.suffix}"
  peering_hub_to_spoke = "peer-hub-to-spoke-${local.suffix}"
  key_vault            = "kv-${substr(local.suffix, 0, min(21, length(local.suffix)))}" # max 24 chars
}
