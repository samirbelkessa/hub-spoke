# Module: naming

Shared naming module implementing the Azure Cloud Adoption Framework (CAF) naming convention for the Hub & Spoke architecture.

## Naming convention

```
<prefix>-<workload>-<environment>-<location_short>-<instance>[-<qualifier>]
```

All names are derived from a single `suffix` local:

```hcl
suffix = "${workload}-${environment}-${location_short}-${instance}"
```

> **Exception:** The Application Gateway subnet is always named `ApplicationGatewaySubnet` — this name is imposed by Azure and cannot follow the CAF pattern.

> **Key Vault:** Truncated to 24 characters maximum using `substr`.

## Generated name examples

For `workload=myapp`, `environment=dev`, `location_short=frc`, `instance=001`:

| Resource | Generated name |
|----------|---------------|
| Hub network RG | `rg-myapp-dev-frc-001-network` |
| Hub AppGW RG | `rg-myapp-dev-frc-001-appgw` |
| Hub PIP RG | `rg-myapp-dev-frc-001-pip` |
| Hub VNet | `vnet-myapp-dev-frc-001-hub` |
| AppGW subnet | `ApplicationGatewaySubnet` |
| Application Gateway | `agw-myapp-dev-frc-001` |
| Public IP | `pip-agw-myapp-dev-frc-001` |
| Spoke RG | `rg-myapp-dev-frc-001-spoke` |
| Spoke VNet | `vnet-myapp-dev-frc-001-spoke` |
| App subnet | `snet-myapp-dev-frc-001-app` |
| PE subnet | `snet-myapp-dev-frc-001-pe` |
| App Service Plan | `asp-myapp-dev-frc-001` |
| Web App | `app-myapp-dev-frc-001` |
| SQL Server | `sql-myapp-dev-frc-001` |
| SQL Database | `sqldb-myapp-dev-frc-001` |
| NSG app | `nsg-myapp-dev-frc-001-app` |
| NSG pe | `nsg-myapp-dev-frc-001-pe` |
| PE SQL | `pe-sql-myapp-dev-frc-001` |
| PE webapp | `pe-app-myapp-dev-frc-001` |
| Peering spoke→hub | `peer-spoke-to-hub-myapp-dev-frc-001` |
| Peering hub→spoke | `peer-hub-to-spoke-myapp-dev-frc-001` |
| Key Vault | `kv-myapp-dev-frc-001` |

## Inputs

| Name | Type | Required | Validation | Description |
|------|------|----------|------------|-------------|
| `environment` | `string` | yes | `dev`, `staging`, or `prod` | Deployment environment |
| `location_short` | `string` | yes | 2-6 lowercase letters | Short Azure region code |
| `workload` | `string` | yes | Lowercase alphanumeric | Short workload identifier |
| `instance` | `string` | yes | Exactly 3 digits | Instance number |

## Outputs

| Name | Description |
|------|-------------|
| `rg_network` | Hub network resource group name |
| `rg_appgw` | Application Gateway resource group name |
| `rg_pip` | Public IP resource group name |
| `vnet_hub` | Hub VNet name |
| `subnet_appgw` | AppGW subnet name (`ApplicationGatewaySubnet`) |
| `appgw` | Application Gateway name |
| `pip_appgw` | Application Gateway public IP name |
| `rg_spoke` | Spoke resource group name |
| `vnet_spoke` | Spoke VNet name |
| `subnet_app` | Application subnet name |
| `subnet_pe` | Private endpoint subnet name |
| `app_service_plan` | App Service Plan name |
| `webapp` | Linux Web App name |
| `sql_server` | SQL Server name |
| `sql_database` | SQL Database name |
| `nsg_app` | NSG for app subnet name |
| `nsg_pe` | NSG for PE subnet name |
| `pe_sql` | SQL private endpoint name |
| `pe_webapp` | Webapp private endpoint name |
| `peering_spoke_to_hub` | Spoke→hub peering name |
| `peering_hub_to_spoke` | Hub→spoke peering name |
| `key_vault` | Key Vault name (max 24 chars) |
