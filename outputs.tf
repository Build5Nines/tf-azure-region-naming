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

output "base_suffix" {
  description = "The base prefix for Azure resource names based on the organization and environment."
  value       = local.name_suffix
}

output "prefix" {
  description = "The full prefix for Azure resource names including location abbreviation."
  value       = module.azure_name_prefix
}

output "organization" {
  description = "The organization name part used in the naming convention."
  value       = var.organization
}

output "environment" {
  description = "The environment name part used in the naming convention."
  value       = var.environment
}

output "location" {
  description = "The Azure Region used in the naming convention."
  value       = var.location
}

output "location_abbreviation" {
  description = "The abbreviation for the specified Azure region."
  value       = try(local.location_abbr[var.location], try(local.location_abbr[local.location_canonical], local.location_canonical))
}

output "location_secondary" {
  description = "The standardized Azure region name for the specified location."
  value       = try(local.azure_region_pair[var.location], local.azure_region_pair[local.location_canonical])
}