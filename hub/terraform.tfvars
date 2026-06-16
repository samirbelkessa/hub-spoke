# =============================================================================
# terraform.tfvars — HUB
# Non-sensitive values only.
# Sensitive variables must be passed via environment variables:
#
#   export TF_VAR_hub_subscription_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#
# =============================================================================

# ── NAMING ───────────────────────────────────────────────────────────────────

environment    = "dev"           # dev | staging | prod
location       = "francecentral" # imposé par la policy CAF Governance (francecentral | westeurope)
location_short = "frc"           # frc = France Central
workload       = "myapp"         # lowercase alphanumeric, no hyphens
instance       = "001"
hub_subscription_id = "8d0e92f6-619b-497b-9957-9dfaf7111240" # Sensitive, must be passed via environment variable
# ── NETWORK ──────────────────────────────────────────────────────────────────

hub_vnet_address_space  = ["10.0.0.0/16"]
hub_subnet_appgw_prefix = "10.0.1.0/24"
pip_zones               = ["1", "2", "3"]
appgw_private_ip        = "10.0.1.10"

# ── APPLICATION GATEWAY ───────────────────────────────────────────────────────

capacity_min         = 1
capacity_max         = 10
waf_mode             = "Prevention"
waf_rule_set_version = "3.2"
cookie_affinity      = "Disabled"
request_timeout      = 30
require_sni          = false

# backend_fqdns and ssl_certificate_key_vault_id are left empty at initial hub deployment.
# Populate backend_fqdns after the spoke private endpoint is created.
backend_fqdns                = []
ssl_certificate_key_vault_id = ""
managed_identity_ids         = []

# ── TAGS ─────────────────────────────────────────────────────────────────────

tags = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "hub-spoke"
  NetworkType = "Hub" # requis par la policy CAF Network Baseline sur les resource groups
}
