variable "organization" {
    description = "Organization name for tests"
    type        = string
    default     = "b59"
}

variable "environment" {
    description = "Environment name for tests"
    type        = string
    default     = "dev"
}

variable "location" {
    description = "Azure location to test"
    type        = string
    default     = "West US 2"
}

variable "name_suffix" {
    description = "Name suffix pattern for tests"
    type        = list(string)
    default     = ["{org}", "{loc}", "{env}"]
}

variable "location_abbreviations" {
    description = "Optional overrides for region abbreviations"
    type        = map(string)
    default     = {}
}

module "test" {
    source = "../../"

    organization           = var.organization
    environment            = var.environment
    location               = var.location
    name_suffix            = var.name_suffix
    location_abbreviations = var.location_abbreviations
}

output "location_abbreviation" {
    description = "Abbreviation for the chosen location (forwarded from module under test)"
    value       = module.test.location_abbreviation
}

output "prefix_resource_group_name" {
    description = "Full generated prefix from the naming module for Azure Resource Group"
    value       = module.test.prefix.resource_group.name
}

output "location_secondary" {
    description = "Standardized Azure region name for the specified location (forwarded from module under test)"
    value       = module.test.location_secondary
}
