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
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_storage_container" "production-backend" {
  name                  = "terraform-production-env"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "staging-backend" {
  name                  = "terraform-staging-env"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "test-backend" {
  name                  = "terraform-test-env"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_public_ip" "taro-production-api-public-ip" {
  name                = "taro-production-api-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_public_ip" "taro-production-frontend-public-ip" {
  name                = "taro-production-frontend-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_public_ip" "taro-production-reverse-proxy-public-ip" {
  name                = "taro-production-reverse-proxy-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Production"
  }
}