variable "resource_group_location" {
  default     = "germanywestcentral"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "taro-staging"
  description = "The resource group name."
}


variable "container_registry_name" {
  default = "tarostagingregistry"
  description = "Name of container registry"
}