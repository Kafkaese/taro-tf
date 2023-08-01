# Resource group name
output "rg-name" {
  value = azurerm_resource_group.rg.name
}

# Location of the resource group
output "rg-location" {
  value = azurerm_resource_group.rg.location
}

# Name of the container registry
output "acr" {
  value = azurerm_container_registry.container-registry.name
}