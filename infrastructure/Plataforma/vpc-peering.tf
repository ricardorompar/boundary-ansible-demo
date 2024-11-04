provider "aws" {
  region = var.region
}

resource "aws_vpc" "peer" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "Boundary"
  }
  # Enabling DNS name so they can be used in some configurations
  enable_dns_hostnames = true
}

data "aws_arn" "peer" {
  arn = aws_vpc.peer.arn
}

resource "aws_security_group" "allow_vault_egress_ingress" {
  name        = "allow_vault_egress_ingress"
  description = "Allow Vault outbound traffic and some ingress"
  vpc_id      = aws_vpc.peer.id

  egress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["172.25.16.0/20"]
  }
  # Allow connection to postgres from Vault
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["172.25.16.0/20"]
  }
  # Allow LDAP from Vault to VPC
  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = ["172.25.16.0/20"]
  }

}

resource "hcp_hvn" "hvn" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
}

resource "hcp_aws_network_peering" "peer" {
  hvn_id          = hcp_hvn.hvn.hvn_id
  peering_id      = var.peering_id
  peer_vpc_id     = aws_vpc.peer.id
  peer_account_id = aws_vpc.peer.owner_id
  peer_vpc_region = data.aws_arn.peer.region
}

resource "hcp_hvn_route" "peer_route" {
  hvn_link         = hcp_hvn.hvn.self_link
  hvn_route_id     = var.route_id
  destination_cidr = aws_vpc.peer.cidr_block
  target_link      = hcp_aws_network_peering.peer.self_link
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}
