# =============================================================================
# variables.tf
# Architecture  : Hub & Spoke — SPOKE
# Description   : All input variables for the spoke root module
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

# ── SUBSCRIPTIONS ─────────────────────────────────────────────────────────────

variable "spoke_subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure subscription ID for the spoke"
}

variable "hub_subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure subscription ID for the hub (required for cross-subscription peering and data sources)"
}

variable "tenant_id" {
  type        = string
  sensitive   = true
  description = "Azure AD tenant ID (required for Key Vault access policies)"
}

# ── NAMING ───────────────────────────────────────────────────────────────────

variable "environment" {
  type        = string
  description = "Deployment environment — must match hub value"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all spoke resources (e.g. francecentral)"
}

variable "location_short" {
  type        = string
  description = "Short code for the Azure region — must match hub value (e.g. frc)"

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.location_short))
    error_message = "location_short must be 2-6 lowercase letters."
  }
}

variable "workload" {
  type        = string
  description = "Short identifier for the workload — must match hub value"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload))
    error_message = "workload must be lowercase alphanumeric characters only."
  }
}

variable "instance" {
  type        = string
  description = "3-digit instance number — must match hub value (e.g. 001)"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "instance must be exactly 3 digits."
  }
}

# ── HUB REFERENCES ───────────────────────────────────────────────────────────

variable "hub_vnet_name" {
  type        = string
  description = "Name of the hub VNet (from hub output: hub_vnet_name)"
}

variable "hub_rg_network_name" {
  type        = string
  description = "Name of the hub network resource group (from hub output: hub_rg_network_name)"
}

variable "hub_appgw_name" {
  type        = string
  description = "Name of the hub Application Gateway (from hub output: appgw_name)"
}

variable "hub_rg_appgw_name" {
  type        = string
  description = "Name of the hub AppGW resource group (from hub output: hub_rg_appgw_name)"
}

variable "hub_rg_dns_name" {
  type        = string
  description = "Name of the hub dedicated Private DNS resource group (from hub output: hub_rg_dns_name)"
}

variable "hub_subnet_appgw_prefix" {
  type        = string
  description = "CIDR prefix of the hub ApplicationGatewaySubnet — used in NSG inbound rules"
}

# ── NETWORK ──────────────────────────────────────────────────────────────────

variable "spoke_vnet_address_space" {
  type        = list(string)
  description = "Address space for the spoke virtual network (e.g. [\"10.1.0.0/16\"])"
}

variable "spoke_subnet_app_prefix" {
  type        = string
  description = "Address prefix for the application subnet (e.g. 10.1.1.0/24)"
}

variable "spoke_subnet_pe_prefix" {
  type        = string
  description = "Address prefix for the private endpoint subnet (e.g. 10.1.2.0/24)"
}

# ── SECURITY / KEY VAULT ──────────────────────────────────────────────────────

variable "key_vault_sku" {
  type        = string
  default     = "standard"
  description = "Key Vault SKU: standard or premium"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "key_vault_sku must be standard or premium."
  }
}

variable "kv_soft_delete_days" {
  type        = number
  default     = 90
  description = "Number of days to retain soft-deleted Key Vault objects (7-90)"
}

variable "kv_purge_protection" {
  type        = bool
  default     = true
  description = "Enable purge protection on the Key Vault"
}

variable "kv_allowed_ips" {
  type        = list(string)
  default     = []
  description = "Additional IP addresses allowed through Key Vault network ACLs"
}

variable "sql_connection_string_secret" {
  type        = string
  sensitive   = true
  default     = ""
  description = "SQL connection string stored as a Key Vault secret. Pass via TF_VAR_sql_connection_string_secret."
}

# ── SQL ───────────────────────────────────────────────────────────────────────

variable "sql_admin_login" {
  type        = string
  sensitive   = true
  description = "SQL Server administrator login"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "SQL Server administrator password"
}

variable "sql_aad_admin_login" {
  type        = string
  description = "Display name of the Azure AD SQL administrator"
}

variable "sql_aad_admin_object_id" {
  type        = string
  description = "Object ID of the Azure AD SQL administrator user or group"
}

variable "sql_server_version" {
  type        = string
  default     = "12.0"
  description = "SQL Server version"
}

variable "sql_db_sku_name" {
  type        = string
  default     = "GP_Gen5_2"
  description = "SQL Database SKU name (e.g. GP_Gen5_2, BC_Gen5_4)"
}

variable "sql_max_size_gb" {
  type        = number
  default     = 32
  description = "SQL Database maximum size in GB"
}

# ── APP SERVICE ───────────────────────────────────────────────────────────────

variable "asp_os_type" {
  type        = string
  default     = "Linux"
  description = "App Service Plan OS type"

  validation {
    condition     = contains(["Linux", "Windows"], var.asp_os_type)
    error_message = "asp_os_type must be Linux or Windows."
  }
}

variable "asp_sku_name" {
  type        = string
  default     = "P1v3"
  description = "App Service Plan SKU (e.g. P1v3, P2v3, P3v3)"
}

# ── TAGS ─────────────────────────────────────────────────────────────────────

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources via merge(var.tags, { resource_type = \"...\" })"
}
