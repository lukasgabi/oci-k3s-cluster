module "network" {
  source = "./network"

  compartment_id = var.compartment_id
}

module "compute" {
  source     = "./compute"
  depends_on = [module.network]

  compartment_id      = var.compartment_id
  cluster_subnet_id   = module.network.cluster_subnet.id
  permit_ssh_nsg_id   = module.network.permit_ssh.id
  ssh_authorized_keys = var.ssh_authorized_keys
  k3s_tls_san         = "k3s.myvision.me"
}
