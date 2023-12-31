terraform {
  required_version = ">=0.12"

  backend "azurerm" {
    resource_group_name  = "taro"
    storage_account_name = "taro"
    container_name       = "terraform-production-env"
    key                  = "prod.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}