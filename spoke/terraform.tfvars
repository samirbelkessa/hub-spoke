# =============================================================================
# terraform.tfvars — SPOKE
# Non-sensitive values only.
# Sensitive variables must be passed via environment variables:
#
#   export TF_VAR_spoke_subscription_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#   export TF_VAR_hub_subscription_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#   export TF_VAR_tenant_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#   export TF_VAR_sql_admin_login="sqladmin"
#   export TF_VAR_sql_admin_password="P@ssw0rd!2024"
#   export TF_VAR_sql_connection_string_secret="Server=tcp:..."
#
# =============================================================================

# ── NAMING ───────────────────────────────────────────────────────────────────
# Must match hub values to ensure consistent resource naming
sql_admin_login = "sqladmin"
sql_admin_password = "P@ssw0rd!2024" # Sensitive, must be passed via environment variable
tenant_id = "01c40c02-a3ca-49b1-a844-dd9c825be5eb" # Sensitive, must be passed via environment variable
environment    = "dev"           # dev | staging | prod
location       = "francecentral" # imposé par la policy CAF Governance (francecentral | westeurope)
location_short = "frc"           # frc = France Central — doit matcher le hub
workload       = "myapp"         # must match hub value
instance       = "001"           # must match hub value
spoke_subscription_id = "b016bf4d-0eda-4613-b434-4d1fb841c3cb"
hub_subscription_id = "8d0e92f6-619b-497b-9957-9dfaf7111240" # Sensitive, must be passed via environment variable
# ── HUB REFERENCES ───────────────────────────────────────────────────────────
# Retrieve these values from hub outputs: terraform -chdir=../hub output

hub_vnet_name           = "vnet-myapp-dev-frc-001-hub"
hub_rg_network_name     = "rg-myapp-dev-frc-001-network"
hub_appgw_name          = "agw-myapp-dev-frc-001"
hub_rg_appgw_name       = "rg-myapp-dev-frc-001-appgw"
hub_subnet_appgw_prefix = "10.0.1.0/24"

# ── NETWORK ──────────────────────────────────────────────────────────────────

spoke_vnet_address_space = ["10.1.0.0/16"]
spoke_subnet_app_prefix  = "10.1.1.0/24"
spoke_subnet_pe_prefix   = "10.1.2.0/24"

# Set after creating Private DNS Zones (centralised in hub subscription)
private_dns_zone_sql_id    = ""
private_dns_zone_webapp_id = ""

# ── SECURITY / KEY VAULT ──────────────────────────────────────────────────────

key_vault_sku       = "standard"
kv_soft_delete_days = 90
kv_purge_protection = true
kv_allowed_ips      = ["88.186.124.220"] # IP du poste déployeur — requis pour écrire le secret via Terraform (réseau KV en Deny)

# ── SQL ───────────────────────────────────────────────────────────────────────

sql_aad_admin_login     = "samir.belkessa@gmail.com"
sql_aad_admin_object_id = "12d2a769-7745-4fca-8be9-795926ea8e7f"
sql_server_version      = "12.0"
sql_db_sku_name         = "GP_Gen5_2"
sql_max_size_gb         = 32

# ── APP SERVICE ───────────────────────────────────────────────────────────────

asp_os_type  = "Linux"
asp_sku_name = "P1v3"

# ── TAGS ─────────────────────────────────────────────────────────────────────

tags = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "hub-spoke"
  NetworkType = "Spoke" # requis par la policy CAF Network Baseline sur les resource groups
}
