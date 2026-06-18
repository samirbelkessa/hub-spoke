resource "azurerm_resource_group" "spoke" {
  provider = azurerm.spoke

  tags     = merge(var.tags, { resource_type = "resource_group" })
  name     = module.naming.rg_spoke
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network" "spoke" {
  provider = azurerm.spoke

  tags                = merge(var.tags, { resource_type = "virtual_network" })
  resource_group_name = azurerm_resource_group.spoke.name
  name                = module.naming.vnet_spoke
  location            = var.location
  address_space       = var.spoke_vnet_address_space
}

resource "azurerm_subnet" "app" {
  provider = azurerm.spoke

  virtual_network_name = azurerm_virtual_network.spoke.name
  resource_group_name  = azurerm_resource_group.spoke.name
  name                 = module.naming.subnet_app

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Web",
  ]

  address_prefixes = [
    var.spoke_subnet_app_prefix,
  ]

  delegation {
    name = "webapp-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_subnet" "pe" {
  provider = azurerm.spoke

  virtual_network_name              = azurerm_virtual_network.spoke.name
  resource_group_name               = azurerm_resource_group.spoke.name
  private_endpoint_network_policies = "Disabled"
  name                              = module.naming.subnet_pe

  address_prefixes = [
    var.spoke_subnet_pe_prefix,
  ]
}

resource "azurerm_network_security_group" "app" {
  provider = azurerm.spoke

  tags                = merge(var.tags, { resource_type = "network_security_group" })
  resource_group_name = azurerm_resource_group.spoke.name
  name                = module.naming.nsg_app
  location            = var.location

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = var.hub_subnet_appgw_prefix
    protocol                   = "Tcp"
    priority                   = 100
    name                       = "Allow-AppGW-HTTP"
    direction                  = "Inbound"
    destination_port_range     = "80"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
  }

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = var.hub_subnet_appgw_prefix
    protocol                   = "Tcp"
    priority                   = 110
    name                       = "Allow-AppGW-HTTPS"
    direction                  = "Inbound"
    destination_port_range     = "443"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
  }

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = "AzureLoadBalancer"
    protocol                   = "*"
    priority                   = 120
    name                       = "Allow-AzureLoadBalancer"
    direction                  = "Inbound"
    destination_port_range     = "*"
    destination_address_prefix = "*"
    access                     = "Allow"
  }

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = "*"
    protocol                   = "*"
    priority                   = 4096
    name                       = "Deny-All-Inbound"
    direction                  = "Inbound"
    destination_port_range     = "*"
    destination_address_prefix = "*"
    access                     = "Deny"
  }

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    protocol                   = "*"
    priority                   = 200
    name                       = "Allow-VNet-Out"
    direction                  = "Outbound"
    destination_port_range     = "*"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
  }

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = "*"
    protocol                   = "Tcp"
    priority                   = 210
    name                       = "Allow-Internet-Out"
    direction                  = "Outbound"
    destination_address_prefix = "Internet"
    access                     = "Allow"

    destination_port_ranges = [
      "80",
      "443",
    ]
  }
}

resource "azurerm_network_security_group" "pe" {
  provider = azurerm.spoke

  tags                = merge(var.tags, { resource_type = "network_security_group" })
  resource_group_name = azurerm_resource_group.spoke.name
  name                = module.naming.nsg_pe
  location            = var.location

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = var.spoke_subnet_app_prefix
    protocol                   = "Tcp"
    priority                   = 100
    name                       = "Allow-App-SQL"
    direction                  = "Inbound"
    destination_port_range     = "1433"
    destination_address_prefix = "*"
    access                     = "Allow"
  }

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = var.spoke_subnet_app_prefix
    protocol                   = "Tcp"
    priority                   = 110
    name                       = "Allow-App-HTTPS"
    direction                  = "Inbound"
    destination_port_range     = "443"
    destination_address_prefix = "*"
    access                     = "Allow"
  }

  security_rule {
    source_port_range          = "*"
    source_address_prefix      = "*"
    protocol                   = "*"
    priority                   = 4096
    name                       = "Deny-All-Inbound"
    direction                  = "Inbound"
    destination_port_range     = "*"
    destination_address_prefix = "*"
    access                     = "Deny"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  provider = azurerm.spoke

  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  provider = azurerm.spoke

  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.pe.id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  provider = azurerm.spoke

  virtual_network_name         = azurerm_virtual_network.spoke.name
  use_remote_gateways          = false
  resource_group_name          = azurerm_resource_group.spoke.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
  name                         = module.naming.peering_spoke_to_hub
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.hub

  virtual_network_name         = data.azurerm_virtual_network.hub.name
  resource_group_name          = data.azurerm_resource_group.hub_network.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  name                         = module.naming.peering_hub_to_spoke
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  allow_forwarded_traffic      = true
}

resource "azurerm_key_vault" "spoke" {
  provider = azurerm.spoke

  tenant_id                  = var.tenant_id
  tags                       = merge(var.tags, { resource_type = "key_vault" })
  soft_delete_retention_days = var.kv_soft_delete_days
  sku_name                   = var.key_vault_sku
  resource_group_name        = azurerm_resource_group.spoke.name
  purge_protection_enabled   = var.kv_purge_protection
  name                       = module.naming.key_vault
  location                   = var.location
  enable_rbac_authorization  = true

  lifecycle {
    prevent_destroy = true
  }

  network_acls {
    ip_rules       = var.kv_allowed_ips
    default_action = "Deny"
    bypass         = "AzureServices"

    virtual_network_subnet_ids = [
      azurerm_subnet.app.id,
    ]
  }
}

resource "azurerm_role_assignment" "webapp_kv_secrets" {
  provider = azurerm.spoke

  scope                = azurerm_key_vault.spoke.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}

resource "azurerm_role_assignment" "deployer_kv_secrets" {
  provider = azurerm.spoke

  scope                = azurerm_key_vault.spoke.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  provider = azurerm.spoke

  value        = var.sql_connection_string_secret
  name         = "sql-connection-string"
  key_vault_id = azurerm_key_vault.spoke.id

  depends_on = [
    azurerm_role_assignment.webapp_kv_secrets,
    azurerm_role_assignment.deployer_kv_secrets,
  ]
}

resource "azurerm_mssql_server" "sql" {
  provider = azurerm.spoke

  version                       = var.sql_server_version
  tags                          = merge(var.tags, { resource_type = "sql_server" })
  resource_group_name           = azurerm_resource_group.spoke.name
  public_network_access_enabled = false
  name                          = module.naming.sql_server
  minimum_tls_version           = "1.2"
  location                      = var.location
  administrator_login_password  = var.sql_admin_password
  administrator_login           = var.sql_admin_login

  azuread_administrator {
    object_id      = var.sql_aad_admin_object_id
    login_username = var.sql_aad_admin_login
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_database" "sql" {
  provider = azurerm.spoke

  tags        = merge(var.tags, { resource_type = "sql_database" })
  sku_name    = var.sql_db_sku_name
  server_id   = azurerm_mssql_server.sql.id
  name        = module.naming.sql_database
  max_size_gb = var.sql_max_size_gb
}

resource "azurerm_service_plan" "asp" {
  provider = azurerm.spoke

  tags                = merge(var.tags, { resource_type = "service_plan" })
  sku_name            = var.asp_sku_name
  resource_group_name = azurerm_resource_group.spoke.name
  os_type             = var.asp_os_type
  name                = module.naming.app_service_plan
  location            = var.location
}

resource "azurerm_linux_web_app" "webapp" {
  provider = azurerm.spoke

  virtual_network_subnet_id     = azurerm_subnet.app.id
  tags                          = merge(var.tags, { resource_type = "linux_web_app" })
  service_plan_id               = azurerm_service_plan.asp.id
  resource_group_name           = azurerm_resource_group.spoke.name
  public_network_access_enabled = false
  name                          = module.naming.webapp
  location                      = var.location
  https_only                    = true

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }

  connection_string {
    value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.spoke.name};SecretName=sql-connection-string)"
    type  = "SQLAzure"
    name  = "DefaultConnection"
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    http2_enabled       = true
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_sql" {
  provider = azurerm.spoke

  virtual_network_id    = azurerm_virtual_network.spoke.id
  tags                  = merge(var.tags, { resource_type = "private_dns_zone_vnet_link" })
  resource_group_name   = azurerm_resource_group.spoke.name
  registration_enabled  = false
  private_dns_zone_name = data.azurerm_private_dns_zone.sql.name
  name                  = "spoke-vnet-link"
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_webapp" {
  provider = azurerm.spoke

  virtual_network_id    = azurerm_virtual_network.spoke.id
  tags                  = merge(var.tags, { resource_type = "private_dns_zone_vnet_link" })
  resource_group_name   = azurerm_resource_group.spoke.name
  registration_enabled  = false
  private_dns_zone_name = data.azurerm_private_dns_zone.webapp.name
  name                  = "spoke-vnet-link"
}

resource "azurerm_private_endpoint" "sql" {
  provider = azurerm.spoke

  tags                = merge(var.tags, { resource_type = "private_endpoint" })
  subnet_id           = azurerm_subnet.pe.id
  resource_group_name = azurerm_resource_group.spoke.name
  name                = module.naming.pe_sql
  location            = var.location

  private_dns_zone_group {
    name = "pdnszg-sql"

    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.sql.id,
    ]
  }

  private_service_connection {
    private_connection_resource_id = azurerm_mssql_server.sql.id
    name                           = "psc-sql"
    is_manual_connection           = false

    subresource_names = [
      "sqlServer",
    ]
  }
}

resource "azurerm_private_endpoint" "webapp" {
  provider = azurerm.spoke

  tags                = merge(var.tags, { resource_type = "private_endpoint" })
  subnet_id           = azurerm_subnet.pe.id
  resource_group_name = azurerm_resource_group.spoke.name
  name                = module.naming.pe_webapp
  location            = var.location

  private_dns_zone_group {
    name = "pdnszg-webapp"

    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.webapp.id,
    ]
  }

  private_service_connection {
    private_connection_resource_id = azurerm_linux_web_app.webapp.id
    name                           = "psc-webapp"
    is_manual_connection           = false

    subresource_names = [
      "sites",
    ]
  }
}

data "azurerm_virtual_network" "hub" {
  provider = azurerm.hub

  resource_group_name = data.azurerm_resource_group.hub_network.name
  name                = var.hub_vnet_name
}

data "azurerm_application_gateway" "hub" {
  provider = azurerm.hub

  resource_group_name = var.hub_rg_appgw_name
  name                = var.hub_appgw_name
}

data "azurerm_resource_group" "hub_network" {
  provider = azurerm.hub

  name = var.hub_rg_network_name
}

data "azurerm_client_config" "current" {
  provider = azurerm.spoke

}

data "azurerm_private_dns_zone" "sql" {
  provider = azurerm.hub

  resource_group_name = var.hub_rg_dns_name
  name                = module.naming.pdns_sql
}

data "azurerm_private_dns_zone" "webapp" {
  provider = azurerm.hub

  resource_group_name = var.hub_rg_dns_name
  name                = module.naming.pdns_webapp
}

module "naming" {
  source = "../modules/naming"


  environment    = var.environment
  location_short = var.location_short
  workload       = var.workload
  instance       = var.instance

}

