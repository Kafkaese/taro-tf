terraform {
  required_version = ">=1.0"

  backend "s3" {
    bucket         = "taro-tfstate-cb4c175e"
    key            = "persistent.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "taro-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
