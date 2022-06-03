variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "cluster_subnet_id" {
  description = "Subnet for the bastion instance"
  type        = string
}

variable "permit_ssh_nsg_id" {
  description = "NSG to permit SSH"
  type        = string
}

variable "ssh_authorized_keys" {
  description = "List of authorized SSH keys"
  type        = list(any)
}

variable "master_1_user_data" {
  description = "Commands to be ran at boot for the bastion instance. Default installs Kali headless"
  type        = string
  default     = <<EOT
#!/bin/sh
sudo apt-get update
EOT
}

variable "master_2_user_data" {
  description = "Commands to be ran at boot for the bastion instance. Default installs Kali headless"
  type        = string
  default     = <<EOT
#!/bin/sh
sudo apt-get update
EOT
}

variable "worker_user_data" {
  description = "Commands to be ran at boot for the bastion instance. Default installs Kali headless"
  type        = string
  default     = <<EOT
#!/bin/sh
sudo apt-get update
EOT
}
