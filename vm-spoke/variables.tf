# =============================================================================
# variables.tf
# Architecture  : Hub & Spoke — SPOKE (vm-spoke autonome)
# Description   : All input variables for the vm-spoke root module
# Agent         : architecture
# Dernière MAJ  : 2026-06-18
# =============================================================================

# ── SUBSCRIPTION ─────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure subscription ID hosting the VM. Pass via TF_VAR_subscription_id."
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
  description = "Azure region (allowed by policy: francecentral or westeurope)"
}

variable "location_short" {
  type        = string
  description = "Short code for the Azure region (e.g. frc)"

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

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the VM virtual network (e.g. [\"10.2.0.0/16\"])"
}

variable "subnet_vm_prefix" {
  type        = string
  description = "Address prefix for the VM subnet (e.g. 10.2.1.0/24)"
}

variable "subnet_bastion_prefix" {
  type        = string
  description = "Address prefix for AzureBastionSubnet — must be /26 or larger (e.g. 10.2.0.0/26)"
}

# ── VM ───────────────────────────────────────────────────────────────────────

variable "vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Size (SKU) of the virtual machine"
}

variable "admin_username" {
  type        = string
  description = "Administrator username for the Windows VM"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for the Windows VM. Pass via TF_VAR_admin_password — never commit."
}

# ── BASTION ──────────────────────────────────────────────────────────────────

variable "enable_bastion" {
  type        = bool
  default     = true
  description = "Whether to deploy Azure Bastion alongside the VM"
}

variable "bastion_sku" {
  type        = string
  default     = "Basic"
  description = "Azure Bastion SKU: Basic or Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "bastion_sku must be Basic or Standard."
  }
}

# ── TAGS ─────────────────────────────────────────────────────────────────────

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources via merge(var.tags, { resource_type = \"...\" })"
}
