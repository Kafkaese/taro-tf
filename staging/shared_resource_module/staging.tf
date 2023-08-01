# Resource group shared by all resources in staging environment
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

# Container regsitry for all containers in the staging environemtn (api, frontend and pipeline)
resource "azurerm_container_registry" "container-registry" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}
