output "acr_login" {
  value = azurerm_container_registry.container-registry.login_server
}

output "postgres_server" {
    value = "${azurerm_postgresql_flexible_server.pg-server.name}.postgres.database.azure.com"
}

output "rg-name" {
  value = azurerm_resource_group.rg.name
}

output "rg-location" {
  value = azurerm_resource_group.rg.location
}

output "pg-server" {
  value = azurerm_postgresql_flexible_server.pg-server.name
}

output "pg-db" {
  value = azurerm_postgresql_flexible_server_database.pg-db.name
}

output "pg-firewall" {
  value = azurerm_postgresql_flexible_server_firewall_rule.pg-server-open.name
}

output "acr" {
  value = azurerm_container_registry.container-registry.name
}