# Module: vm

Autonomous module deploying a **Windows Server VM reachable exclusively through Azure Bastion**. The VM has **no public IP** — RDP access goes through the Bastion host, which is bundled in this module.

## What it creates

- VM subnet (+ NSG: RDP allowed only from `VirtualNetwork`, deny-all inbound otherwise)
- `AzureBastionSubnet` (`/26` minimum) — *only when `enable_bastion = true`*
- Network interface (private IP only)
- `azurerm_windows_virtual_machine`
- Azure Bastion public IP (Standard, static) + `azurerm_bastion_host` — *only when `enable_bastion = true`*

The virtual network and resource group are **not** created by this module — pass an existing VNet and RG (the `vm-spoke/` root module creates them).

## Traffic flow

```
Operator (browser, Azure Portal)
  → Azure Bastion (AzureBastionSubnet, public IP)
    → RDP over private IP
      → Windows VM (VM subnet, no public IP)
```

## Usage

```hcl
module "vm" {
  source = "../modules/vm"

  resource_group_name           = azurerm_resource_group.vm.name
  location                      = var.location
  virtual_network_name          = azurerm_virtual_network.vm.name
  subnet_vm_address_prefix      = var.subnet_vm_prefix
  subnet_bastion_address_prefix = var.subnet_bastion_prefix

  vm_name             = module.naming.vm
  vm_computer_name    = module.naming.vm_computer
  nic_name            = module.naming.nic_vm
  nsg_name            = module.naming.nsg_vm
  subnet_vm_name      = module.naming.subnet_vm
  subnet_bastion_name = module.naming.subnet_bastion
  bastion_name        = module.naming.bastion
  pip_bastion_name    = module.naming.pip_bastion

  admin_username = var.admin_username
  admin_password = var.admin_password # via TF_VAR_admin_password

  tags = var.tags
}
```

## Key inputs

| Name | Default | Description |
|------|---------|-------------|
| `vm_size` | `Standard_B2s` | VM SKU |
| `admin_username` | — | Windows admin username |
| `admin_password` | — | Windows admin password (**sensitive**, pass via `TF_VAR_admin_password`) |
| `image_sku` | `2022-datacenter-azure-edition` | Windows Server image SKU |
| `os_disk_storage_account_type` | `Premium_LRS` | OS disk type |
| `enable_bastion` | `true` | Deploy Bastion alongside the VM |
| `bastion_sku` | `Basic` | `Basic` or `Standard` |
| `subnet_bastion_address_prefix` | — | Must be `/26` or larger |

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` / `vm_name` | VM identifiers |
| `vm_private_ip_address` | Private IP (Bastion target) |
| `subnet_vm_id` / `nsg_vm_id` | VM subnet & NSG IDs |
| `bastion_id` | Bastion host ID (`null` when disabled) |
| `bastion_public_ip_address` | Bastion public IP (`null` when disabled) |
