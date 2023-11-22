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
  depends_on = [azurerm_private_dns_zone_virtual_network_link.taro_vnete_dns_zone]
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

# Subnet for the postgresql flexible server
resource "azurerm_subnet" "postgresql_subnet" {
  name                 = "postgresql-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.taro_production_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Subnet for the API
resource "azurerm_subnet" "backend_subnet" {
  name                 = "taro-production-backend-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.taro_production_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
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

# Load balancer for API
resource "azurerm_lb" "taro-production-lb" {
  name                = "taro-production-load-balancer"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

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
  virtual_network_id      = azurerm_virtual_network.taro_production_vnet.id
  ip_address              = azurerm_container_group.container-instance-api.ip_address
}

# Load balancer rule
resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.taro-production-lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8000
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [ azurerm_lb_backend_address_pool.taro-production-lb-address-pool.id ]
}

# Container Instance for the api
resource "azurerm_container_group" "container-instance-api" {
  name                = var.container_group_name_api
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_ids          = [ azurerm_subnet.backend_subnet.id ]
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
      REACT_HOST=var.frontend_ip_address
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

# Subnet for the Frontend
resource "azurerm_subnet" "frontend_subnet" {
  name                 = "taro-production-frontend-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.taro_production_vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "frontend"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
  
  service_endpoints = [ "Microsoft.Storage" ]
}

# Container Instance for the frontend
resource "azurerm_container_group" "container-instance-frontend" {
  name                = var.container_group_name_frontend
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_ids          = [ azurerm_subnet.frontend_subnet.id ]
  ip_address_type     = "Private"
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
      REACT_APP_API_HOST=var.api_host
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

### Reverse proxy

# NIC for reverse proxy vm
resource "azurerm_network_interface" "reverse-proxy-nic" {
  name                = "taro-production-reverse-proxy-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rp-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.rp_vm_public_ip_id
  }
}

# Reverse proxy subnet
resource "azurerm_subnet" "rp-subnet" {
  name = "taro-production-reverse-proxy-subnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.taro_production_vnet.name
  address_prefixes = [ "10.0.5.0/24" ]
}

# Reverse Proxy VM
resource "azurerm_linux_virtual_machine" "rp_vm" {
  name                  = "taro-production-reverse-proxy"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.reverse-proxy-nic.id]
  size                  = "Standard_B1s"
  

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "taro-production-reverse-proxy"
  admin_username                  = "adminuser"
  admin_password                  = var.rp_vm_admin_password
  disable_password_authentication = false

}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "HTTPS"
    priority = 1011
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.reverse-proxy-nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}
