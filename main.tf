resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

resource "azurerm_postgresql_server" "pg-server" {
  name = "taro-server"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name = "B_Gen5_1"
  storage_mb = 5120
  version = 11
  ssl_enforcement_enabled = true
  auto_grow_enabled = false
  administrator_login = var.postgres_user
  administrator_login_password = var.postgres_password
}

resource "azurerm_postgresql_database" "pg-db" {
  name = var.postgres_database
  resource_group_name = azurerm_resource_group.rg.name
  server_name = azurerm_postgresql_server.pg-server.name
  charset = "UTF8"
  collation = "en-US"
}