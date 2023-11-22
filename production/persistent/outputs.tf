output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_registry_name" {
  value = azurerm_container_registry.container-registry.name
}

output "rp_vm_public_ip_id" {
  value = azurerm_public_ip.taro-production-reverse-proxy-public-ip.id
}