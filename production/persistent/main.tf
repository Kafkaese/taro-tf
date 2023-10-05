# Resource group for entire taro arms-tracker project
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

# Storage account for backend of all other terraform configurations
resource "azurerm_storage_account" "storage" {
  name = "taro"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

# Container regsitry for all containers in the production environemtn (api, frontend and pipeline)
resource "azurerm_container_registry" "container-registry" {
  name                = var.container_registry_name
  
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = "Basic"
}