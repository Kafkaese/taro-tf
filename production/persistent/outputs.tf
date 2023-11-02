output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_registry_name" {
  value = azurerm_container_registry.container-registry.name
}

output "public_ip_id" {
  value = azurerm_public_ip.taro-production-api-public-ip.id
}

output "public_ip_address" {
  value = azurerm_public_ip.taro-production-api-public-ip.ip_address
}