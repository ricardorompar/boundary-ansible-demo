# https://portal.cloud.hashicorp.com/

# https://support.hashicorp.com/hc/en-us/articles/4416229422739-HCP-Vault-Upgrade-FAQ

# https://developer.hashicorp.com/vault/tutorials/cloud-ops/terraform-hcp-provider-vault
# https://developer.hashicorp.com/vault/tutorials/cloud-ops/amazon-peering-hcp

provider "hcp" {

}

resource "hcp_boundary_cluster" "boundary" {
  cluster_id = var.boundary_cluster_id
  username   = var.username
  password   = var.password
  tier       = var.boundary_tier
}