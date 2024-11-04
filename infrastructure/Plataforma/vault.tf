# https://portal.cloud.hashicorp.com/

# https://support.hashicorp.com/hc/en-us/articles/4416229422739-HCP-Vault-Upgrade-FAQ

# https://developer.hashicorp.com/vault/tutorials/cloud-ops/terraform-hcp-provider-vault
# https://developer.hashicorp.com/vault/tutorials/cloud-ops/amazon-peering-hcp


resource "hcp_vault_cluster" "hcp_vault" {
  hvn_id          = hcp_hvn.hvn.hvn_id
  cluster_id      = var.vault_cluster_id
  tier            = var.vault_tier
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "token" {
  cluster_id = var.vault_cluster_id
  depends_on = [hcp_vault_cluster.hcp_vault]
}

