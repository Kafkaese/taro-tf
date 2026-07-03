# TODO: once envs/bootstrap has been applied, add a backend "s3" block here
# using its outputs (see envs/bootstrap/README.md), e.g.:
#
# backend "s3" {
#   bucket         = "<state_bucket_name output>"
#   key            = "persistent.tfstate"
#   region         = "<aws_region output>"
#   dynamodb_table = "<lock_table_name output>"
#   encrypt        = true
# }
#
# Until then this uses local state.

terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
