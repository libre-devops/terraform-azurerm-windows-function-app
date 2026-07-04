<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Windows Function App

Terraform module for Azure Windows function apps on normal App Service plans (Consumption Y1,
Elastic Premium, dedicated B/S/P, and App Service Environments), in the Libre DevOps style:
fast to get going, secure by default, flexible when it matters.

[![CI](https://github.com/libre-devops/terraform-azurerm-windows-function-app/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-windows-function-app/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-windows-function-app?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-windows-function-app/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-windows-function-app)](./LICENSE)

---

## Overview

```hcl
module "windows_function_app" {
  source  = "libre-devops/windows-function-app/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-dev-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  function_apps = {
    "func-app-ldo-uks-dev-001" = {
      site_config = { application_stack = { powershell_core_version = "7.4" } }
    }
  }
}
```

That single entry gets a dedicated Y1 consumption plan, a keyless storage account (shared keys
disabled, TLS 1.2 floor, infrastructure encryption), a user-assigned identity granted the
documented role set BEFORE the app exists, identity-based host storage
(`storage_uses_managed_identity` plus the `AzureWebJobsStorage__clientId` hint), and secure
defaults the provider does not give you: `https_only`, FTP and WebDeploy basic auth OFF, and
the legacy builtin logging off. Every default has an explicit override.

- **Plans as a map.** Multiple apps share a plan via `service_plan_key`, `service_plan_id`
  brings your own, `app_service_environment_id` places a plan on an ASE, and an app that
  references no plan gets its own Y1 automatically.
- **Storage in three shapes.** Created (default), bring-your-own by id (grants intact, name
  parsed from the id), or `storage_key_vault_secret_id` where Key Vault holds the connection
  string and the caller owns everything. Keys-on is a first-class opt-out
  (`storage_shared_access_key_enabled = true`).
- **The content share trap, guarded.** Elastic Premium plans want an Azure Files content share
  and Files has no AAD data plane for it, so keyless apps on EP plans must set
  `content_share_force_disabled = true` (and deploy run-from-package) or flip keys on; a check
  enforces this for module-managed plans. Dedicated plans have no content share need.
- **Identity in every shape.** The default attaches both kinds with a module-created UAI
  (system-assigned plus deploy-during-create is a bootstrap deadlock); bring your own of any
  type; or none at all (keys-on apps).
- **A deploy story that works on every Windows plan.** Unlike Linux Consumption (which has no
  Kudu/SCM site and cannot be reached by config-zip), Windows apps on ALL plans, Consumption
  included, have a Kudu/SCM site, so `az functionapp deployment source config-zip` and the
  Terraform-native `zip_deploy_file` both work everywhere. The honest default is the AAD push
  after apply (config-zip), which this repo's staged CI proves end to end on the complete
  example's B1 PowerShell app: apply, push the package with a fresh login, curl the endpoint as
  the real gate, destroy. `zip_deploy_file` also works (verified on the linux sibling; the same
  Kudu path), but it relies on the basic-auth publishing profile this module disables by default,
  so opting in also requires `webdeploy_publish_basic_authentication_enabled = true` plus
  `WEBSITE_RUN_FROM_PACKAGE` or `SCM_DO_BUILD_DURING_DEPLOYMENT` (a validation enforces the
  pairing). The minimal (Y1) example is left as apply-and-destroy in CI for parity with the
  linux repo, but it is config-zip-deployable too.
- **Application Insights, AAD-ingestion ready.** Pass the connection string and the AI id and
  the module wires the app setting, the AAD ingestion auth string, and the Monitoring Metrics
  Publisher grant (gated on a plan-known flag).
- **The full provider surface.** site_config including application_stack (dotnet, node, java,
  and PowerShell, plus custom and dotnet-isolated; Windows function apps have no container
  runtime), auth_settings and auth_settings_v2 in full, backup, connection strings, sticky
  settings, storage mounts, IP restrictions with headers, and VNet integration
  (`virtual_network_subnet_id`, `vnet_route_all_enabled`, storage network rules).

## Examples

- [`examples/minimal`](./examples/minimal) - the one-entry PowerShell call above, applied and
  verified in CI.
- [`examples/complete`](./examples/complete) - a shared B1 plan hosting a keyless PowerShell API
  (App Insights with AAD ingestion, always_on, health checks, CORS, TLS 1.3) next to a keys-on
  node worker with a system-assigned identity.

Slots are a deliberate non-goal for now (`azurerm_windows_function_app_slot` is its own resource
and can compose with this module's outputs).
