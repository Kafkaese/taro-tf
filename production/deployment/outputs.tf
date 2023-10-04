output "postgres_host" {
  value = azurerm_postgresql_flexible_server.pg-server.fqdn
}