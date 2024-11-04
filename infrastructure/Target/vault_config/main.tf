terraform {
  required_providers {

    vault = {
      source  = "hashicorp/vault"
      version = "3.17.0"
    }

  }
}


provider "vault" {
  address = data.terraform_remote_state.local_backend.outputs.vault_public_url
  # token = var.vault_token
  namespace = "admin" # Set for HCP Vault
}

# Remote Backend to obtain VPC details 
data "terraform_remote_state" "local_backend" {
  backend = "local"

  config = {
    path = "../../Plataforma/terraform.tfstate"
  }
}