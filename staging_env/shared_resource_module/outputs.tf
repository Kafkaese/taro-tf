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

# Login server for the container registry
output "acr-login" {
  value = azurerm_container_registry.container-registry.login_server
}

output "acr-user" {
  value = azurerm_container_registry.container-registry.admin_username
}

output "acr-password" {
  value = azurerm_container_registry.container-registry.admin_password
  sensitive = true
}