# =============================================================================
# variables.tf
# Architecture  : Hub & Spoke — HUB
# Description   : All input variables for the hub root module
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

# ── SUBSCRIPTION ─────────────────────────────────────────────────────────────

variable "hub_subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure subscription ID for the hub"
}

# ── NAMING ───────────────────────────────────────────────────────────────────

variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all hub resources (e.g. francecentral)"
}

variable "location_short" {
  type        = string
  description = "Short code for the Azure region (e.g. frc for France Central)"

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.location_short))
    error_message = "location_short must be 2-6 lowercase letters."
  }
}

variable "workload" {
  type        = string
  description = "Short identifier for the workload, lowercase alphanumeric only"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload))
    error_message = "workload must be lowercase alphanumeric characters only."
  }
}

variable "instance" {
  type        = string
  description = "3-digit instance number (e.g. 001)"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "instance must be exactly 3 digits."
  }
}

# ── NETWORK ──────────────────────────────────────────────────────────────────

variable "hub_vnet_address_space" {
  type        = list(string)
  description = "Address space for the hub virtual network (e.g. [\"10.0.0.0/16\"])"
}

variable "hub_subnet_appgw_prefix" {
  type        = string
  description = "Address prefix for the ApplicationGatewaySubnet (e.g. 10.0.1.0/24)"
}

variable "pip_zones" {
  type        = list(string)
  default     = ["1", "2", "3"]
  description = "Availability zones for the public IP"
}

variable "appgw_private_ip" {
  type        = string
  description = "Static private IP address for the Application Gateway frontend (must be within hub_subnet_appgw_prefix)"
}

# ── APPLICATION GATEWAY ───────────────────────────────────────────────────────

variable "capacity_min" {
  type        = number
  default     = 1
  description = "Minimum autoscale capacity for the Application Gateway"
}

variable "capacity_max" {
  type        = number
  default     = 10
  description = "Maximum autoscale capacity for the Application Gateway"
}

variable "waf_mode" {
  type        = string
  default     = "Prevention"
  description = "WAF mode: Detection or Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be Detection or Prevention."
  }
}

variable "waf_rule_set_version" {
  type        = string
  default     = "3.2"
  description = "OWASP rule set version for the WAF (e.g. 3.2)"
}

variable "backend_fqdns" {
  type        = list(string)
  default     = []
  description = "FQDNs of the backend targets (spoke webapp private endpoint). Can be empty at initial hub deployment."
}

variable "cookie_affinity" {
  type        = string
  default     = "Disabled"
  description = "Cookie-based affinity for backend HTTP settings: Enabled or Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.cookie_affinity)
    error_message = "cookie_affinity must be Enabled or Disabled."
  }
}

variable "request_timeout" {
  type        = number
  default     = 30
  description = "Backend request timeout in seconds"
}

variable "require_sni" {
  type        = bool
  default     = false
  description = "Whether to require SNI on the HTTPS listener"
}

variable "ssl_certificate_key_vault_id" {
  type        = string
  default     = ""
  description = "Key Vault secret ID for the SSL certificate. Leave empty to skip HTTPS listener creation."
}

variable "managed_identity_ids" {
  type        = list(string)
  default     = []
  description = "List of User Assigned Managed Identity IDs for the Application Gateway (required for Key Vault certificate access)"
}

# ── TAGS ─────────────────────────────────────────────────────────────────────

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources via merge(var.tags, { resource_type = \"...\" })"
}
