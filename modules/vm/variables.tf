# =============================================================================
# variables.tf
# Architecture  : Hub & Spoke — MODULE
# Description   : Input variables for the autonomous VM + Bastion module
# Agent         : architecture
# Dernière MAJ  : 2026-06-18
# =============================================================================

# ── PLACEMENT ──────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group hosting the VM, Bastion and subnets"
}

variable "location" {
  type        = string
  description = "Azure region (e.g. francecentral)"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the existing virtual network in which subnets are created"
}

variable "subnet_vm_address_prefix" {
  type        = string
  description = "Address prefix for the VM subnet (e.g. 10.2.1.0/24)"
}

variable "subnet_bastion_address_prefix" {
  type        = string
  description = "Address prefix for AzureBastionSubnet — must be /26 or larger (e.g. 10.2.0.0/26)"
}

# ── NAMING (fournis par le module naming) ──────────────────────────────────────

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine resource"
}

variable "vm_computer_name" {
  type        = string
  description = "Windows computer name (max 15 characters)"
}

variable "nic_name" {
  type        = string
  description = "Name of the VM network interface"
}

variable "nsg_name" {
  type        = string
  description = "Name of the NSG attached to the VM subnet"
}

variable "subnet_vm_name" {
  type        = string
  description = "Name of the VM subnet"
}

variable "subnet_bastion_name" {
  type        = string
  default     = "AzureBastionSubnet"
  description = "Name of the Bastion subnet — must be AzureBastionSubnet (Azure-imposed)"
}

variable "bastion_name" {
  type        = string
  description = "Name of the Azure Bastion host"
}

variable "pip_bastion_name" {
  type        = string
  description = "Name of the Azure Bastion public IP"
}

# ── VM ─────────────────────────────────────────────────────────────────────────

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

variable "os_disk_storage_account_type" {
  type        = string
  default     = "Premium_LRS"
  description = "Storage account type for the OS disk (e.g. Premium_LRS, StandardSSD_LRS)"
}

variable "image_publisher" {
  type        = string
  default     = "MicrosoftWindowsServer"
  description = "Publisher of the source image"
}

variable "image_offer" {
  type        = string
  default     = "WindowsServer"
  description = "Offer of the source image"
}

variable "image_sku" {
  type        = string
  default     = "2022-datacenter-azure-edition"
  description = "SKU of the source image"
}

variable "image_version" {
  type        = string
  default     = "latest"
  description = "Version of the source image"
}

# ── BASTION ────────────────────────────────────────────────────────────────────

variable "enable_bastion" {
  type        = bool
  default     = true
  description = "Whether to deploy Azure Bastion (subnet + public IP + host) alongside the VM"
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

# ── TAGS ───────────────────────────────────────────────────────────────────────

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources via merge(var.tags, { resource_type = \"...\" })"
}
