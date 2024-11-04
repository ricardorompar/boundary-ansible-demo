terraform {
  required_providers {

    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.15"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.7.0"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.2"
    }
  }
}

# Declare the provider for the AWS resource to be managed by Terraform
provider "aws" {
  region = var.region
}

# Declare the provider for the HashiCorp Boundary resource to be managed by Terraform
provider "boundary" {
  # Use variables to provide values for the provider configuration
  addr                   = ""
  auth_method_id         = var.authmethod
  auth_method_login_name = var.username
  auth_method_password   = var.password
}

# Remote Backend to obtain VPC details 
data "terraform_remote_state" "local_backend" {
  backend = "local"

  config = {
    path = "../Plataforma/terraform.tfstate"
  }
}

# Remote Backend to obtain Vault Token 
data "terraform_remote_state" "local_backend_vault" {
  backend = "local"

  config = {
    path = "vault_config/terraform.tfstate"
  }
}