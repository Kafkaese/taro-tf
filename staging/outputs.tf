output "acr_login" {
  value = azurerm_container_registry.container-registry.login_server
}

output "postgres_server" {
    value = "${azurerm_postgresql_flexible_server.pg-server.name}.postgres.database.azure.com"
}