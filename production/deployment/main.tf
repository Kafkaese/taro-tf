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
  delegated_subnet_id    = azurerm_subnet.postgresql_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.taro_dns_zone.id
  sku_name = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.taro_vnete_dns_zone]
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

# Virtual network
resource "azurerm_virtual_network" "taro_production_vnet" {
  name                = "taro-production-vnet"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  address_space       = ["10.0.0.0/16"]
}

# Private DNS zone
resource "azurerm_private_dns_zone" "taro_dns_zone" {
  name                = "taro.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

# Link vnet and dns zone
resource "azurerm_private_dns_zone_virtual_network_link" "taro_vnete_dns_zone" {
  name                  = "exampleVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.taro_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.taro_production_vnet.id
  resource_group_name   = var.resource_group_name
}

# Subnet for the API
resource "azurerm_subnet" "backend_subnet" {
  name = "taro-production-backend-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.taro_production_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


# Subnet for the postgresql flexible server with service endpoint
resource "azurerm_subnet" "postgresql_subnet" {
  name                 = "postgresql-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.taro_production_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.DBforPostgreSQL/flexibleServers"] 
}

# Private endpoint for postgres server
resource "azurerm_private_endpoint" "taro_postgres_endpoint" {
  name                = "taro-postgres-endpoint"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.postgresql_subnet.id

  private_service_connection {
    name                           = "taro-postgres-connection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.pg-server.id
    is_manual_connection           = false
  }
}

# Private Endpoint Connecton for postgres server
data "azurerm_private_endpoint_connection" "taro_postgres_endpoint_connection" {
  depends_on = [azurerm_private_endpoint.taro_postgres_endpoint]

  name                = azurerm_private_endpoint.taro_postgres_endpoint.name
  resource_group_name = var.resource_group_name
}

/*
# Create a network security group
resource "azurerm_network_security_group" "taro_production_network_security_group" {
  name                = "taro-production-network-security-group"
  depends_on          = [ azurerm_container_group.container-instance-api ]
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
}

# Allow incoming traffic to the PostgreSQL server only from the API container
resource "azurerm_network_security_rule" "taro_production_api_postgres_rule" {
  name                        = "allow-api-to-postgres"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 5432
  source_address_prefix       = azurerm_container_group.container-instance-api.ip_address
  destination_address_prefix  = azurerm_subnet.postgresql_subnet.address_prefixes[0]
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.taro_production_network_security_group.name
}


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
  subnet_ids          = [azurerm_subnet.postgresql_subnet.id]
  ip_address_type     = "Private"
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
