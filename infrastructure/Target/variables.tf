variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "eu-west-2"
}

variable "authmethod" {
  type = string
}

variable "alias" {
  type        = string
  description = "Alias for target"
  default = "ssh.ansible.boundary.demo"
}

variable "key_pair_name" {
  type = string
}

variable "hosts_number" {
  type = number
  description = "The amount of hosts (servers) in the target."
  default = 3
}