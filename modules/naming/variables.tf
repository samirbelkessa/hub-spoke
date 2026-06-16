# =============================================================================
# variables.tf
# Architecture  : Hub & Spoke — MODULE
# Description   : Input variables for the shared naming module
# Agent         : architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
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
