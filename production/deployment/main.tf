# Null resource to trigger redeploy on container instances
resource "null_resource" "always_run" {
  triggers = {
    timestamp = "${timestamp()}"
  }
}

# Postgres server
resource "azurerm_postgresql_flexible_server" "pg-server" {
  name = var.postgres_server_name
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku_name = "B_Standard_B1ms"
  storage_mb = 32768
  version = 11
  administrator_login = var.postgres_user
  administrator_password = var.postgres_password
  zone = 2
}

# Database on postgres server
resource "azurerm_postgresql_flexible_server_database" "pg-db" {
  name = var.postgres_database
  server_id = azurerm_postgresql_flexible_server.pg-server.id
  charset = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_firewall_rule" "postgres-for-api-firewall-rule" {
  name                = "api-can-access-postgres"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_flexible_server.pg-server.name
  start_ip_address    = var.api_ip_adddress
  end_ip_address      = var.api_ip_adddress
}

/*
# Container Instance for the frontend
resource "azurerm_container_group" "container-instance-frontend" {
  name                = var.container_group_name_frontend
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"
  image_registry_credential {
    username = var.container_registry_credential_user
    password = var.container_registry_credential_password
    server   = var.container_registry_login_server
  }

  container {
    name   = "taro-frontend"
    image  = "${var.container_registry_login_server}/taro:frontend"
    cpu    = "0.5"
    memory = "1.5"
    environment_variables = {
      ENV=var.environment
      REACT_APP_API_HOST=azurerm_container_group.container-instance-api.ip_address
      REACT_APP_API_PORT=var.api_port
    }

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    environment = var.environment
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}
*/

# Container Instance for the api
resource "azurerm_container_group" "container-instance-api" {
  name                = var.container_group_name_api
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_ids          = [azurerm_subnet.backend_subnet.id]
  ip_address_type     = "Public"
  os_type             = "Linux"
  depends_on          = [ azurerm_postgresql_flexible_server_database.pg-db ]

  image_registry_credential {
    username = var.container_registry_credential_user
    password = var.container_registry_credential_password
    server   = var.container_registry_login_server
  }

  init_container {
    name = "pipeline"
    image = "${var.container_registry_login_server}/taro:pipeline"
    environment_variables = {
      POSTGRES_HOST=azurerm_postgresql_flexible_server.pg-server.fqdn
      POSTGRES_PORT=var.postgres_port
      POSTGRES_USER=var.postgres_user
      POSTGRES_DB=var.postgres_database
      POSTGRES_PASSWORD=var.postgres_password
    }
  }

  container {
    name   = "taro-api"
    image  = "${var.container_registry_login_server}/taro:api"
    cpu    = "0.5"
    memory = "1.5"
    environment_variables = {
      ENV=var.environment
      POSTGRES_HOST=azurerm_postgresql_flexible_server.pg-server.fqdn
      POSTGRES_PORT=var.postgres_port
      POSTGRES_DB=var.postgres_database
      POSTGRES_USER=var.postgres_user
      POSTGRES_PASSWORD=var.postgres_password
      LOG_PATH="./Log"
    }

    ports {
      port     = 8000
      protocol = "TCP"
    }
  }


  tags = {
    environment = var.environment
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}

resource "azurerm_public_ip" "taro_production_api_public_ip" {
  name = "taro-production-api-public-ip"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  allocation_method = "Static"
  
  lifecycle {
   create_before_destroy = true 
  }
  
  tags = {
    environment = var.environment  
  }
}