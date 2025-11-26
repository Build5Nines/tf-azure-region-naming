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

variable "organization" {
  description = "The name part of Azure resource names representing the Organization"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment name part of Azure resource names representing the Environment"
  type        = string
  default     = ""
}

variable "location" {
  description = "The Azure Region where the Azure Resources will be deployed (e.g. East US, West US, eastus, westus, etc.)"
  type        = string
  validation {
    condition = contains([
      "Australia Central",
      "Australia Central 2",
      "Australia East",
      "Australia Southeast",
      "australiacentral",
      "australiacentral2",
      "australiaeast",
      "australiasoutheast",
      "Austria East",
      "austriaeast",
      "Belgium Central",
      "belgiumcentral",
      "Brazil South",
      "Brazil Southeast",
      "brazilsouth",
      "brazilsoutheast",
      "Canada Central",
      "Canada East",
      "canadacentral",
      "canadaeast",
      "Central India",
      "Central US",
      "Central US EUAP",
      "centralindia",
      "centralus",
      "centraluseuap",
      "Chile Central",
      "chilecentral",
      "East Asia",
      "East US",
      "East US 2",
      "East US 2 EUAP",
      "East US STG",
      "eastasia",
      "eastus",
      "eastus2",
      "eastus2euap",
      "eastusstg",
      "France Central",
      "France South",
      "francecentral",
      "francesouth",
      "Germany North",
      "Germany West Central",
      "germanynorth",
      "germanywestcentral",
      "Indonesia Central",
      "indonesiacentral",
      "Israel Central",
      "israelcentral",
      "Italy North",
      "italynorth",
      "Japan East",
      "Japan West",
      "japaneast",
      "japanwest",
      "Jio India Central",
      "Jio India West",
      "jioindiacentral",
      "jioindiawest",
      "Korea Central",
      "Korea South",
      "koreacentral",
      "koreasouth",
      "Malaysia West",
      "malaysiawest",
      "Mexico Central",
      "mexicocentral",
      "New Zealand North",
      "newzealandnorth",
      "North Central US",
      "North Europe",
      "northcentralus",
      "northeurope",
      "Norway East",
      "Norway West",
      "norwayeast",
      "norwaywest",
      "Poland Central",
      "polandcentral",
      "Qatar Central",
      "qatarcentral",
      "South Africa North",
      "South Africa West",
      "South Central US",
      "South Central US STG",
      "South India",
      "southafricanorth",
      "southafricawest",
      "southcentralus",
      "southcentralusstg",
      "Southeast Asia",
      "southeastasia",
      "southindia",
      "Spain Central",
      "spaincentral",
      "Sweden Central",
      "swedencentral",
      "Switzerland North",
      "Switzerland West",
      "switzerlandnorth",
      "switzerlandwest",
      "UAE Central",
      "UAE North",
      "uaecentral",
      "uaenorth",
      "UK South",
      "UK West",
      "uksouth",
      "ukwest",
      "West Central US",
      "West Europe",
      "West India",
      "West US",
      "West US 2",
      "West US 3",
      "westcentralus",
      "westeurope",
      "westindia",
      "westus",
      "westus2",
      "westus3",
    ], var.location)
    error_message = "The Location specified must be a valid Azure Region. You can use either the display name (e.g. 'East US') or the short name (e.g. 'eastus')."
  }
}

variable "location_secondary" {
  description = "Optional override for the secondary Azure Region to use. When provided (non-empty), this value will be exposed by the `location_secondary` output instead of the computed Microsoft regional pair."
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "The pattern to use for the name suffix in Azure resource names. This can include placeholders for organization, environment, and location."
  type        = list(string)
  default     = ["{org}", "{loc}", "{env}"]
}

variable "name_prefix" {
  description = "The pattern to use for the name prefix in Azure resource names. This can include placeholders for organization, environment, and location."
  type        = list(string)
  default     = []
}

variable "location_abbreviations" {
  description = <<EOT
Optional map of region -> abbreviation overrides. Use this to provide custom or alternate
abbreviations for regions. Keys may be either the display name (e.g. "East US") or the
programmatic short name (e.g. "eastus"). Values must be the short abbreviation string.
Example: { "eastus" = "east", "westus" = "west" }
EOT
  type        = map(string)
  default     = {}
}
