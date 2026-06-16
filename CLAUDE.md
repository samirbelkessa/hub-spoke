# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Présentation du projet

Architecture Terraform Hub & Spoke sur Azure (Cloud Adoption Framework). Deux root modules indépendants (`hub/` et `spoke/`) partagent un module de nommage et communiquent via VNet peering cross-subscription.

## Commandes Terraform

```bash
# Hub (déployer en premier)
cd hub/
terraform init
terraform validate
terraform plan
terraform apply
terraform output   # récupérer les valeurs à passer au spoke

# Spoke
cd spoke/
terraform init
terraform validate
terraform plan
terraform apply

# Debug : logs détaillés
export TF_LOG=DEBUG
terraform plan 2>&1 | tee terraform-debug.log

# Cibler une ressource spécifique
terraform plan  -target=azurerm_virtual_network_peering.spoke_to_hub
terraform apply -target=azurerm_key_vault.spoke

# Importer une ressource existante dans le state
terraform import azurerm_resource_group.spoke /subscriptions/<sub>/resourceGroups/<rg_name>

# Résoudre un conflit soft-delete Key Vault
az keyvault purge --name <kv-name> --location francecentral
```

## Structure de dossiers (état cible)

```
hub-spoke/
├── modules/naming/          # Source de vérité unique pour tous les noms de ressources
│   ├── variables.tf
│   ├── locals.tf
│   └── outputs.tf
├── hub/                     # Root module hub (AppGW WAF_v2, VNet, Public IP)
│   ├── providers.tf         # Provider azurerm unique (subscription hub)
│   ├── backend.tf           # Remote state — key: hub.tfstate
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── spoke/                   # Root module spoke (WebApp, SQL, Key Vault, Private Endpoints)
    ├── providers.tf         # Deux providers : azurerm.spoke + azurerm.hub alias (cross-subscription)
    ├── backend.tf           # Remote state — key: spoke.tfstate
    ├── main.tf
    ├── data.tf              # Data sources hub — jamais terraform_remote_state
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars
```

## Agents spécialisés

Les instructions par domaine sont dans `.claude/agents/`. Utiliser le bon agent selon le périmètre :

| Agent | Périmètre |
|-------|-----------|
| `architecture` | Structure des dossiers, providers, backends, root modules, variables, outputs, `modules/naming/` |
| `network` | VNet, subnets, peering, AppGW, Private Endpoints, DNS zone groups |
| `security` | Règles NSG, Key Vault ACL, access policies, durcissement SQL/WebApp |
| `debug` | Erreurs `init`/`validate`/`plan`/`apply`, state, auth provider |
| `documentation` | Tous les `README.md`, commentaires de tête dans les `.tf`, `terraform.tfvars` annoté |

## Convention de nommage CAF

Le module `modules/naming/` est l'unique source de vérité. Pattern :

```
suffix = "${workload}-${environment}-${location_short}-${instance}"
```

Exemples pour `workload=myapp env=dev loc=frc instance=001` :
- `rg-myapp-dev-frc-001-network` / `-appgw` / `-pip` / `-spoke`
- `vnet-myapp-dev-frc-001-hub` / `-spoke`
- `agw-myapp-dev-frc-001`, `pip-agw-myapp-dev-frc-001`
- `kv-myapp-dev-frc-001` — tronqué à 24 caractères via `substr`
- Le subnet AppGW s'appelle toujours `ApplicationGatewaySubnet` (nom imposé par Azure)

## Contraintes architecturales clés

**Peering cross-subscription :** Le `spoke/providers.tf` déclare deux providers aliasés (`azurerm.spoke` et `azurerm.hub`). La ressource peering hub→spoke doit explicitement porter `provider = azurerm.hub`.

**Pas de `terraform_remote_state` :** Le spoke lit les ressources hub via des `data` sources dans `data.tf`. Les noms hub sont passés en variables d'entrée du spoke.

**Variables sensibles :** Les subscription IDs, tenant ID, credentials SQL et la connection string SQL sont tous `sensitive = true`. Ils ne doivent jamais figurer dans `terraform.tfvars` — les passer via `TF_VAR_*`.

**Protection des ressources critiques :** `lifecycle { prevent_destroy = true }` obligatoire sur tous les Resource Groups, le Key Vault et le SQL Server.

**Tags :** Toutes les ressources utilisent `merge(var.tags, { resource_type = "..." })`.

**En-tête de chaque fichier `.tf` :**
```hcl
# =============================================================================
# <NOM DU FICHIER>
# Architecture  : Hub & Spoke — <HUB|SPOKE|MODULE>
# Description   : <description courte>
# Agent         : <architecture|network|security>
# Dernière MAJ  : <date>
# =============================================================================
```

## Flux de trafic

```
Internet → PIP Standard (hub)
  → AppGW WAF_v2 (hub, subnet ApplicationGatewaySubnet)
    → [Peering VNet hub ↔ spoke]
      → Private Endpoint webapp (spoke / subnet_pe)
        → Linux Web App (spoke / subnet_app, VNet Integration)
          ├→ Key Vault (via service endpoint sur subnet_app)
          └→ Private Endpoint SQL (spoke / subnet_pe)
               → Azure SQL Server
```

## Ordre de déploiement

1. Déployer `hub/` en premier
2. Récupérer les outputs : `terraform -chdir=hub output`
3. Renseigner les valeurs non-sensibles dans `spoke/terraform.tfvars`, les sensibles via `TF_VAR_*`
4. Déployer `spoke/`

## Versions

- Terraform : `>= 1.5.0`
- Provider azurerm : `~> 3.110`
