# Create an organisation scope within global, named "ops-org"
# The global scope can contain multiple org scopes
resource "boundary_scope" "org" {
  scope_id                 = "global"
  name                     = "Demo"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

/* Create a project scope within the "ops-org" organsation
Each org can contain multiple projects and projects are used to hold
infrastructure-related resources
*/
resource "boundary_scope" "project" {
  name                     = "Ansible_Boundary_project"
  description              = "SSH test machines to demo connection with Ansible"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_credential_store_vault" "vault" {
  name        = "certificates-store"
  description = "My first Vault credential store!"
  address     = data.terraform_remote_state.local_backend.outputs.vault_public_url
  token       = data.terraform_remote_state.local_backend_vault.outputs.boundary_token
  scope_id    = boundary_scope.project.id
  namespace   = "admin"
}

resource "boundary_credential_library_vault_ssh_certificate" "ssh" {
  name                = "certificates-library"
  description         = "Certificate Library"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "ssh-client-signer/sign/boundary-client" # change to Vault backend path
  username            = "ubuntu"
  key_type            = "ecdsa"
  key_bits            = 521

  extensions = {
    permit-pty = ""
  }
}



resource "boundary_host_catalog_static" "aws_instance" {
  name        = "ssh-catalog"
  description = "SSH catalog"
  scope_id    = boundary_scope.project.id
}

resource "boundary_host_static" "ssh" {
  for_each = { for i, instance in aws_instance.ssh_injection_target : i => instance }
  name            = "ssh-host-${each.value.id}"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id
  address         = each.value.public_ip
}

resource "boundary_host_set_static" "ssh" {
  name            = "ssh-host-set"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id

  host_ids = [
    for target in boundary_host_static.ssh : target.id
  ]
}


resource "boundary_target" "ssh" {
  type        = "ssh"
  name        = "boundary_ansible_target"
  description = "Target example for interacting with Ansible"
  #egress_worker_filter     = " \"sm-egress-downstream-worker1\" in \"/tags/type\" "
  #ingress_worker_filter    = " \"sm-ingress-upstream-worker1\" in \"/tags/type\" "
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_static.ssh.id
  ]

  # Comment this to avoid brokeing the credentials

  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.ssh.id
  ]

}


resource "boundary_alias_target" "ssh_injection" {
  name           = "ssh_target"
  description    = "Target of SSH machines"
  scope_id       = "global"
  value          = var.alias
  destination_id = boundary_target.ssh.id
  #authorize_session_host_id = boundary_host_static.bar.id
}