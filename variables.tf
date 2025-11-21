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
}

variable "environment" {
    description = "The environment name part of Azure resource names representing the Environment"
    type        = string
}

variable "location" {
    description = "The Azure Region where the Azure Resources will be deployed (e.g. East US, West US, eastus, westus, etc.)"
    type        = string
    validation {
        condition = contains([
        # Americas
        "East US", "eastus",
        "East US 2", "eastus2",
        "West US", "westus",
        "West US 2", "westus2",
        "West US 3", "westus3",
        "Central US", "centralus",
        "North Central US", "northcentralus",
        "South Central US", "southcentralus",
        "West Central US", "westcentralus",
        "Canada Central", "canadacentral",
        "Canada East", "canadaeast",
        "Brazil South", "brazilsouth",
        "Brazil Southeast", "brazilsoutheast",
        "Mexico Central", "mexicocentral",
        "Chile Central", "chilecentral",

        # Europe
        "North Europe", "northeurope",
        "West Europe", "westeurope",
        "UK South", "uksouth",
        "UK West", "ukwest",
        "France Central", "francecentral",
        "France South", "francesouth",
        "Germany West Central", "germanywestcentral",
        "Germany North", "germanynorth",
        "Switzerland North", "switzerlandnorth",
        "Switzerland West", "switzerlandwest",
        "Norway East", "norwayeast",
        "Norway West", "norwaywest",
        "Sweden Central", "swedencentral",
        # "Sweden South", "swedensouth", # Uncomment if your subscription has access
        "Poland Central", "polandcentral",
        "Austria East", "austriaeast",
        "Belgium Central", "belgiumcentral",
        "Spain Central", "spaincentral",
        "Italy North", "italynorth",

        # Asia Pacific
        "East Asia", "eastasia",
        "Southeast Asia", "southeastasia",
        "Japan East", "japaneast",
        "Japan West", "japanwest",
        "Korea Central", "koreacentral",
        "Korea South", "koreasouth",
        "Australia East", "australiaeast",
        "Australia Southeast", "australiasoutheast",
        "Australia Central", "australiacentral",
        "Australia Central 2", "australiacentral2",
        "New Zealand North", "newzealandnorth",
        "Central India", "centralindia",
        "South India", "southindia",
        "West India", "westindia",
        "Indonesia Central", "indonesiacentral",
        "Malaysia West", "malaysiawest",

        # Middle East & Africa
        "UAE North", "uaenorth",
        "UAE Central", "uaecentral",
        "Qatar Central", "qatarcentral",
        "Israel Central", "israelcentral",
        "South Africa North", "southafricanorth",
        "South Africa West", "southafricawest"
        ], var.location)
        error_message = "The Location specified must be a valid Azure Region. You can use either the display name (e.g. 'East US') or the short name (e.g. 'eastus')."
    }
}

variable "name_suffix_pattern" {
    description = "The pattern to use for the name suffix in Azure resource names. This can include placeholders for organization, environment, and location."
    type        = string
    default     = "{org}-{loc}-{env}"
}
