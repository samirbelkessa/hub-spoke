resource "azurerm_resource_group" "network" {
  tags     = merge(var.tags, { resource_type = "resource_group" })
  name     = module.naming.rg_network
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "appgw" {
  tags     = merge(var.tags, { resource_type = "resource_group" })
  name     = module.naming.rg_appgw
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "pip" {
  tags     = merge(var.tags, { resource_type = "resource_group" })
  name     = module.naming.rg_pip
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network" "hub" {
  tags                = merge(var.tags, { resource_type = "virtual_network" })
  resource_group_name = azurerm_resource_group.network.name
  name                = module.naming.vnet_hub
  location            = var.location
  address_space       = var.hub_vnet_address_space
}

resource "azurerm_subnet" "appgw" {
  virtual_network_name = azurerm_virtual_network.hub.name
  resource_group_name  = azurerm_resource_group.network.name
  name                 = module.naming.subnet_appgw

  address_prefixes = [
    var.hub_subnet_appgw_prefix,
  ]
}

resource "azurerm_resource_group" "dns" {
  tags     = merge(var.tags, { resource_type = "resource_group" })
  name     = module.naming.rg_dns
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_private_dns_zone" "sql" {
  tags                = merge(var.tags, { resource_type = "private_dns_zone" })
  resource_group_name = azurerm_resource_group.dns.name
  name                = module.naming.pdns_sql
}

resource "azurerm_private_dns_zone" "webapp" {
  tags                = merge(var.tags, { resource_type = "private_dns_zone" })
  resource_group_name = azurerm_resource_group.dns.name
  name                = module.naming.pdns_webapp
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_webapp" {
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = merge(var.tags, { resource_type = "private_dns_zone_vnet_link" })
  resource_group_name   = azurerm_resource_group.dns.name
  registration_enabled  = false
  private_dns_zone_name = azurerm_private_dns_zone.webapp.name
  name                  = "hub-vnet-link"
}

resource "azurerm_public_ip" "appgw" {
  zones               = var.pip_zones
  tags                = merge(var.tags, { resource_type = "public_ip" })
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.pip.name
  name                = module.naming.pip_appgw
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_web_application_firewall_policy" "appgw" {
  tags                = merge(var.tags, { resource_type = "waf_policy" })
  resource_group_name = azurerm_resource_group.appgw.name
  name                = module.naming.waf_policy
  location            = var.location

  managed_rules {
    managed_rule_set {
      version = var.waf_rule_set_version
      type    = "OWASP"
    }
  }

  policy_settings {
    mode    = var.waf_mode
    enabled = true
  }
}

module "naming" {
  source = "../modules/naming"


  environment    = var.environment
  location_short = var.location_short
  workload       = var.workload
  instance       = var.instance

}

resource "azurerm_application_gateway" "appgw" {
  tags                = merge(var.tags, { resource_type = "application_gateway" })
  resource_group_name = azurerm_resource_group.appgw.name
  name                = module.naming.appgw
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.appgw.id

  depends_on = [
    azurerm_resource_group.network,
    azurerm_public_ip.appgw,
  ]

  autoscale_configuration {
    min_capacity = var.capacity_min
    max_capacity = var.capacity_max
  }

  backend_address_pool {
    name  = "bap-default"
    fqdns = var.backend_fqdns
  }

  backend_http_settings {
    request_timeout                     = var.request_timeout
    protocol                            = "Https"
    port                                = 443
    pick_host_name_from_backend_address = true
    name                                = "bhs-default"
    cookie_based_affinity               = var.cookie_affinity
  }

  frontend_ip_configuration {
    public_ip_address_id = azurerm_public_ip.appgw.id
    name                 = "fip-public"
  }

  frontend_ip_configuration {
    subnet_id                     = azurerm_subnet.appgw.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.appgw_private_ip
    name                          = "fip-private"
  }

  frontend_port {
    port = 80
    name = "port-80"
  }

  frontend_port {
    port = 443
    name = "port-443"
  }

  gateway_ip_configuration {
    subnet_id = azurerm_subnet.appgw.id
    name      = "gip-default"
  }

  http_listener {
    protocol                       = "Http"
    name                           = "listener-http"
    frontend_port_name             = "port-80"
    frontend_ip_configuration_name = "fip-public"
  }

  request_routing_rule {
    rule_type                  = "Basic"
    priority                   = 100
    name                       = "rrr-http"
    http_listener_name         = "listener-http"
    backend_http_settings_name = "bhs-default"
    backend_address_pool_name  = "bap-default"
  }

  sku {
    tier = "WAF_v2"
    name = "WAF_v2"
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificate_key_vault_id != "" ? [1] : []
    content {
      name                = "ssl-cert-default"
      key_vault_secret_id = var.ssl_certificate_key_vault_id
    }
  }

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

  dynamic "identity" {
    for_each = length(var.managed_identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.managed_identity_ids
    }
  }
}

