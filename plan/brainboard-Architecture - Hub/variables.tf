variable "appgw_private_ip" {
  description = "Static private IP address for the Application Gateway frontend (must be within hub_subnet_appgw_prefix)"
  type        = string
}

variable "backend_fqdns" {
  description = "FQDNs of the backend targets (spoke webapp private endpoint). Can be empty at initial hub deployment."
  type        = list(string)
  default     = []
}

variable "capacity_max" {
  description = "Maximum autoscale capacity for the Application Gateway"
  type        = number
  default     = 10
}

variable "capacity_min" {
  description = "Minimum autoscale capacity for the Application Gateway"
  type        = number
  default     = 1
}

variable "cookie_affinity" {
  description = "Cookie-based affinity for backend HTTP settings: Enabled or Disabled"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.cookie_affinity)
    error_message = "variable value does not match the validator"
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "variable value does not match the validator"
  }
}

variable "hub_subnet_appgw_prefix" {
  description = "Address prefix for the ApplicationGatewaySubnet (e.g. 10.0.1.0/24)"
  type        = string
}

variable "hub_subscription_id" {
  description = "Azure subscription ID for the hub"
  type        = string
  sensitive   = true
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network (e.g. [" 10.0.0.0 / 16 "])"
  type        = list(string)
}

variable "instance" {
  description = "3-digit instance number (e.g. 001)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "variable value does not match the validator"
  }
}

variable "location" {
  description = "Azure region for all hub resources (e.g. francecentral)"
  type        = string
}

variable "location_short" {
  description = "Short code for the Azure region (e.g. frc for France Central)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.location_short))
    error_message = "variable value does not match the validator"
  }
}

variable "managed_identity_ids" {
  description = "List of User Assigned Managed Identity IDs for the Application Gateway (required for Key Vault certificate access)"
  type        = list(string)
  default     = []
}

variable "pip_zones" {
  description = "Availability zones for the public IP"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "request_timeout" {
  description = "Backend request timeout in seconds"
  type        = number
  default     = 30
}

variable "require_sni" {
  description = "Whether to require SNI on the HTTPS listener"
  type        = bool
  default     = false
}

variable "ssl_certificate_key_vault_id" {
  description = "Key Vault secret ID for the SSL certificate. Leave empty to skip HTTPS listener creation."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Default tags to apply to all resources."
  type        = map(any)
}

variable "waf_mode" {
  description = "WAF mode: Detection or Prevention"
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "variable value does not match the validator"
  }
}

variable "waf_rule_set_version" {
  description = "OWASP rule set version for the WAF (e.g. 3.2)"
  type        = string
  default     = "3.2"
}

variable "workload" {
  description = "Short identifier for the workload, lowercase alphanumeric only"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload))
    error_message = "variable value does not match the validator"
  }
}

