variable "resource_group_location" {
  default     = "germanywestcentral"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "taro"
  description = "The resource group name."
}

variable "container_registry_name" {
  default = "taroContainerRegistry"
}

variable "image_registry_credential_user" {
  default = "admin"
  sensitive = true
}

variable "image_registry_credential_password" {
  default = "secret"
  sensitive = true
}

variable "image_registry_login_server" {
  default = "tarostagingregistry.azurecr.io"
}

variable "instance_name" {
  default = "taro-staging-frontend"
}

variable "instance_name_api" {
  default = "taro-staging-api"
}

variable "environment" {
  default = "staging"
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
  default = "taro-staging-db"
}

