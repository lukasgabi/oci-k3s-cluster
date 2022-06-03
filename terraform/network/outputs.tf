output "vcn" {
  description = "Created VCN"
  value       = oci_core_vcn.this
}

output "cluster_subnet" {
  description = "Subnet of the k3s cluster"
  value       = oci_core_subnet.this
}

output "permit_ssh" {
  description = "NSG to permit ssh"
  value       = oci_core_network_security_group.this
}

