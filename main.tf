resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

resource "azurerm_postgresql_server" "pg-server" {
  name = "taro-server"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku_name = "B_Gen5_1"
  storage_mb = 5120
  version = 11
  ssl_enforcement_enabled = true
  auto_grow_enabled = false
  administrator_login = var.postgres_user
  administrator_login_password = var.postgres_password
  depends_on = [ azurerm_resource_group.rg ]
}