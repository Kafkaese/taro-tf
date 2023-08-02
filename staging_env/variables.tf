variable "resource_group_location" {
  default     = "germanywestcentral"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "taro-staging"
  description = "The resource group name."
}

/*
variable "postgres_prefix" {
    default = "staging-postgres-server"
  
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
*/
variable "container_registry_name" {
  default = "tarostagingregistry"
}

variable "container_registry_user" {
  default = "admin"
  sensitive = true
}

variable "container_registry_password" {
  default = "secret"
  sensitive = true
}