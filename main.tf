resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

resource "azurerm_postgresql_flexible_server" "pg-server" {
  name = "taro-server"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name = "B_Standard_B1ms"
  storage_mb = 32768
  version = 11
  administrator_login = var.postgres_user
  administrator_password = var.postgres_password
}

# Firewall rule for the postgres server !!! currently open to all IP addresses
resource "azurerm_postgresql_flexible_server_firewall_rule" "pg-server-open" {
  name                = "allpublic"
  server_id           = azurerm_postgresql_flexible_server.pg-server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_postgresql_flexible_server_database" "pg-db" {
  name = var.postgres_database
  server_id = azurerm_postgresql_flexible_server.pg-server.id
  charset = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_storage_account" "storage" {
  name = "taro"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}