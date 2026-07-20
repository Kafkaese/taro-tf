# TODO: once envs/bootstrap has been applied, add a backend "s3" block here
# using its outputs (see envs/bootstrap/README.md), e.g.:
#
# backend "s3" {
#   bucket         = "taro-tfstate-cb4c175e"
#   key            = "persistent.tfstate"
#   region         = "eu-central-1"
#   dynamodb_table = "taro-tfstate-cb4c175e"
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
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
