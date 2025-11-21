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
    location_abbr = jsondecode(file("${path.module}/data/region_abbr.json"))

    # Canonical region short name lookup loaded from JSON
    azure_region_pair = jsondecode(file("${path.module}/data/region_pair.json"))

    # Use explicit abbreviation when available; otherwise fall back to canonical short region name (e.g., eastus)
    name_suffix = replace(
        replace(
            replace(
                var.name_suffix_pattern,
                "{org}", var.organization
            ),
            "{env}", var.environment
        ),
        "{loc}", try(local.location_abbr[var.location], try(local.location_abbr[local.location_canonical], local.location_canonical))
    )
}

# Azure Naming Module
# https://github.com/Azure/terraform-azurerm-naming
module "azure_name_prefix" {
    source = "Azure/naming/azurerm"
    suffix = local.name_suffix
}
