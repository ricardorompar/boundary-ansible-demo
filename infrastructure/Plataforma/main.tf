# Declare the required providers and their version constraints for this Terraform configuration
terraform {
  backend "local" {}
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.15"
    }
    hcp = {
      source = "hashicorp/hcp"
      version = "~>0.89"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}
