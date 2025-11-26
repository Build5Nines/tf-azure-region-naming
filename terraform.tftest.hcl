// Unit tests for the root module using Terraform's built-in test framework.
// These tests exercise the module's naming logic using `command = plan` so
// they behave like unit tests (no resources are created).

test {
  # Enable parallel execution for independent runs. Individual runs may
  # still override this setting if necessary.
  parallel = true
}

run "basic-westus" {
  command = plan

  variables {
    location    = "West US"
    name_suffix = ["{loc}"]
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-wus"
    error_message = "prefix_resource_group_name did not match expected"
  }
}

// Basic East US test
run "basic-eastus" {
  command = plan

  variables {
    organization = "acme"
    environment  = "prd"
    location     = "East US"
  }

  assert {
    condition     = output.location_abbreviation == "eus"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-acme-eus-prd"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.resources.storage_account.name == "stacmeeusprd"
    error_message = "prefix.storage_account.name did not match expected"
  }

  assert {
    condition     = output.resources.sql_server.name == "sql-acme-eus-prd"
    error_message = "prefix.sql_server.name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "westus"
    error_message = "location_secondary did not match expected"
  }

  assert {
    condition     = output.organization == "acme"
    error_message = "organization did not match expected"
  }
}

// Canonical eastus (short) test
run "canonical-eastus-short" {
  command = plan

  variables {
    organization = "acme"
    environment  = "stg"
    location     = "eastus"
  }

  assert {
    condition     = output.location_abbreviation == "eus"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-acme-eus-stg"
    error_message = "prefix_resource_group_name did not match expected"
  }
}

// Custom pattern test
run "custom-pattern" {
  command = plan

  variables {
    organization = "acme"
    environment  = "dev"
    location     = "West US"
    name_suffix  = ["{env}", "{org}", "{loc}"]
  }

  assert {
    condition     = output.location_abbreviation == "wus"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-dev-acme-wus"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "eastus"
    error_message = "location_secondary did not match expected"
  }
}

// Custom pattern with ending name test
run "custom-pattern-with-ending-name" {
  command = plan

  variables {
    organization = "acme"
    environment  = "dev"
    location     = "North Central US"
    name_suffix  = ["{env}", "{org}", "{loc}", "data"]
  }

  assert {
    condition     = output.location_abbreviation == "ncus"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-dev-acme-ncus-data"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "southcentralus"
    error_message = "location_secondary did not match expected"
  }
}

run "custom-pattern-prefix-with-ending-name" {
  command = plan

  variables {
    organization = "acme"
    environment  = "dev"
    location     = "North Central US"
    name_suffix  = []
    name_prefix  = ["{env}", "{org}", "{loc}", "data"]
  }

  assert {
    condition     = output.resources.resource_group.name == "dev-acme-ncus-data-rg"
    error_message = "resource_group_name did not match expected"
  }
}

// No organization - only environment and location
run "no-organization-01" {
  command = plan

  variables {
    environment = "dev"
    location    = "North Central US"
    name_suffix = ["{env}", "{loc}", "data"]
  }

  assert {
    condition     = output.location_abbreviation == "ncus"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-dev-ncus-data"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "southcentralus"
    error_message = "location_secondary did not match expected"
  }
}

// No environment - only location and name_suffix
run "no-environment-01" {
  command = plan

  variables {
    location    = "North Central US"
    name_suffix = ["{loc}", "data"]
  }

  assert {
    condition     = output.location_abbreviation == "ncus"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-ncus-data"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "southcentralus"
    error_message = "location_secondary did not match expected"
  }
}

// Custom Location Abbreviation
run "custom-location-abbreviation-01" {
  command = plan

  variables {
    organization = "acme"
    environment  = "prd"
    location     = "East US"
    location_abbreviations = {
      "East US" = "east"
    }
  }

  assert {
    condition     = output.location_abbreviation == "east"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-acme-east-prd"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "westus"
    error_message = "location_secondary did not match expected"
  }
}

run "custom-location-abbreviation-02" {
  command = plan

  variables {
    organization = "acme"
    environment  = "prd"
    location     = "East US"
    location_abbreviations = {
      "eastus" = "east"
    }
  }

  assert {
    condition     = output.location_abbreviation == "east"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-acme-east-prd"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "westus"
    error_message = "location_secondary did not match expected"
  }
}

run "custom-location-abbreviation-03" {
  command = plan

  variables {
    organization = "acme"
    environment  = "prd"
    location     = "eastus"
    location_abbreviations = {
      "East US" = "east"
    }
  }

  assert {
    condition     = output.location_abbreviation == "east"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-acme-east-prd"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "westus"
    error_message = "location_secondary did not match expected"
  }
}

run "custom-secondary-location" {
  command = plan

  variables {
    organization       = "acme"
    environment        = "prd"
    location           = "East US"
    location_secondary = "North Central US"
  }

  assert {
    condition     = output.location_abbreviation == "eus"
    error_message = "location_abbreviation did not match expected"
  }

  assert {
    condition     = output.resources.resource_group.name == "rg-acme-eus-prd"
    error_message = "prefix_resource_group_name did not match expected"
  }

  assert {
    condition     = output.location_secondary == "North Central US"
    error_message = "location_secondary did not match expected"
  }
}