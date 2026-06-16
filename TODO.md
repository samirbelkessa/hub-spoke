# TODO — Déploiement Hub & Spoke Azure (Terraform)

Orchestration séquentielle des tâches par agent spécialisé.
Cocher chaque tâche au fur et à mesure. Ne pas passer à la phase suivante sans avoir validé la précédente.

---

## PHASE 0 — Initialisation du projet

- [ ] **[architecture]** Créer la structure de dossiers racine
  ```
  hub-spoke/
  ├── .claude/agents/
  ├── modules/naming/
  ├── hub/
  └── spoke/
  ```

---

## PHASE 1 — Module naming partagé

> Agent : **architecture**
> Périmètre : `modules/naming/`

- [ ] **[architecture]** Créer `modules/naming/variables.tf`
  - Variables : `environment`, `location_short`, `workload`, `instance`
  - Validation blocks sur chaque variable (environment ∈ dev/staging/prod, instance = 3 chiffres, workload alphanumérique minuscules)

- [ ] **[architecture]** Créer `modules/naming/locals.tf`
  - Local `suffix` = `${workload}-${environment}-${location_short}-${instance}`
  - Tous les noms HUB : `rg_network`, `rg_appgw`, `rg_pip`, `vnet_hub`, `subnet_appgw` (= "ApplicationGatewaySubnet"), `appgw`, `pip_appgw`
  - Tous les noms SPOKE : `rg_spoke`, `vnet_spoke`, `subnet_app`, `subnet_pe`, `app_service_plan`, `webapp`, `sql_server`, `sql_database`, `nsg_app`, `nsg_pe`, `pe_sql`, `pe_webapp`, `peering_spoke_to_hub`, `peering_hub_to_spoke`
  - `key_vault` avec `substr` pour rester ≤ 24 caractères

- [ ] **[architecture]** Créer `modules/naming/outputs.tf`
  - Exposer tous les locals avec une `description` par output

- [ ] **[documentation]** Créer `modules/naming/README.md`
  - Convention de nommage CAF
  - Tableau inputs / outputs
  - Exemples de noms générés pour `workload=myapp env=dev loc=frc`

---

## PHASE 2 — Architecture HUB

### 2.1 Squelette et providers

> Agent : **architecture**
> Périmètre : `hub/`

- [ ] **[architecture]** Créer `hub/providers.tf`
  - Provider `azurerm` unique (subscription hub)
  - `required_version >= 1.5.0`, `azurerm ~> 3.110`

- [ ] **[architecture]** Créer `hub/backend.tf`
  - Backend `azurerm` entièrement variabilisé
  - Key par défaut : `hub.tfstate`

- [ ] **[architecture]** Créer `hub/variables.tf`
  - Toutes les variables avec `type`, `description`, `sensitive` et `validation`
  - Groupes : subscription, naming, network, appgw, tags, backend

- [ ] **[architecture]** Créer `hub/terraform.tfvars`
  - Valeurs d'exemple non-sensibles commentées
  - En-tête commenté indiquant les variables à passer via TF_VAR_*

### 2.2 Ressources réseau hub

> Agent : **network**
> Périmètre : `hub/main.tf` (blocs network)

- [ ] **[network]** Ajouter dans `hub/main.tf` — instanciation du module naming
  ```hcl
  module "naming" {
    source         = "../modules/naming"
    environment    = var.environment
    location_short = var.location_short
    workload       = var.workload
    instance       = var.instance
  }
  ```

- [ ] **[network]** Ajouter dans `hub/main.tf` — Resource Group réseau
  - Nom : `module.naming.rg_network`
  - `lifecycle { prevent_destroy = true }`

- [ ] **[network]** Ajouter dans `hub/main.tf` — VNet hub
  - Nom : `module.naming.vnet_hub`
  - `address_space = var.hub_vnet_address_space`

- [ ] **[network]** Ajouter dans `hub/main.tf` — Subnet ApplicationGatewaySubnet
  - Nom : `module.naming.subnet_appgw` (= "ApplicationGatewaySubnet")
  - Pas de NSG (restriction Azure AppGW)
  - `address_prefixes = [var.hub_subnet_appgw_prefix]`

- [ ] **[network]** Ajouter dans `hub/main.tf` — Resource Group PIP
  - Nom : `module.naming.rg_pip`

- [ ] **[network]** Ajouter dans `hub/main.tf` — Public IP AppGW
  - Nom : `module.naming.pip_appgw`
  - SKU Standard, Static, zones variabilisées

- [ ] **[network]** Ajouter dans `hub/main.tf` — Resource Group AppGW
  - Nom : `module.naming.rg_appgw`

- [ ] **[network]** Ajouter dans `hub/main.tf` — Application Gateway WAF_v2
  - Nom : `module.naming.appgw`
  - SKU WAF_v2, autoscale min/max variabilisés
  - Deux frontend IP : publique (PIP) + privée (Static dans subnet)
  - Ports 80 et 443 variabilisés
  - Backend pool avec `fqdns = var.backend_fqdns`
  - Listeners HTTP et HTTPS
  - SSL certificate via Key Vault secret ID (variable)
  - Routing rules HTTP et HTTPS (Basic, priorités 100/110)
  - WAF configuration (mode Prevention, OWASP 3.2)
  - Identity UserAssigned (pour accès KV certificats)
  - `depends_on = [azurerm_resource_group.network, azurerm_public_ip.appgw]`

### 2.3 Outputs hub

> Agent : **architecture**

- [ ] **[architecture]** Créer `hub/outputs.tf`
  - Outputs obligatoires pour le spoke :
    - `hub_vnet_id`, `hub_vnet_name`
    - `hub_subnet_appgw_id`
    - `hub_rg_network_name`, `hub_rg_appgw_name`, `hub_rg_pip_name`
    - `appgw_id`, `appgw_name`
    - `appgw_backend_address_pool_id`
    - `appgw_private_ip`
    - `pip_appgw_address`

### 2.4 Documentation hub

> Agent : **documentation**

- [ ] **[documentation]** Créer `hub/README.md`
  - Description de l'architecture hub
  - Diagramme ASCII ou Mermaid
  - Tableaux inputs / outputs
  - Commandes de déploiement

### 2.5 Validation hub

- [ ] **[debug]** Vérifier `terraform init` dans `hub/` (module naming résolu)
- [ ] **[debug]** Vérifier `terraform validate`
- [ ] **[debug]** Vérifier `terraform plan` (aucune valeur null non intentionnelle)

---

## PHASE 3 — Architecture SPOKE

### 3.1 Squelette et providers

> Agent : **architecture**
> Périmètre : `spoke/`

- [ ] **[architecture]** Créer `spoke/providers.tf`
  - Provider `azurerm.spoke` (subscription spoke)
  - Provider `azurerm.hub` alias (subscription hub, pour peering cross-subscription)

- [ ] **[architecture]** Créer `spoke/backend.tf`
  - Backend `azurerm` entièrement variabilisé
  - Key par défaut : `spoke.tfstate`

- [ ] **[architecture]** Créer `spoke/variables.tf`
  - Variables spoke + références hub (hub_vnet_name, hub_rg_network_name, hub_appgw_name, hub_rg_appgw_name)
  - Variables réseau, SQL, AppService, KeyVault, Private DNS
  - Toutes avec `type`, `description`, `sensitive`, `validation`

- [ ] **[architecture]** Créer `spoke/terraform.tfvars`
  - Valeurs d'exemple non-sensibles commentées
  - Les valeurs `hub_vnet_name`, `hub_appgw_name`, etc. doivent correspondre aux outputs du hub

### 3.2 Data sources hub

> Agent : **architecture**

- [ ] **[architecture]** Créer `spoke/data.tf`
  - `data.azurerm_virtual_network.hub` (provider = azurerm.hub)
  - `data.azurerm_application_gateway.hub` (provider = azurerm.hub)
  - `data.azurerm_resource_group.hub_network` (provider = azurerm.hub)
  - **Jamais de `terraform_remote_state`**

### 3.3 Ressources réseau spoke

> Agent : **network**
> Périmètre : `spoke/main.tf` (blocs network)

- [ ] **[network]** Ajouter dans `spoke/main.tf` — module naming
  ```hcl
  module "naming" {
    source         = "../modules/naming"
    environment    = var.environment
    location_short = var.location_short
    workload       = var.workload
    instance       = var.instance
  }
  ```

- [ ] **[network]** Ajouter dans `spoke/main.tf` — Resource Group spoke
  - Nom : `module.naming.rg_spoke`
  - `lifecycle { prevent_destroy = true }`

- [ ] **[network]** Ajouter dans `spoke/main.tf` — VNet spoke
  - Nom : `module.naming.vnet_spoke`
  - `address_space = var.spoke_vnet_address_space`

- [ ] **[network]** Ajouter dans `spoke/main.tf` — Subnet app
  - Nom : `module.naming.subnet_app`
  - Delegation `Microsoft.Web/serverFarms`
  - Service endpoints : KeyVault, Sql, Web

- [ ] **[network]** Ajouter dans `spoke/main.tf` — Subnet pe
  - Nom : `module.naming.subnet_pe`
  - `private_endpoint_network_policies_enabled = false`

- [ ] **[network]** Ajouter dans `spoke/main.tf` — VNet Peering spoke→hub
  - Provider : `azurerm.spoke`
  - `remote_virtual_network_id = data.azurerm_virtual_network.hub.id`

- [ ] **[network]** Ajouter dans `spoke/main.tf` — VNet Peering hub→spoke
  - Provider : `azurerm.hub` (cross-subscription)
  - `remote_virtual_network_id = azurerm_virtual_network.spoke.id`

### 3.4 Sécurité spoke

> Agent : **security**
> Périmètre : `spoke/main.tf` (blocs security)

- [ ] **[security]** Ajouter dans `spoke/main.tf` — NSG subnet app
  - Nom : `module.naming.nsg_app`
  - Règles : Allow AppGW (80/443 depuis `hub_subnet_appgw_prefix`), Allow AzureLoadBalancer, Deny-All-Inbound, Allow-VNet-Out, Allow-Internet-Out

- [ ] **[security]** Ajouter dans `spoke/main.tf` — NSG subnet pe
  - Nom : `module.naming.nsg_pe`
  - Règles : Allow-App-SQL (1433 depuis subnet_app), Allow-App-HTTPS (443 depuis subnet_app), Deny-All-Inbound

- [ ] **[security]** Ajouter dans `spoke/main.tf` — Associations NSG
  - `azurerm_subnet_network_security_group_association` pour subnet_app et subnet_pe

- [ ] **[security]** Ajouter dans `spoke/main.tf` — Key Vault
  - Nom : `module.naming.key_vault`
  - `network_acls.default_action = "Deny"`, bypass AzureServices
  - `virtual_network_subnet_ids = [azurerm_subnet.app.id]`
  - `purge_protection_enabled = var.kv_purge_protection`
  - `lifecycle { prevent_destroy = true }`

- [ ] **[security]** Ajouter dans `spoke/main.tf` — Key Vault Access Policy webapp
  - `secret_permissions = ["Get", "List"]`
  - `object_id = azurerm_linux_web_app.webapp.identity[0].principal_id`

- [ ] **[security]** Ajouter dans `spoke/main.tf` — Secret SQL connection string
  - `value = var.sql_connection_string_secret` (sensitive)

### 3.5 Ressources applicatives spoke

> Agent : **architecture**
> Périmètre : `spoke/main.tf` (blocs compute et data)

- [ ] **[architecture]** Ajouter dans `spoke/main.tf` — SQL Server
  - Nom : `module.naming.sql_server`
  - `public_network_access_enabled = false`
  - `minimum_tls_version = "1.2"`
  - AAD administrator block
  - `lifecycle { prevent_destroy = true }`

- [ ] **[architecture]** Ajouter dans `spoke/main.tf` — SQL Database
  - Nom : `module.naming.sql_database`
  - SKU et size variabilisés

- [ ] **[architecture]** Ajouter dans `spoke/main.tf` — App Service Plan
  - Nom : `module.naming.app_service_plan`
  - `os_type = var.asp_os_type` (Linux)
  - `sku_name = var.asp_sku_name` (P1v3)

- [ ] **[architecture]** Ajouter dans `spoke/main.tf` — Linux Web App
  - Nom : `module.naming.webapp`
  - `https_only = true`
  - `public_network_access_enabled = false`
  - Identity SystemAssigned
  - VNet Integration : `virtual_network_subnet_id = azurerm_subnet.app.id`
  - App settings avec référence KV : `@Microsoft.KeyVault(SecretUri=...)`
  - `depends_on = [azurerm_key_vault_access_policy.webapp]`

### 3.6 Private Endpoints spoke

> Agent : **network**

- [ ] **[network]** Ajouter dans `spoke/main.tf` — Private Endpoint SQL
  - Nom : `module.naming.pe_sql`
  - Subnet : `azurerm_subnet.pe.id`
  - Subresource : `["sqlServer"]`
  - Private DNS Zone group : `var.private_dns_zone_sql_id`

- [ ] **[network]** Ajouter dans `spoke/main.tf` — Private Endpoint webapp
  - Nom : `module.naming.pe_webapp`
  - Subnet : `azurerm_subnet.pe.id`
  - Subresource : `["sites"]`
  - Private DNS Zone group : `var.private_dns_zone_webapp_id`

### 3.7 Outputs spoke

> Agent : **architecture**

- [ ] **[architecture]** Créer `spoke/outputs.tf`
  - `spoke_vnet_id`, `spoke_vnet_name`
  - `webapp_hostname`, `webapp_principal_id`
  - `sql_server_fqdn`
  - `key_vault_uri`
  - `pe_webapp_private_ip`, `pe_sql_private_ip`
  - `rg_spoke_name`

### 3.8 Documentation spoke

> Agent : **documentation**

- [ ] **[documentation]** Créer `spoke/README.md`
  - Description de l'architecture spoke
  - Flux de trafic
  - Tableaux inputs / outputs
  - Variables à récupérer depuis les outputs hub

### 3.9 Validation spoke

- [ ] **[debug]** Vérifier `terraform init` dans `spoke/` (providers hub et spoke, module naming)
- [ ] **[debug]** Vérifier `terraform validate`
- [ ] **[debug]** Vérifier `terraform plan`

---

## PHASE 4 — Documentation globale

> Agent : **documentation**

- [ ] **[documentation]** Créer `README.md` racine
  - Vue d'ensemble du projet
  - Diagramme Mermaid complet (hub + spoke + flux trafic)
  - Prérequis (Terraform, Azure CLI, droits, storage account state)
  - Ordre de déploiement avec commandes
  - Tableau des variables sensibles à exporter
  - Section troubleshooting (pointer vers l'agent debug)

---

## PHASE 5 — Validation end-to-end

- [ ] **[debug]** `terraform init` dans `hub/` → succès
- [ ] **[debug]** `terraform validate` dans `hub/` → "Success"
- [ ] **[debug]** `terraform plan` dans `hub/` → 0 erreur, ressources attendues présentes
- [ ] **[debug]** `terraform init` dans `spoke/` → succès
- [ ] **[debug]** `terraform validate` dans `spoke/` → "Success"
- [ ] **[debug]** `terraform plan` dans `spoke/` → 0 erreur, ressources attendues présentes
- [ ] **[architecture]** Vérifier que les outputs hub couvrent tous les inputs spoke
- [ ] **[security]** Vérifier la checklist sécurité complète
- [ ] **[network]** Vérifier le flux de trafic Internet → AppGW → PE webapp → WebApp → PE SQL → SQL

---

## Résumé des ressources attendues

### HUB (17 ressources)
| Ressource | Nom (exemple avec workload=myapp env=dev loc=frc) |
|-----------|--------------------------------------------------|
| `azurerm_resource_group` (network) | `rg-myapp-dev-frc-001-network` |
| `azurerm_resource_group` (appgw) | `rg-myapp-dev-frc-001-appgw` |
| `azurerm_resource_group` (pip) | `rg-myapp-dev-frc-001-pip` |
| `azurerm_virtual_network` | `vnet-myapp-dev-frc-001-hub` |
| `azurerm_subnet` | `ApplicationGatewaySubnet` |
| `azurerm_public_ip` | `pip-agw-myapp-dev-frc-001` |
| `azurerm_application_gateway` | `agw-myapp-dev-frc-001` |

### SPOKE (20 ressources)
| Ressource | Nom (exemple) |
|-----------|--------------|
| `azurerm_resource_group` | `rg-myapp-dev-frc-001-spoke` |
| `azurerm_virtual_network` | `vnet-myapp-dev-frc-001-spoke` |
| `azurerm_subnet` (app) | `snet-myapp-dev-frc-001-app` |
| `azurerm_subnet` (pe) | `snet-myapp-dev-frc-001-pe` |
| `azurerm_network_security_group` (app) | `nsg-myapp-dev-frc-001-app` |
| `azurerm_network_security_group` (pe) | `nsg-myapp-dev-frc-001-pe` |
| `azurerm_subnet_network_security_group_association` (×2) | — |
| `azurerm_virtual_network_peering` (spoke→hub) | `peer-spoke-to-hub-myapp-dev-frc-001` |
| `azurerm_virtual_network_peering` (hub→spoke) | `peer-hub-to-spoke-myapp-dev-frc-001` |
| `azurerm_key_vault` | `kv-myapp-dev-frc-001` |
| `azurerm_key_vault_access_policy` | — |
| `azurerm_key_vault_secret` | `sql-connection-string` |
| `azurerm_mssql_server` | `sql-myapp-dev-frc-001` |
| `azurerm_mssql_database` | `sqldb-myapp-dev-frc-001` |
| `azurerm_service_plan` | `asp-myapp-dev-frc-001` |
| `azurerm_linux_web_app` | `app-myapp-dev-frc-001` |
| `azurerm_private_endpoint` (sql) | `pe-sql-myapp-dev-frc-001` |
| `azurerm_private_endpoint` (webapp) | `pe-app-myapp-dev-frc-001` |
