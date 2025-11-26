# #######################################################
# Azure Resource Naming is easier with this
# Terraform Module for the AzureRM Provider
#
# Source:
# https://github.com/Build5Nines/tf-azure-region-naming
#
# Author: Chris Pietschmann (https://pietschsoft.com)
# Copyright (c) 2025 Build5Nine LLC
# #######################################################

locals {
  # Canonical short region name derived from the provided location (e.g., "East US" -> "eastus")
  location_canonical = lower(replace(var.location, " ", ""))

  # Load region abbreviations from external JSON file
  default_location_abbr = jsondecode(file("${path.module}/data/region_abbr.json"))

  # Allow consumers to override abbreviations via var.location_abbreviations.
  # `merge(default, overrides)` lets the consumer-provided entries override the defaults.
  # Normalize override keys so consumers may provide either display names ("East US") or
  # short programmatic names ("eastus") and still have their overrides apply. We create
  # a canonicalized map of overrides where keys are lowercased and spaces removed, then
  # merge it last so these canonical overrides take final precedence.
  location_abbr = merge(
    local.default_location_abbr,
    var.location_abbreviations,
    { for k, v in var.location_abbreviations : lower(replace(k, " ", "")) => v }
  )

  # Canonical region short name lookup loaded from JSON
  azure_region_pair = jsondecode(file("${path.module}/data/region_pair.json"))

  # Use explicit abbreviation when available; otherwise fall back to canonical short region name (e.g., eastus)
  # Build name suffix parts from the pattern array and then join into a string for consumers
  name_suffix = [for part in var.name_suffix :
    replace(
      replace(
        replace(
          part,
          "{org}", var.organization
        ),
        "{env}", var.environment
      ),
      "{loc}", try(local.location_abbr[local.location_canonical], try(local.location_abbr[var.location], local.location_canonical))
    )
  ]

  name_prefix = [for part in var.name_prefix :
    replace(
      replace(
        replace(
          part,
          "{org}", var.organization
        ),
        "{env}", var.environment
      ),
      "{loc}", try(local.location_abbr[local.location_canonical], try(local.location_abbr[var.location], local.location_canonical))
    )
  ]
}

# Azure Naming Module
# https://github.com/Azure/terraform-azurerm-naming
module "azure_naming" {
  source = "Azure/naming/azurerm"
  suffix = local.name_suffix
  prefix = local.name_prefix
}
