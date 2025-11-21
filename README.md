# tf-azure-region-naming

Azure Resource Naming is easier and more consistent with this Terraform module. It helps you:

- Normalize Azure region inputs (both display names like "East US" and programmatic names like "eastus").
- Generate a consistent location-aware name suffix (e.g., `{org}-{loc}-{env}` -> `contoso-eus-prod`).
- Use a comprehensive, data-driven map of Azure regions to abbreviations and canonical short names.
- Leverage the official Azure naming module while keeping your own opinionated suffix pattern.

This module is ideal for teams that want to set and adhere to a clear naming convention across Azure resources.

## What this module does

- Validates `var.location` against the up-to-date list of public Azure regions (both display and short names).
- Maps the region to a short, readable abbreviation (e.g., `eastus` -> `eus`) using a JSON lookup.
- Maps any input region (display or short) to the canonical programmatic name (e.g., `East US` -> `eastus`) using a JSON lookup.
- Builds a customizable location-aware suffix using `{org}`, `{loc}`, `{env}` placeholders.
- Passes that suffix into the Azure official naming module to generate a consistent `prefix` you can use on all resources.

## Why this helps with naming conventions

Consistent naming improves discoverability, governance, and automation. This module:

- Enforces consistency for region names and abbreviations.
- Encodes your organization/environment/location into every resource name via a single, configurable pattern.
- Keeps region data separate from code (JSON files), making updates simple and reviewable.
- Provides sensible fallbacks so future regions don’t break your pipeline.

## Usage

Basic usage in your root module:

```hcl
module "azure_primary_region" {
    source       = "github.com/Build5Nines/tf-azure-region-naming"
    organization = "contoso"
    environment  = "prod"
    location     = "East US" # or "eastus"
}

# Use the generated prefix in resource names
resource "azurerm_resource_group" "rg" {
    name     = module.azure_primary_region.prefix.resource_group.name
    location = module.azure_primary_region.location
}
```

Override the suffix pattern:

```hcl
module "azure_primary_region" {
    source             = "github.com/Build5Nines/tf-azure-region-naming"
    organization       = "contoso"
    environment        = "dev"
    location           = "westeurope"
    name_suffix_pattern = "{org}-{env}-{loc}" # e.g., contoso-dev-weu
}
```

Use programmatic region names everywhere (also supported):

```hcl
module "azure_primary_region" {
    source       = "github.com/Build5Nines/tf-azure-region-naming"
    organization = "contoso"
    environment  = "stage"
    location     = "japaneast"
}
```

Optional: define a secondary region using a second module instance that automatically uses the Azure Region Pair that matches the primary region:

```hcl
module "azure_secondary_region" {
    source       = "github.com/Build5Nines/tf-azure-region-naming"
    organizaton = module.azure_primary_region.organization
    environment = module.azure_primary_region.environment
    location    = module.azure_primary_region.secondary_location
}
```

## Inputs

- `organization` (string, required): Your org or business unit identifier (e.g., `contoso`).
- `environment` (string, required): Your environment identifier (e.g., `dev`, `test`, `prod`).
- `location` (string, required): Azure region, either display name (e.g., `East US`) or programmatic short name (e.g., `eastus`).
- `name_suffix_pattern` (string, optional, default `{org}-{loc}-{env}`): Pattern for the suffix. Placeholders:
    - `{org}` -> `var.organization`
    - `{env}` -> `var.environment`
    - `{loc}` -> Region abbreviation (e.g., `eus`, `weu`, etc.)

## Outputs

- `base_suffix` (string): The computed suffix using your pattern (e.g., `contoso-eus-prod`).
- `prefix` (string): The naming prefix returned from the Azure naming module with your suffix applied.
- `organization` (string): Passthrough of `var.organization`.
- `environment` (string): Passthrough of `var.environment`.
- `location` (string): Passthrough of `var.location`.
- `location_abbreviation` (string): Abbreviated region code resolved from JSON (falls back to canonical short name when missing).
- `location_secondary` (string): Canonical programmatic region name (e.g., `eastus`).

## Data-driven region lookups

Two JSON files back the region logic:

- `data/region_abbr.json`: Map of region name -> short abbreviation. Contains both display and programmatic keys, e.g.
    - `"East US": "eus"`
    - `"eastus": "eus"`

- `data/region_pair.json`: Map of region name -> canonical programmatic name, e.g.
    - `"East US": "eastus"`
    - `"eastus": "eastus"`

These are loaded in `main.tf` using `jsondecode(file(...))`. Because the data files live in the repo, updates are simple PRs with clear diffs.

## How abbreviations are chosen

Abbreviations aim to be short and readable (e.g., `eastus` -> `eus`, `westeurope` -> `weu`). If a region is missing from `region_abbr.json`, the module falls back to the canonical short name (lowercased, spaces removed), so your pipeline won’t break if a new region appears before the data file is updated.

## Keeping regions up to date

- The validation list in `variables.tf` and the JSON files track the public Azure regions. When Microsoft adds new regions, submit a PR to:
    - Add entries to `data/region_abbr.json` and `data/region_pair.json`.
    - Optionally extend the validation list in `variables.tf` (display and programmatic names).

Tip: You can confirm the latest region list using the Azure CLI:

```bash
az account list-locations -o table
```

## How the pattern enforces convention

By driving all resource names through a single suffix pattern that encodes org, environment, and location, you:

- Ensure consistent, predictable naming across all modules and teams.
- Make it easy to search and filter by environment and region in the Azure Portal or scripts.
- Reduce drift by centralizing the logic in one place (this module + JSON data files).

## Notes

- This module uses the official [Azure naming module from Microsoft](https://github.com/Azure/terraform-azurerm-naming) (`source = "Azure/naming/azurerm"`) internally to compose the Azure resource names.
- Sovereign or restricted regions aren’t included by default. If you need Azure Government or China regions, we can add a separate JSON file or a toggle.

## Contributing

Issues and PRs are welcome. For region updates, please:

- Update both `data/region_abbr.json` and `data/region_pair.json`.
- Include both display and programmatic keys.
- Add or adjust the validation list in `variables.tf` if needed.
