# =============================================================================
# main.tf
# Architecture  : Hub & Spoke — SPOKE (vm-spoke autonome)
# Description   : RG + VNet + Windows VM reachable via Azure Bastion (module vm)
# Agent         : architecture / network
# Dernière MAJ  : 2026-06-18
# =============================================================================

module "naming" {
  source         = "../modules/naming"
  environment    = var.environment
  location_short = var.location_short
  workload       = var.workload
  instance       = var.instance
}

# ── RESOURCE GROUP ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "vm" {
  name     = module.naming.rg_vm
  location = var.location
  tags     = merge(var.tags, { resource_type = "resource_group" })

  lifecycle {
    prevent_destroy = true
  }
}

# ── VNET ──────────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "vm" {
  name                = module.naming.vnet_vm
  location            = var.location
  resource_group_name = azurerm_resource_group.vm.name
  address_space       = var.vnet_address_space
  tags                = merge(var.tags, { resource_type = "virtual_network" })
}

# ── VM + BASTION ──────────────────────────────────────────────────────────────

module "vm" {
  source = "../modules/vm"

  resource_group_name           = azurerm_resource_group.vm.name
  location                      = var.location
  virtual_network_name          = azurerm_virtual_network.vm.name
  subnet_vm_address_prefix      = var.subnet_vm_prefix
  subnet_bastion_address_prefix = var.subnet_bastion_prefix

  # Noms — source de vérité unique : module naming
  vm_name             = module.naming.vm
  vm_computer_name    = module.naming.vm_computer
  nic_name            = module.naming.nic_vm
  nsg_name            = module.naming.nsg_vm
  subnet_vm_name      = module.naming.subnet_vm
  subnet_bastion_name = module.naming.subnet_bastion
  bastion_name        = module.naming.bastion
  pip_bastion_name    = module.naming.pip_bastion

  # VM
  vm_size        = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password # via TF_VAR_admin_password

  # Bastion
  enable_bastion = var.enable_bastion
  bastion_sku    = var.bastion_sku

  tags = var.tags
}
