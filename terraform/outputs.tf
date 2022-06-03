output "ssh_access" {
  description = "ssh access to k3s server"
  value = {
    primary   = "ssh rancher@${module.compute.server_1_ip}"
    secondary = "ssh rancher@${module.compute.server_2_ip}"
  }
}
