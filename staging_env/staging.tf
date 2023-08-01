# Import shared resource module
module "shared-resources" {
  source = "./shared_resource_module"

  resource_group_name = var.resource_group_name
  resource_group_location = var.resource_group_location
  container_registry_name = var.container_registry_name
}