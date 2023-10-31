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

# Virtual network
resource "azurerm_virtual_network" "taro_production_vnet" {
  name                = "taro-production-vnet"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  address_space       = ["10.0.0.0/16"]
}

# Subnet for the API
resource "azurerm_subnet" "backend_subnet" {
  name                 = "taro-production-backend-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.taro_production_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "api"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "postgres-for-api-firewall-rule" {
  name                = "api-can-access-postgres"
  server_id           = azurerm_postgresql_flexible_server.pg-server.id
  start_ip_address    = var.api_ip_address
  end_ip_address      = var.api_ip_address
  depends_on = [ azurerm_postgresql_flexible_server.pg-server ]
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

# Load balancer for API
resource "azurerm_lb" "taro-production-lb" {
  name                = "taro-production-load-balancer"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = var.api_ip_id
  }
}

# IP address pool for api load balancer
resource "azurerm_lb_backend_address_pool" "taro-production-lb-address-pool" {
  name            = "taro-api-pool"
  loadbalancer_id = azurerm_lb.taro-production-lb.id
}

# API address for lb address pool
resource "azurerm_lb_backend_address_pool_address" "taro-production-api-container-ip-address" {
  name                    = "taro-production-api-container-ip-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.taro-production-lb-address-pool.id
  ip_address              = azurerm_container_group.container-instance-api.ip_address
}

# Load balancer rule
resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.taro-production-lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "publicIPAddress"
  
}

# Container Instance for the api
resource "azurerm_container_group" "container-instance-api" {
  name                = var.container_group_name_api
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_ids = [ azurerm_subnet.backend_subnet.id ]
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

