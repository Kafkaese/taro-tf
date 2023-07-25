variable "resource_group_location" {
  default     = "germanywestcentral"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "taro-staging"
  description = "The resource group name."
}

variable "storage_account_name" {
  default = "tarostagingstorage"
}

variable "postgres_server_name" {
    default = "taro-staging-postgres-server"
  
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

variable "container_registry_name" {
  default = "tarostagingregistry"
}