resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

/*
resource "azurerm_postgresql_flexible_server" "pg-staging-server" {
  name = var.postgres_server_name
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name = "B_Standard_B1ms"
  storage_mb = 32768
  version = 11
  zone = 2
  administrator_login = var.postgres_user
  administrator_password = var.postgres_password
}

resource "azurerm_postgresql_flexible_server_database" "pg-staging-db" {
  name = var.postgres_database
  server_id = azurerm_postgresql_flexible_server.pg-staging-server.id
  charset = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_storage_account" "storage" {
  name = var.storage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}
*/
resource "azurerm_container_registry" "container-registry" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}
