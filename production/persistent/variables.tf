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
