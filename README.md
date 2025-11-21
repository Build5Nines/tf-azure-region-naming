# tf-azure-region-naming
Azure Resource Naming is easier with this Terraform Module for the AzureRM Provider


Usage:

```hcl

module "azure_primary_region" {
    source = "https://github.com/build5nines/tf-azure-region-naming"
    organization = "b59"
    environment  = "dev"
    location     = "East US"
}

module "azure_secondary_region" {
    source = "https://github.com/build5nines/tf-azure-region-naming"
    organizaton = module.azure_primary_region.organization
    environment = module.azure_primary_region.environment
    location    = module.azure_primary_region.secondary_location
}

resource "azurerm_resource_group" "b59rg" {
    name = module.azure_primary_region.prefix.resource_group.name
}

```