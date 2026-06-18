# =============================================================================
# main.tf
# Architecture  : Hub & Spoke — HUB
# Description   : Hub network resources: VNet, AppGW WAF_v2, Public IP, Resource Groups
# Agent         : network
# Dernière MAJ  : 2026-06-16
# =============================================================================

module "naming" {
  source         = "git::https://github.com/samirbelkessa/hub-spoke.git//modules/naming?ref=master"
  environment    = var.environment
  location_short = var.location_short
  workload       = var.workload
  instance       = var.instance
}

# ── RESOURCE GROUPS ───────────────────────────────────────────────────────────

resource "azurerm_resource_group" "network" {
  name     = module.naming.rg_network
  location = var.location
  tags     = merge(var.tags, { resource_type = "resource_group" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "appgw" {
  name     = module.naming.rg_appgw
  location = var.location
  tags     = merge(var.tags, { resource_type = "resource_group" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "pip" {
  name     = module.naming.rg_pip
  location = var.location
  tags     = merge(var.tags, { resource_type = "resource_group" })

  lifecycle {
    prevent_destroy = true
  }
}

# ── HUB VNET ─────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "hub" {
  name                = module.naming.vnet_hub
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = var.hub_vnet_address_space
  tags                = merge(var.tags, { resource_type = "virtual_network" })
}

# No NSG on this subnet — Azure restriction for Application Gateway
resource "azurerm_subnet" "appgw" {
  name                 = module.naming.subnet_appgw
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnet_appgw_prefix]
}

# ── PRIVATE DNS (zones centralisées dans le hub) ──────────────────────────────

# RG dédié aux Private DNS Zones — centralisées dans le hub, consommées par le spoke
resource "azurerm_resource_group" "dns" {
  name     = module.naming.rg_dns
  location = var.location
  tags     = merge(var.tags, { resource_type = "resource_group" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_private_dns_zone" "sql" {
  name                = module.naming.pdns_sql
  resource_group_name = azurerm_resource_group.dns.name
  tags                = merge(var.tags, { resource_type = "private_dns_zone" })
}

resource "azurerm_private_dns_zone" "webapp" {
  name                = module.naming.pdns_webapp
  resource_group_name = azurerm_resource_group.dns.name
  tags                = merge(var.tags, { resource_type = "private_dns_zone" })
}

# Lien vers le VNet hub sur la zone App Service — permet à l'AppGW de résoudre
# le webapp vers l'IP privée de son private endpoint (backend en accès privé).
resource "azurerm_private_dns_zone_virtual_network_link" "hub_webapp" {
  name                  = "hub-vnet-link"
  resource_group_name   = azurerm_resource_group.dns.name
  private_dns_zone_name = azurerm_private_dns_zone.webapp.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = merge(var.tags, { resource_type = "private_dns_zone_vnet_link" })
}

# ── PUBLIC IP ─────────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "appgw" {
  name                = module.naming.pip_appgw
  location            = var.location
  resource_group_name = azurerm_resource_group.pip.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.pip_zones
  tags                = merge(var.tags, { resource_type = "public_ip" })
}

# ── WAF POLICY ────────────────────────────────────────────────────────────────
# La configuration WAF inline sur l'AppGW a été retirée par Azure.
# On attache une WAF policy dédiée via firewall_policy_id.

resource "azurerm_web_application_firewall_policy" "appgw" {
  name                = module.naming.waf_policy
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw.name
  tags                = merge(var.tags, { resource_type = "waf_policy" })

  policy_settings {
    enabled = true
    mode    = var.waf_mode
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = var.waf_rule_set_version
    }
  }
}

# ── APPLICATION GATEWAY WAF_v2 ────────────────────────────────────────────────

resource "azurerm_application_gateway" "appgw" {
  name                = module.naming.appgw
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw.name
  tags                = merge(var.tags, { resource_type = "application_gateway" })

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  # Politique TLS explicite — la valeur par défaut (AppGwSslPolicy20150501) est dépréciée par Azure
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  autoscale_configuration {
    min_capacity = var.capacity_min
    max_capacity = var.capacity_max
  }

  gateway_ip_configuration {
    name      = "gip-default"
    subnet_id = azurerm_subnet.appgw.id
  }

  # Public frontend
  frontend_ip_configuration {
    name                 = "fip-public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Private frontend (static IP within AppGW subnet)
  frontend_ip_configuration {
    name                          = "fip-private"
    subnet_id                     = azurerm_subnet.appgw.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.appgw_private_ip
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_port {
    name = "port-443"
    port = 443
  }

  backend_address_pool {
    name  = "bap-default"
    fqdns = var.backend_fqdns
  }

  backend_http_settings {
    name                                = "bhs-default"
    cookie_based_affinity               = var.cookie_affinity
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = var.request_timeout
    pick_host_name_from_backend_address = true
  }

  # HTTP listener (always created)
  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "fip-public"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  # HTTPS listener — only created when ssl_certificate_key_vault_id is provided
  dynamic "http_listener" {
    for_each = var.ssl_certificate_key_vault_id != "" ? [1] : []
    content {
      name                           = "listener-https"
      frontend_ip_configuration_name = "fip-public"
      frontend_port_name             = "port-443"
      protocol                       = "Https"
      ssl_certificate_name           = "ssl-cert-default"
      require_sni                    = var.require_sni
    }
  }

  # SSL certificate from Key Vault — requires User Assigned Managed Identity
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificate_key_vault_id != "" ? [1] : []
    content {
      name                = "ssl-cert-default"
      key_vault_secret_id = var.ssl_certificate_key_vault_id
    }
  }

  # HTTP routing rule (always created)
  request_routing_rule {
    name                       = "rrr-http"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "listener-http"
    backend_address_pool_name  = "bap-default"
    backend_http_settings_name = "bhs-default"
  }

  # HTTPS routing rule — only created with HTTPS listener
  dynamic "request_routing_rule" {
    for_each = var.ssl_certificate_key_vault_id != "" ? [1] : []
    content {
      name                       = "rrr-https"
      priority                   = 110
      rule_type                  = "Basic"
      http_listener_name         = "listener-https"
      backend_address_pool_name  = "bap-default"
      backend_http_settings_name = "bhs-default"
    }
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.appgw.id

  # User Assigned Identity for Key Vault certificate access
  dynamic "identity" {
    for_each = length(var.managed_identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.managed_identity_ids
    }
  }

  depends_on = [
    azurerm_resource_group.network,
    azurerm_public_ip.appgw,
  ]
}
