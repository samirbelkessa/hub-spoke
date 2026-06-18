# Fil conducteur — Formation « Prendre en main Brainboard »

> **Sujet de la formation : Brainboard** (la plateforme visuelle d'Infrastructure as Code).
> Les deux architectures **Hub & Spoke Azure** servent de **support pratique** : on apprend Brainboard
> *en construisant* le hub (atelier 1) puis le spoke (atelier 2).
>
> Deux ateliers de **2 heures**. À la fin, le participant sait concevoir une infra dans le canvas
> Brainboard, la générer en Terraform/OpenTofu, gérer variables/secrets/modules, et la déployer
> via le **CI/CD embarqué** (init / plan / apply) — y compris en cross-subscription.

---

## 1. Cadre pédagogique

### Public cible
Cloud / DevOps engineers, architectes Azure, qui veulent **industrialiser leur IaC visuellement**.
Bases Azure requises (VNet, RBAC, abonnement/tenant) ; **aucune expérience Brainboard préalable**.

### Pré-requis participants
- Un compte **Brainboard** + accès à l'**organisation / workspace** de la formation.
- Deux souscriptions Azure (hub + spoke) ou deux RG, avec un **service principal** par souscription
  (Contributor ; + Network Contributor cross-sub côté hub).
- Bases : VNet/subnet/NSG, WAF, Key Vault, notion de provider Terraform.

### Ce que le participant saura faire avec Brainboard (objectifs)
1. Naviguer la hiérarchie **Organisation → Projet → Architecture** et le **Smart Cloud Designer**.
2. **Designer sur le canvas** : resource library (Azure), drag-and-drop, connexions, dépendances.
3. Exploiter la **génération de code Terraform/OpenTofu** et la **synchronisation bidirectionnelle**
   diagramme ↔ code (**Code Edition**, éditeur Monaco : `main.tf`, `variables.tf`, `locals.tf`,
   `outputs.tf`, `terraform.tfvars`).
4. Gérer les **variables & secrets** (flag `sensitive`, séparation `terraform.tfvars`).
5. Réutiliser un **module** (le module `naming`) comme source de vérité, versionné via Git.
6. Configurer le **multi-provider / cross-subscription** et le **backend** (par le code / Git).
7. Lancer et lire un **job CI/CD** (init / plan / apply) sur un **runner** Brainboard, et **diagnostiquer**.
8. Brancher le **scanning sécurité & coût** (Checkov / tfsec, Infracost) avant déploiement.
9. Connecter **Git** et pousser le code généré.

### Architecture support (le fil rouge des 2 ateliers)
```
Internet → PIP Standard (HUB)
  → AppGW WAF_v2 (HUB, subnet ApplicationGatewaySubnet)
    → [Peering VNet  HUB ↔ SPOKE]
      → Private Endpoint webapp (SPOKE / subnet_pe)
        → Linux Web App (SPOKE / subnet_app, VNet Integration)
          ├→ Key Vault (service endpoint sur subnet_app)
          └→ Private Endpoint SQL (SPOKE / subnet_pe) → Azure SQL Server
```
> **Atelier 1 = découverte de Brainboard en construisant le HUB.**
> **Atelier 2 = Brainboard avancé (multi-sub, secrets, CI complet) en construisant le SPOKE.**

### Table de correspondance « étape ↔ fonctionnalité Brainboard »
| Brique construite | Fonctionnalité Brainboard travaillée |
|---|---|
| RG / VNet / subnet hub | Canvas, resource library, connexions & dépendances |
| AppGW WAF_v2 + PIP | Resource Configuration panel, properties, génération de code |
| Module `naming` | Réutilisation de **modules** + source Git versionnée |
| Subscription IDs, SQL creds | **Variables & secrets** (`sensitive`, `terraform.tfvars`) |
| `providers.tf` 2 alias, `backend.tf` | **Code Edition** / Git (non éditables au canvas — voir §3) |
| Data sources hub (spoke) | Référencer une archi existante en cross-subscription |
| init / plan / apply | **CI/CD engine** + **runner** + lecture des jobs |
| Validation pré-déploiement | **Checkov / tfsec / Infracost** |

---

## 2. ATELIER 1 — Découvrir Brainboard en construisant le HUB (2h)

**Objectif Brainboard :** maîtriser le cycle de base **Designer → Générer le code → Déployer (CI/CD)**.
**Support :** le hub (VNet + ApplicationGatewaySubnet, AppGW WAF_v2, Public IP).
**Livrable :** un **job `apply` hub réussi** dans Brainboard + les **outputs** lus dans l'UI.

| Temps | Durée | Séquence Brainboard | Contenu & gestes outil |
|-------|-------|---------------------|------------------------|
| 0:00 | 15' | **Tour de la plateforme** | Organisation / Projet / Architecture. Vue d'ensemble : canvas, panneau de code, jobs CI. Démo de l'archi finale pour donner le cap. |
| 0:15 | 15' | **Le Smart Cloud Designer** | Resource library Azure, drag-and-drop sur le canvas, créer des **connexions** (le canvas comprend les dépendances). Notion de génération **Terraform/OpenTofu** en temps réel. |
| 0:30 | 20' | **Hands-on : réseau hub au canvas** | Poser 3 RG (`-network`, `-appgw`, `-pip`), un VNet, le subnet `ApplicationGatewaySubnet`. Ouvrir le **Resource Configuration panel** : renommer, régler les propriétés. Observer le **code généré** se mettre à jour. |
| 0:50 | 15' | **Code Edition & sync bidirectionnel** | Ouvrir l'éditeur (Monaco) : `main.tf`, `variables.tf`, `outputs.tf`. Modifier une propriété **dans le code** → voir le **canvas se synchroniser** (et inversement). |
| 1:05 | 10' | ☕ **Pause** | — |
| 1:15 | 20' | **Hands-on : exposition + variables** | Public IP Standard, **WAF policy** OWASP 3.2, **AppGW WAF_v2** (listeners HTTP/HTTPS, frontend public+privé). Déclarer des **variables** (`environment`, `location`, `waf_mode`…) et les valoriser dans `terraform.tfvars`. Introduire le **module `naming`** pour les noms. |
| 1:35 | 20' | **CI/CD : premier déploiement** | Lancer un **job** : `init → plan → apply` sur le **runner** Brainboard. Lire les logs du job, comprendre le **plan** (`+ create`), le **backend** (state distant). |
| 1:55 | 5' | **Outputs & débrief** | Lire les **outputs** du hub dans l'UI (`hub_vnet_name`, `hub_rg_network_name`, `hub_appgw_name`…). Teaser : *« le spoke viendra référencer ces valeurs. »* |

**Notes formateur (Atelier 1)**
- Insister sur la **boucle** Brainboard : *je dessine → le code se génère → je déploie*, et la **réversibilité** (code ↔ canvas).
- Montrer que les **noms** passent par le **module** `naming`, jamais en dur.
- Si une **policy Azure** bloque le job (région, tag `NetworkType`), c'est l'occasion d'introduire le
  **scanning / les guardrails** (Checkov/tfsec) — cf. mémoire `azure-env-constraints`.

---

## 3. ATELIER 2 — Brainboard avancé en construisant le SPOKE (2h)

**Objectif Brainboard :** gérer le **réel** : multi-provider (cross-subscription), **secrets**,
**modules versionnés**, référence à une archi existante, **pipeline complet** et **diagnostic des jobs**.
**Support :** le spoke (réseau, Key Vault, SQL, Web App, Private Endpoints, peering).
**Livrable :** flux `Internet → AppGW → webapp → SQL/KV` validé, déployé depuis Brainboard.

| Temps | Durée | Séquence Brainboard | Contenu & gestes outil |
|-------|-------|---------------------|------------------------|
| 0:00 | 10' | **Rappel & nouvelle archi** | Créer l'architecture **Spoke** dans le même projet. Rappel de l'**ordre** (hub d'abord). |
| 0:10 | 20' | **Multi-provider & backend par le code** | Point clé Brainboard : `providers.tf` et `backend.tf` se configurent **par Code Edition / Git** (non éditables au canvas en alpha). Déclarer **2 providers aliasés** (`azurerm.spoke` + `azurerm.hub`). **Pas de `remote_state`** : référencer le hub via **`data` sources** (`provider = azurerm.hub`). |
| 0:30 | 15' | **Hands-on : réseau spoke au canvas** | VNet spoke, `subnet_app` (delegation Web/serverFarms, service endpoints), `subnet_pe`, NSG app & pe (**Deny-All-Inbound**), **peering** bidirectionnel (le hub→spoke porte `provider = azurerm.hub`). |
| 0:45 | 10' | ☕ **Pause** | — |
| 0:55 | 20' | **Hands-on : workload + secrets** | Key Vault, SQL Server + DB, Linux Web App (MSI, VNet Integration), Private Endpoints, RBAC. **Gestion des secrets** Brainboard : `sql_admin_password`, connection string → variables **`sensitive`**, **jamais** en clair dans `terraform.tfvars` (passées en `TF_VAR_*` / secrets). |
| 1:15 | 10' | **Modules versionnés via Git** | Pointer le module `naming` sur sa **source Git** (`?ref=v1.0.0`) plutôt qu'un chemin local : montrer la **réutilisation de module** entre architectures et l'intérêt du **tag de version**. |
| 1:25 | 20' | **Pipeline complet + troubleshooting** | Lancer le job spoke : `init → plan → apply`. **C'est ici qu'on rencontre les vraies erreurs des jobs CI** (cf. §4) : tenant 401, 403 cross-sub, « hub absent ». Lire les logs, diagnostiquer, corriger. |
| 1:45 | 10' | **Bouclage du flux** | Récupérer `pe_webapp_private_ip`, le mettre dans `backend_fqdns` du hub, **relancer le job hub**. Tester `Internet → AppGW → webapp`. |
| 1:55 | 5' | **Débrief & Git** | Connecter / **pousser** le code vers Git, parler collaboration, scanning (Checkov/tfsec) & coût (Infracost), pistes multi-env. |

**Notes formateur (Atelier 2)**
- Le **cross-subscription** est le morceau de bravoure : faire vivre la dépendance — le job spoke
  **échoue** tant que le hub n'existe pas (les `data` sources ne trouvent rien).
- Bien distinguer **ce qui se fait au canvas** (ressources, connexions) de **ce qui se fait par le code/Git**
  (providers multi-alias, backend) — limite actuelle (alpha) à expliquer clairement.
- Secrets : montrer le flag `sensitive` côté Brainboard et le passage par variables d'environnement.

---

## 4. Annexe — Troubleshooting des jobs CI Brainboard (cas réels)

> Erreurs réellement rencontrées sur les **runs Brainboard** du projet. À utiliser comme **exercices de diagnostic**.

### A. `401 InvalidAuthenticationTokenTenant` — mauvais tenant
**Symptôme :** `The access token is from the wrong issuer 'sts.windows.net/<A>'. It must match the
tenant '<B>' associated with this subscription.`
**Cause :** les credentials configurés dans Brainboard s'authentifient sur le **tenant A**, mais la
souscription vit dans le **tenant B** (typiquement après transfert de souscription).
**Fix :** dans Brainboard, `ARM_TENANT_ID = <B>` **et** un **service principal enregistré dans le tenant B**
(un secret s'authentifie toujours dans le tenant d'origine de l'app).

### B. `403 AuthorizationFailed` sur les data sources hub — hub absent / droits manquants
**Symptôme :** `does not have authorization to perform action 'Microsoft.Network/applicationGateways/read'`
(idem RG network, private DNS zones) pendant le **job plan du spoke**.
**Cause :** (1) le **hub n'est pas déployé** (les ressources n'existent pas → Azure renvoie 403, pas 404) ;
et/ou (2) le SP spoke n'a **aucun rôle** sur la souscription hub.
**Fix :** déployer le **hub d'abord**, puis donner au SP spoke **Reader + Network Contributor** sur la sub hub :
```bash
az role assignment create \
  --assignee <object-id-SP-spoke> \
  --role "Network Contributor" \
  --scope /subscriptions/<hub-subscription-id>
```

### C. Conflit soft-delete Key Vault (re-déploiement)
**Fix :** `az keyvault purge --name <kv-name> --location francecentral`.

### D. Rappels qui évitent 80 % des incidents de job
- **Ordre** : job hub → outputs → job spoke → re-job hub (backend pool).
- **Cohérence** des variables `workload` / `environment` / `location_short` / `instance` entre les 2 archis.
- **Module naming** : source Git **taggée** (`?ref=v1.0.0`) pour figer le comportement pendant la formation.
- **Secrets** : jamais en clair dans `terraform.tfvars` → variables `sensitive` / `TF_VAR_*`.

---

## 5. Check-list formateur (avant J-1)

- [ ] Organisation / workspace Brainboard prêt, participants invités, **runner** opérationnel.
- [ ] Credentials Azure configurés dans Brainboard, **bon tenant** vérifié (éviter l'erreur A).
- [ ] SP spoke avec droits **cross-sub** sur le hub (éviter l'erreur B).
- [ ] Backends distants (storage tfstate) hub & spoke créés.
- [ ] Module `naming` **taggé** (version figée) et accessible via Git.
- [ ] Variables sensibles préparées (subscription IDs, tenant, SQL creds) en secrets / `TF_VAR_*`.
- [ ] Un run hub **testé de bout en bout** par le formateur la veille.
- [ ] (Option) Scanning Checkov/tfsec et Infracost activés pour la démo des guardrails.

---

## 6. Synthèse en une phrase

> **Atelier 1**, on apprend la boucle Brainboard — *dessiner → générer le code → déployer en CI/CD* — en
> construisant le **hub** ; **Atelier 2**, on pousse Brainboard en conditions réelles — *multi-souscription,
> secrets, modules versionnés, pipeline et diagnostic* — en construisant le **spoke**, jusqu'à voir un paquet
> aller d'**Internet jusqu'à SQL**.

---

### Sources (fonctionnalités Brainboard)
- [Brainboard — plateforme](https://www.brainboard.co/)
- [Smart Cloud Designer](https://www.brainboard.co/features/smart-cloud-designer)
- [Code Edition (docs)](https://docs.brainboard.co/cloud-design/code-edition)
- [Modules OpenTofu & Terraform](https://www.brainboard.co/features/terraform-opentofu-modules)
- [Self-Hosted Runner (docs)](https://docs.brainboard.co/deployment-and-settings/ci-cd-engine/self-hosted-runner)
- [Gestion des secrets Terraform](https://www.brainboard.co/blog/terraform-secrets-best-practices-for-storing-and-managing-values)
