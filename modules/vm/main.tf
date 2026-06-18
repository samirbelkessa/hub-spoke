# =============================================================================
# main.tf
# Architecture  : Hub & Spoke — MODULE
# Description   : Autonomous Windows VM reachable through Azure Bastion (private,
#                 no public IP on the VM). Creates VM subnet, NSG, NIC, VM and
#                 optionally the Bastion subnet + public IP + host.
# Agent         : network / security
# Dernière MAJ  : 2026-06-18
# =============================================================================

# ── SUBNETS ────────────────────────────────────────────────────────────────────

resource "azurerm_subnet" "vm" {
  name                 = var.subnet_vm_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_vm_address_prefix]
}

# AzureBastionSubnet — nom imposé par Azure, /26 minimum. Aucun NSG custom requis.
resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  name                 = var.subnet_bastion_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_bastion_address_prefix]
}

# ── NSG (VM SUBNET) ────────────────────────────────────────────────────────────
# La VM n'a pas d'IP publique : seul l'accès RDP depuis le VNet (donc depuis le
# sous-réseau Bastion) est autorisé. Tout le reste est refusé en entrée.

resource "azurerm_network_security_group" "vm" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { resource_type = "network_security_group" })

  security_rule {
    name                       = "Allow-Bastion-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Internet-Out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# ── NETWORK INTERFACE ──────────────────────────────────────────────────────────

resource "azurerm_network_interface" "vm" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { resource_type = "network_interface" })

  ip_configuration {
    name                          = "ipconfig-default"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    # Pas d'IP publique : la VM n'est joignable que via Bastion.
  }
}

# ── WINDOWS VIRTUAL MACHINE ────────────────────────────────────────────────────

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_name
  computer_name         = var.vm_computer_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm.id]
  tags                  = merge(var.tags, { resource_type = "windows_virtual_machine" })

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
}

# ── AZURE BASTION ──────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = var.pip_bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static" # imposé par Bastion
  sku                 = "Standard"
  tags                = merge(var.tags, { resource_type = "public_ip" })
}

resource "azurerm_bastion_host" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku
  tags                = merge(var.tags, { resource_type = "bastion_host" })

  ip_configuration {
    name                 = "ipconfig-default"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}
