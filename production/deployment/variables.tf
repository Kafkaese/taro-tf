variable "resource_group_location" {
  default     = "francecentral"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "taro"
  description = "The resource group name."
}

variable "container_registry_name" {
  default = "taroContainerRegistry"
}

variable "container_registry_login_server" {
  default = "tarocontainerregistry.azurecr.io"
}

variable "container_registry_credential_user" {
  sensitive = true
}

variable "container_registry_credential_password" {
  sensitive = true
}

variable "container_group_name_frontend" {
  default = "taro-frontend"
}

variable "container_group_name_api" {
  default = "taro-api"
}

variable "environment" {
  default = "production"
}

variable "postgres_server_name" {
  default = "taro-postgresql-server"
}

variable "postgres_port" {
  default = "5432"
}

variable "postgres_user" {
  default = "postgres"
  sensitive = true
}

variable "postgres_password" {
  default = "secret"
  sensitive = true
}

variable "postgres_database" {
  default = "taro-db"
}

variable "api_port" {
  default = "443"
}

variable "dev_ip" {
  default = "public IP address for dev access"
}

variable "rp_vm_admin_password" {
  sensitive  = true
}

variable "rp_vm_public_ip_id" {
}

variable "api_host" {
}