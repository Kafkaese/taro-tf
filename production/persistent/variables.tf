variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region for all taro production resources."
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block for the taro production VPC."
}

variable "public_subnet_cidr" {
  default     = "10.0.1.0/24"
  description = "CIDR block for the public subnet holding the Postgres EC2 instance and the Lambda VPC attachment."
}

variable "postgres_user" {
  default     = "postgres"
  sensitive   = true
  description = "Postgres superuser name."
}

variable "postgres_password" {
  sensitive   = true
  description = "Postgres superuser password. No default on purpose - set it via TF_VAR_postgres_password or a gitignored terraform.tfvars, never a committed literal."
}

variable "postgres_database" {
  default     = "taro"
  description = "Name of the application database created inside Postgres."
}

variable "postgres_data_volume_gb" {
  default     = 20
  description = "Size, in GB, of the EBS volume holding Postgres's data directory."
}
