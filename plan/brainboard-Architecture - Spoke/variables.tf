variable "asp_os_type" {
  description = "App Service Plan OS type"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.asp_os_type)
    error_message = "variable value does not match the validator"
  }
}

variable "asp_sku_name" {
  description = "App Service Plan SKU (e.g. P1v3, P2v3, P3v3)"
  type        = string
  default     = "P1v3"
}

variable "environment" {
  description = "Deployment environment — must match hub value"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "variable value does not match the validator"
  }
}

variable "hub_appgw_name" {
  description = "Name of the hub Application Gateway (from hub output: appgw_name)"
  type        = string
}

variable "hub_rg_appgw_name" {
  description = "Name of the hub AppGW resource group (from hub output: hub_rg_appgw_name)"
  type        = string
}

variable "hub_rg_dns_name" {
  description = "Name of the hub dedicated Private DNS resource group (from hub output: hub_rg_dns_name)"
  type        = string
}

variable "hub_rg_network_name" {
  description = "Name of the hub network resource group (from hub output: hub_rg_network_name)"
  type        = string
}

variable "hub_subnet_appgw_prefix" {
  description = "CIDR prefix of the hub ApplicationGatewaySubnet — used in NSG inbound rules"
  type        = string
}

variable "hub_subscription_id" {
  description = "Azure subscription ID for the hub (required for cross-subscription peering and data sources)"
  type        = string
  sensitive   = true
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet (from hub output: hub_vnet_name)"
  type        = string
}

variable "instance" {
  description = "3-digit instance number — must match hub value (e.g. 001)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "variable value does not match the validator"
  }
}

variable "key_vault_sku" {
  description = "Key Vault SKU: standard or premium"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "variable value does not match the validator"
  }
}

variable "kv_allowed_ips" {
  description = "Additional IP addresses allowed through Key Vault network ACLs"
  type        = list(string)
  default     = []
}

variable "kv_purge_protection" {
  description = "Enable purge protection on the Key Vault"
  type        = bool
  default     = true
}

variable "kv_soft_delete_days" {
  description = "Number of days to retain soft-deleted Key Vault objects (7-90)"
  type        = number
  default     = 90
}

variable "location" {
  description = "Azure region for all spoke resources (e.g. francecentral)"
  type        = string
}

variable "location_short" {
  description = "Short code for the Azure region — must match hub value (e.g. frc)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.location_short))
    error_message = "variable value does not match the validator"
  }
}

variable "spoke_subnet_app_prefix" {
  description = "Address prefix for the application subnet (e.g. 10.1.1.0/24)"
  type        = string
}

variable "spoke_subnet_pe_prefix" {
  description = "Address prefix for the private endpoint subnet (e.g. 10.1.2.0/24)"
  type        = string
}

variable "spoke_subscription_id" {
  description = "Azure subscription ID for the spoke"
  type        = string
  sensitive   = true
}

variable "spoke_vnet_address_space" {
  description = "Address space for the spoke virtual network"
  type        = list(string)
}

variable "sql_aad_admin_login" {
  description = "Display name of the Azure AD SQL administrator"
  type        = string
}

variable "sql_aad_admin_object_id" {
  description = "Object ID of the Azure AD SQL administrator user or group"
  type        = string
}

variable "sql_admin_login" {
  description = "SQL Server administrator login"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "sql_connection_string_secret" {
  description = "SQL connection string stored as a Key Vault secret. Pass via TF_VAR_sql_connection_string_secret."
  type        = string
  default     = ""
  sensitive   = true
}

variable "sql_db_sku_name" {
  description = "SQL Database SKU name (e.g. GP_Gen5_2, BC_Gen5_4)"
  type        = string
  default     = "GP_Gen5_2"
}

variable "sql_max_size_gb" {
  description = "SQL Database maximum size in GB"
  type        = number
  default     = 32
}

variable "sql_server_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "tags" {
  description = "Tags applied to all resources via merge"
  type        = map(string)
  default     = {}
}

variable "tenant_id" {
  description = "Azure AD tenant ID (required for Key Vault access policies)"
  type        = string
  sensitive   = true
}

variable "workload" {
  description = "Short identifier for the workload — must match hub value"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload))
    error_message = "variable value does not match the validator"
  }
}

