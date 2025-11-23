# Azure Naming

> Consistent, location‑aware, environment‑aware Azure resource naming built on top of the official Microsoft [Azure/naming/azurerm](https://github.com/Azure/terraform-azurerm-naming) module.

[![Unit Tests](https://github.com/Build5Nines/terraform-azurerm-region-naming/actions/workflows/unit-tests.yaml/badge.svg)](https://github.com/Build5Nines/terraform-azurerm-region-naming/actions/workflows/unit-tests.yaml)

This Terraform module standardizes Azure resource names by composing an opinionated suffix that includes:

* Organization
* Region abbreviation (canonical + overridable)
* Environment

It then passes that suffix to the upstream Azure naming module so you can access every supported Azure resource name through a single exported `prefix` object.

---
## Highlights
* Accepts either display region names (e.g. `East US`) or programmatic names (`eastus`).
* Validates regions against an explicit allow list.
* Data‑driven abbreviations via `data/region_abbr.json` (overrideable per region).
* Region pairing / canonicalization via `data/region_pair.json` (exposed as `location_secondary`).
* Flexible suffix pattern using placeholder tokens: `{org}`, `{loc}`, `{env}`.
* Full access to all Azure resource naming outputs provided by `Azure/naming/azurerm`.

---
## Quick Start

```hcl
module "naming_primary" {
    source        = "Build5Nines/naming/azurerm"
    organization  = "b59"
    environment   = "prod"
    location      = "East US"   # or "eastus"
}

resource "azurerm_resource_group" "main" {
    name     = module.naming_primary.prefix.resource_group.name
    location = module.naming_primary.location
}
```

Resulting resource group name pattern (example):
```
rg-b59-eus-prod
```
(`rg` is applied internally by the upstream module as the slug for a resource group.)

---
## Accessing Resource Names

The `prefix` output is an entire instantiated module object from `Azure/naming/azurerm`, not just a string. This means that the `prefix` output has properties for each [Azure Resource type](https://github.com/Azure/terraform-azurerm-naming/blob/master/README.md#outputs). Each resource (e.g. `.prefix.app_service`) is an object with additional properties for that Azure Resource type:

| Property       | Description |
|----------------|-------------|
| `name`         | Generated name with your suffix applied. |
| `name_unique`  | Same as `name` but with additional random characters for uniqueness (when supported). |
| `slug`         | Short identifier segment for the resource type (e.g. `rg`, `sa`, `kv`). |
| `min_length`   | Minimum allowed length. |
| `max_length`   | Maximum allowed length. |
| `scope`        | Uniqueness scope (`resourcegroup`, `global`, etc.). |
| `dashes`       | Whether dashes are allowed. |
| `regex`        | Validation regex (Terraform compatible). |

Example usages:

```hcl
# Storage Account
resource "azurerm_storage_account" "sa" {
    name                     = module.naming_primary.prefix.storage_account.name
    resource_group_name      = azurerm_resource_group.main.name
    location                 = module.naming_primary.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
}

# Unique variation (if collision risk)
resource "azurerm_key_vault" "kv" {
    name                = module.naming_primary.prefix.key_vault.name_unique
    resource_group_name = azurerm_resource_group.main.name
    location            = module.naming_primary.location
    tenant_id           = data.azurerm_client_config.current.tenant_id
    sku_name            = "standard"
}
```

---
## Secondary / Paired Region

`location_secondary` exposes the paired (or canonicalized) region derived from `data/region_pair.json`. Use it to instantiate a second module instance for DR / HA scenarios:

```hcl
module "naming_secondary" {
    source       = "Build5Nines/naming/azurerm"
    organization = module.naming_primary.organization
    environment  = module.naming_primary.environment
    location     = module.naming_primary.location_secondary
}

---
## Customizing the Suffix Pattern

The default suffix is equivalent to the pattern array:
```hcl
name_suffix = ["{org}", "{loc}", "{env}"]
```

You can rearrange or add static parts:

```hcl
module "naming_primary" {
    source        = "Build5Nines/naming/azurerm"
    organization  = "b59"
    environment   = "dev"
    location      = "westeurope"
    name_suffix   = ["{org}", "{env}", "{loc}"] # b59-dev-weu
}
```

## Customizing the Azure Region / Location Abbreviations

Override region abbreviations:

```hcl
module "naming_primary" {
    source        = "Build5Nines/naming/azurerm"
    organization  = "b59"
    environment   = "prod"
    location      = "East US"
    location_abbreviations = {
        eastus = "east"    # overrides default "eus"
        westus = "west"
    }
}
```

## Customizing the Secondary Location / Azure Region Pair

Override the secondary location by setting a custom secondary region on the primary module:

```hcl
module "naming_primary" {
    source              = "Build5Nines/naming/azurerm"
    organization        = "b59"
    environment         = "prod"
    location            = "East US"
    location_secondary  = "North Central US  # or "northcentralus"
}

# Now module.naming_primary.location_secondary == "North Central US"
```

By default, the module will lookup the Microsoft Region Pair to return for the `location_secondary` output from the module. By setting the `location_secondary` explicitly, you can override this behavior by setting the secondary location needed for your own disaster recovery plans.

---
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `organization` | Organization / business unit segment. | string | "" | yes* |
| `environment` | Environment segment (dev, test, prod, etc.). | string | "" | yes* |
| `location` | Azure region (display or programmatic). | string | n/a | yes |
| `name_suffix` | Ordered list of pattern tokens / literals forming the suffix. Tokens: `{org}`, `{loc}`, `{env}`. | list(string) | `["{org}", "{loc}", "{env}"]` | no |
| `location_abbreviations` | Map of region -> abbreviation overrides (display or programmatic keys). | map(string) | `{}` | no |
| `location_secondary` | Optional override for the secondary region. When set (non-empty), the `location_secondary` output will equal this value instead of the computed Microsoft regional pair. | string | "" | no |

`organization` / `environment` default to empty strings; supplying them is strongly recommended for meaningful names.

---
## Outputs

| Name | Description |
|------|-------------|
| `base_suffix` | Final joined suffix string (e.g. `b59-eus-prod`). |
| `prefix` | The full upstream Azure naming module instance (access resource names via `prefix.<resource>.name`). |
| `organization` | Echo of `var.organization`. |
| `environment` | Echo of `var.environment`. |
| `location` | Original provided location input. |
| `location_abbreviation` | Resolved abbreviation (override > JSON > canonical short name). |
| `location_secondary` | Secondary region. If `var.location_secondary` is set (non-empty), this output equals that value; otherwise it is the paired/canonicalized region from `region_pair.json`. |

Example referencing an output:
```hcl
locals {
    rg_name     = module.naming_primary.prefix.resource_group.name
    storage_slug = module.naming_primary.prefix.storage_account.slug  # "st"
}
```

---
## Internals
* Canonicalization: `location_canonical = lower(replace(var.location, " ", ""))`.
* Abbreviations: Merge of JSON defaults + raw overrides + canonicalized override keys.
* Region pairing: `region_pair.json` maps both display and programmatic names to a paired region.
* Suffix expansion: Each element of `var.name_suffix` has tokens replaced; result list joined into a single string by the upstream module when composing names.
* Upstream module call:
    ```hcl
    module "azure_name_prefix" {
        source = "Azure/naming/azurerm"
        suffix = local.name_suffix
    }
    ```

---
## Advanced Usage
* Use `name_unique` for resources that require globally unique naming (storage accounts, key vaults, etc.).
* Derive secondary region infra with `location_secondary`.
* Compose additional naming layers by appending static literals in `name_suffix` (e.g. add a workload slug `{org}-{loc}-{env}-app`).
* Inspect constraints before naming collisions: `module.naming_primary.prefix.storage_account.max_length`.

---
## Region Data Files
| File | Purpose |
|------|---------|
| `data/region_abbr.json` | Default abbreviations keyed by canonical short region names. |
| `data/region_pair.json` | Region pairing / canonicalization map (primary -> secondary). |

Additions/changes are simple JSON edits; prefer PRs with minimal diff noise.

---
## Contributing
1. Update JSON data files for new regions / pairings.
2. Adjust validation list in `variables.tf` when Azure adds regions.
3. Keep abbreviations concise (≤ 4–5 chars recommended).
4. Add tests or examples when introducing new behavior.

---
## Notes & Recommendations
* Keep to lowercase alphanumerics in overrides for broad resource compatibility.
* Sovereign clouds (Gov, China) not yet included—future enhancement could introduce alternate data files.
* Always review resource-specific max length constraints when expanding the suffix pattern.

---
## License
Copyright (c) 2025 Build5Nine LLC. See `LICENSE` for details.

---
## Inspiration / Upstream
This module wraps and extends the Microsoft `Azure/naming/azurerm` module, adding organizational & regional context consistency while reusing its comprehensive resource naming logic.

---
## Example: Multi‑Region Deployment
```hcl
module "naming_primary" {
    source       = "Build5Nines/naming/azurerm"
    organization = "b59"
    environment  = "prod"
    location     = "East US"
}

module "naming_secondary" {
    source       = "Build5Nines/naming/azurerm"
    organization = module.naming_primary.organization
    environment  = module.naming_primary.environment
    location     = module.naming_primary.location_secondary
}

resource "azurerm_resource_group" "primary" {
    name     = module.naming_primary.prefix.resource_group.name
    location = module.naming_primary.location
}

resource "azurerm_resource_group" "secondary" {
    name     = module.naming_secondary.prefix.resource_group.name
    location = module.naming_secondary.location
}
```

---
## Troubleshooting
| Symptom | Cause | Fix |
|---------|-------|-----|
| Validation error for `location` | Region not in allow list | Use a supported region or update `variables.tf`. |
| Unexpected abbreviation | Override not applied | Ensure key matches display or programmatic name; canonical form will also work. |
| Missing paired region | Pair absent in `region_pair.json` | Add entry mapping both display & programmatic names. |

---
## FAQ
**Q: Why an array (`name_suffix`) instead of a single template string?**  
Allows easier reordering and alignment with upstream module expectations (`suffix` accepts list).  
**Q: Can I add a workload slug?**  
Yes—append a literal: `["{org}", "{loc}", "{env}", "api"]`.  
**Q: Is `prefix` really a string?**  
No—it's the entire upstream naming module instance; treat it like `module.<name>.<resource>.name`.

---
## Future Ideas
* Optional inclusion of sovereign clouds via separate data file.
* Automatic region list refresh script.
* Toggle for including subscription / tenant contextual slugs.

---
## Acknowledgments
Built by [Chris Pietschmann](https://pietschsoft.com); inspired by Microsoft's Azure naming guidance and the `Azure/naming/azurerm` module.
