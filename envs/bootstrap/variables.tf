variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region for all taro production resources."
}

variable "state_bucket_prefix" {
  default     = "taro-tfstate"
  description = "Prefix for the S3 bucket that stores Terraform state. S3 bucket names must be globally unique, so a random suffix is appended to this prefix."
}

variable "lock_table_name" {
  default     = "taro-terraform-locks"
  description = "DynamoDB table used to lock Terraform state during apply, preventing two concurrent applies from corrupting it."
}
