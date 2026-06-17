# All variables as it would be defined in the .tfvars file.

appgw_private_ip        = "10.0.1.10"
backend_fqdns           = []
capacity_max            = 10
capacity_min            = 1
cookie_affinity         = "Disabled"
environment             = "dev"
hub_subnet_appgw_prefix = "10.0.1.0/24"
hub_subscription_id     = "8d0e92f6-619b-497b-9957-9dfaf7111240"
hub_vnet_address_space  = ["10.0.0.0/16"]
instance                = "001"
location                = "francecentral"
location_short          = "frc"
managed_identity_ids    = []
pip_zones               = ["1", "2", "3"]
request_timeout         = 30
require_sni             = false
tags = {
  archuuid = "631bbc84-5081-4fa9-bc62-55805c0e9d12"
  env      = "Development"
}
waf_mode             = "Prevention"
waf_rule_set_version = "3.2"
workload             = "myapp"
