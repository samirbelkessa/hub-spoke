# =============================================================================
# main.tf
# Architecture  : Hub & Spoke — SPOKE
# Description   : Spoke resources: network, security, Key Vault, SQL, WebApp, Private Endpoints
# Agent         : network / security / architecture
# Dernière MAJ  : 2026-06-16
# =============================================================================

module "naming" {
  source         = "../modules/naming"
  environment    = var.environment
  location_short = var.location_short
  workload       = var.workload
  instance       = var.instance
}

# ── DATA SOURCES HUB ──────────────────────────────────────────────────────────
# Lecture des ressources hub — jamais terraform_remote_state.

data "azurerm_virtual_network" "hub" {
  provider            = azurerm.hub
  name                = var.hub_vnet_name
  resource_group_name = var.hub_rg_network_name
}

data "azurerm_application_gateway" "hub" {
  provider            = azurerm.hub
  name                = var.hub_appgw_name
  resource_group_name = var.hub_rg_appgw_name
}

data "azurerm_resource_group" "hub_network" {
  provider = azurerm.hub
  name     = var.hub_rg_network_name
}

# Identité courante (déployeur Terraform) — pour lui octroyer une access policy
# permettant d'écrire le secret de connection string dans le Key Vault.
data "azurerm_client_config" "current" {
  provider = azurerm.spoke
}

# Private DNS Zones centralisées dans le hub (RG dédié) — créées avant le spoke.
# Noms imposés par Azure, fournis par le module de nommage partagé.
data "azurerm_private_dns_zone" "sql" {
  provider            = azurerm.hub
  name                = module.naming.pdns_sql
  resource_group_name = var.hub_rg_dns_name
}

data "azurerm_private_dns_zone" "webapp" {
  provider            = azurerm.hub
  name                = module.naming.pdns_webapp
  resource_group_name = var.hub_rg_dns_name
}

# ── RESOURCE GROUP ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "spoke" {
  provider = azurerm.spoke
  name     = module.naming.rg_spoke
  location = var.location
  tags     = merge(var.tags, { resource_type = "resource_group" })

  lifecycle {
    prevent_destroy = true
  }
}

# ── SPOKE VNET ────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "spoke" {
  provider            = azurerm.spoke
  name                = module.naming.vnet_spoke
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = var.spoke_vnet_address_space
  tags                = merge(var.tags, { resource_type = "virtual_network" })
}

# Subnet for WebApp VNet Integration
# Delegation to Microsoft.Web/serverFarms + service endpoints for KV, SQL, Web
resource "azurerm_subnet" "app" {
  provider             = azurerm.spoke
  name                 = module.naming.subnet_app
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.spoke_subnet_app_prefix]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Sql", "Microsoft.Web"]

  delegation {
    name = "webapp-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "pe" {
  provider                                      = azurerm.spoke
  name                                          = module.naming.subnet_pe
  resource_group_name                           = azurerm_resource_group.spoke.name
  virtual_network_name                          = azurerm_virtual_network.spoke.name
  address_prefixes                              = [var.spoke_subnet_pe_prefix]
  private_endpoint_network_policies = "Disabled"
}

# ── NETWORK SECURITY GROUPS ───────────────────────────────────────────────────

resource "azurerm_network_security_group" "app" {
  provider            = azurerm.spoke
  name                = module.naming.nsg_app
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = merge(var.tags, { resource_type = "network_security_group" })

  # INBOUND — only AppGW subnet can reach the webapp
  security_rule {
    name                       = "Allow-AppGW-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.hub_subnet_appgw_prefix
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow-AppGW-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.hub_subnet_appgw_prefix
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
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

  # OUTBOUND
  security_rule {
    name                       = "Allow-VNet-Out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow-Internet-Out"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_network_security_group" "pe" {
  provider            = azurerm.spoke
  name                = module.naming.nsg_pe
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = merge(var.tags, { resource_type = "network_security_group" })

  # INBOUND — only app subnet can reach PE resources
  security_rule {
    name                       = "Allow-App-SQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.spoke_subnet_app_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-App-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.spoke_subnet_app_prefix
    destination_address_prefix = "*"
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
}

resource "azurerm_subnet_network_security_group_association" "app" {
  provider                  = azurerm.spoke
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  provider                  = azurerm.spoke
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.pe.id
}

# ── VNET PEERING ─────────────────────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  provider                     = azurerm.spoke
  name                         = module.naming.peering_spoke_to_hub
  resource_group_name          = azurerm_resource_group.spoke.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

# Cross-subscription peering — uses hub provider alias
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider                     = azurerm.hub
  name                         = module.naming.peering_hub_to_spoke
  resource_group_name          = data.azurerm_resource_group.hub_network.name
  virtual_network_name         = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# ── KEY VAULT ─────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "spoke" {
  provider                   = azurerm.spoke
  name                       = module.naming.key_vault
  location                   = var.location
  resource_group_name        = azurerm_resource_group.spoke.name
  tenant_id                  = var.tenant_id
  sku_name                   = var.key_vault_sku
  soft_delete_retention_days = var.kv_soft_delete_days
  purge_protection_enabled   = var.kv_purge_protection
  enable_rbac_authorization  = true # autorisation par RBAC uniquement — pas d'access policies
  tags                       = merge(var.tags, { resource_type = "key_vault" })

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
    ip_rules                   = var.kv_allowed_ips
  }

  lifecycle {
    prevent_destroy = true
  }
}

# RBAC — webapp System Assigned MSI : lecture des secrets (Key Vault Secrets User)
resource "azurerm_role_assignment" "webapp_kv_secrets" {
  provider             = azurerm.spoke
  scope                = azurerm_key_vault.spoke.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}

# RBAC — déployeur Terraform : gestion des secrets (Key Vault Secrets Officer)
# nécessaire pour écrire le secret ci-dessous
resource "azurerm_role_assignment" "deployer_kv_secrets" {
  provider             = azurerm.spoke
  scope                = azurerm_key_vault.spoke.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  provider     = azurerm.spoke
  name         = "sql-connection-string"
  value        = var.sql_connection_string_secret
  key_vault_id = azurerm_key_vault.spoke.id

  depends_on = [
    azurerm_role_assignment.webapp_kv_secrets,
    azurerm_role_assignment.deployer_kv_secrets,
  ]
}

# ── SQL ───────────────────────────────────────────────────────────────────────

resource "azurerm_mssql_server" "sql" {
  provider                      = azurerm.spoke
  name                          = module.naming.sql_server
  resource_group_name           = azurerm_resource_group.spoke.name
  location                      = var.location
  version                       = var.sql_server_version
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = merge(var.tags, { resource_type = "sql_server" })

  azuread_administrator {
    login_username = var.sql_aad_admin_login
    object_id      = var.sql_aad_admin_object_id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_database" "sql" {
  provider    = azurerm.spoke
  name        = module.naming.sql_database
  server_id   = azurerm_mssql_server.sql.id
  sku_name    = var.sql_db_sku_name
  max_size_gb = var.sql_max_size_gb
  tags        = merge(var.tags, { resource_type = "sql_database" })
}

# ── APP SERVICE ───────────────────────────────────────────────────────────────

resource "azurerm_service_plan" "asp" {
  provider            = azurerm.spoke
  name                = module.naming.app_service_plan
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  os_type             = var.asp_os_type
  sku_name            = var.asp_sku_name
  tags                = merge(var.tags, { resource_type = "service_plan" })
}

resource "azurerm_linux_web_app" "webapp" {
  provider                      = azurerm.spoke
  name                          = module.naming.webapp
  location                      = var.location
  resource_group_name           = azurerm_resource_group.spoke.name
  service_plan_id               = azurerm_service_plan.asp.id
  https_only                    = true
  public_network_access_enabled = false
  virtual_network_subnet_id     = azurerm_subnet.app.id
  tags                          = merge(var.tags, { resource_type = "linux_web_app" })

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    http2_enabled       = true
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  # Le préfixe SQLCONNSTR_ est réservé : la connection string passe par un bloc dédié,
  # qui expose automatiquement la variable d'env SQLCONNSTR_DefaultConnection.
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.spoke.name};SecretName=sql-connection-string)"
  }
}

# ── PRIVATE DNS — LIENS VNET SPOKE (zones centralisées dans le hub) ───────────
# Les zones vivent dans la souscription hub → provider = azurerm.hub.
# Permettent au VNet spoke (webapp en VNet Integration) de résoudre SQL et webapp
# vers les IP privées de leurs private endpoints.

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_sql" {
  provider              = azurerm.hub
  name                  = "spoke-vnet-link"
  resource_group_name   = var.hub_rg_dns_name
  private_dns_zone_name = data.azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = merge(var.tags, { resource_type = "private_dns_zone_vnet_link" })
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_webapp" {
  provider              = azurerm.hub
  name                  = "spoke-vnet-link"
  resource_group_name   = var.hub_rg_dns_name
  private_dns_zone_name = data.azurerm_private_dns_zone.webapp.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = merge(var.tags, { resource_type = "private_dns_zone_vnet_link" })
}

# ── PRIVATE ENDPOINTS ─────────────────────────────────────────────────────────

resource "azurerm_private_endpoint" "sql" {
  provider            = azurerm.spoke
  name                = module.naming.pe_sql
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  subnet_id           = azurerm_subnet.pe.id
  tags                = merge(var.tags, { resource_type = "private_endpoint" })

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnszg-sql"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.sql.id]
  }
}

resource "azurerm_private_endpoint" "webapp" {
  provider            = azurerm.spoke
  name                = module.naming.pe_webapp
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  subnet_id           = azurerm_subnet.pe.id
  tags                = merge(var.tags, { resource_type = "private_endpoint" })

  private_service_connection {
    name                           = "psc-webapp"
    private_connection_resource_id = azurerm_linux_web_app.webapp.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnszg-webapp"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.webapp.id]
  }
}
