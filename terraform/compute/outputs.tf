output "server_1_ip" {
  value = oci_core_instance.server_1.public_ip
}

output "server_2_ip" {
  value = oci_core_instance.server_2.public_ip
}
