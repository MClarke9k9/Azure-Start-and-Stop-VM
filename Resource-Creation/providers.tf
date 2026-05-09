terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}


// If you run into the "Error: Terraform does not have the necessary permissions to register Resource Providers."  
// Use this instead of the provider above.

# provider "azurerm" {
#   features {}

#   resource_provider_registrations = "none"
# }