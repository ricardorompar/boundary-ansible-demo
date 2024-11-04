
output "target_publicIP" {
  value = [for instance in aws_instance.ssh_injection_target : instance.public_ip]
}

output "target_privateIP" {
  value = [for instance in aws_instance.ssh_injection_target : instance.private_ip]
}

output "ssh_connect" {
  value = "boundary connect ssh -target-id=${boundary_target.ssh.id}"
}

output "ssh_connect_alias" {
  value = "boundary connect ssh ${var.alias}"
}