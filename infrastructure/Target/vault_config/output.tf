
output "boundary_token" {
  value     = vault_token.boundary_token.client_token
  sensitive = true
}

