# RSA key of size 4096 bits
resource "tls_private_key" "rsa_4096_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2-key"
  public_key = tls_private_key.rsa_4096_key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.rsa_4096_key.private_key_pem}' > ${var.key_pair_name}.pem && chmod 400 ./${var.key_pair_name}.pem"
  }
}