# This config creates the remote state backend itself (the S3 bucket and
# DynamoDB lock table that `persistent/` and `deployment/` store their state
# in), so it has a chicken-and-egg problem: it can't use that backend for its
# own state. It deliberately has no `backend` block, which makes Terraform
# fall back to plain local state (a `terraform.tfstate` file in this
# directory, already covered by .gitignore).
#
# Run this once. After applying, take the `state_bucket_name` output and
# hardcode it into the `backend "s3"` block of the persistent and deployment
# configs (currently at ../../production/persistent/providers.tf and
# ../../production/deployment/providers.tf — these paths will change once
# those move under envs/ too) (backend blocks can't reference variables or
# outputs, so this copy-paste step is unavoidable).

terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
