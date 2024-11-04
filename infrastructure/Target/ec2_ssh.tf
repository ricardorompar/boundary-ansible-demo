# Define the data source for the latest Ubuntu AMI
data "aws_ami" "ubuntu_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical account ID
}


resource "aws_security_group" "public_network_ssh" {
  name        = "public_ssh_injection"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.local_backend.outputs.vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = ["${data.http.current.response_body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_injection"
  }
}

# # Retrieve information about subnet1 created previously
# data "aws_subnet" "example_subnet" {
#   filter {
#     name   = "cidr-block"
#     values = ["172.31.1.0/24"]
#   }

#   filter {
#     name   = "vpc-id"
#     values = [data.terraform_remote_state.local_backend.outputs.vpc]
#   }
# }

locals {
  cloud_config_config = <<-END
    #cloud-config
    ${jsonencode({
  write_files = [
    {
      path        = "/etc/ssh/ca-key.pub"
      permissions = "0644"
      owner       = "root:root"
      encoding    = "b64"
      content     = filebase64("vault_ca.pub")
    },
  ]
})}
  END
}


resource "aws_instance" "ssh_injection_target" {
  count                  = var.hosts_number
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = "t2.micro"
  depends_on             = [aws_key_pair.ec2_key]
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.public_network_ssh.id]
  subnet_id              = aws_subnet.subnet1.id
  
  user_data_replace_on_change = true
  user_data_base64            = data.cloudinit_config.ssh.rendered

  tags = {
    Name = "SSH Injection Boundary Target"
  }
}


/* Configuring postgress Database as per 
https://developer.hashicorp.com/boundary/tutorials/credential-management/hcp-vault-cred-brokering-quickstart#setup-postgresql-northwind-demo-database
*/
data "cloudinit_config" "ssh" {
  gzip          = false
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = local.cloud_config_config
  }
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      sudo chown 1000:1000 /etc/ssh/ca-key.pub
      sudo chmod 644 /etc/ssh/ca-key.pub
      sudo echo TrustedUserCAKeys /etc/ssh/ca-key.pub >> /etc/ssh/sshd_config
      sudo echo PermitTTY yes >> /etc/ssh/sshd_config
      sudo sed -i 's/X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
      sudo echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
      sudo systemctl restart sshd

      curl 'https://api.ipify.org?format=txt' > /tmp/ip
      cat /tmp/ip
  EOF
  }
}



