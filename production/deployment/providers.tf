terraform {
  required_version = ">=1.0"

  backend "s3" {
    bucket         = "taro-tfstate-cb4c175e"
    key            = "deployment.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "taro-terraform-locks"
    encrypt        = true
  }

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

data "aws_caller_identity" "current" {}

# Pulls in persistent/'s outputs (VPC, subnet, Lambda SG, Postgres's private
# IP, the SSM password parameter's name, etc.) - reads the same S3 state
# bucket persistent/ itself is stored in, just a different key, so this
# works identically whether run locally or from CI.
data "terraform_remote_state" "persistent" {
  backend = "s3"

  config = {
    bucket = "taro-tfstate-cb4c175e"
    key    = "persistent.tfstate"
    region = "eu-central-1"
  }
}
