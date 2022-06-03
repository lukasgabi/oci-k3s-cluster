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

module "loadbalancer" {
  source     = "./loadbalancer"
  depends_on = [module.network, module.compute]

  compartment_id = var.compartment_id
  vcn_id         = module.network.vcn.id
  subnet_id      = module.network.cluster_subnet.id
  public_ip_id   = "ocid1.publicip.oc1.eu-zurich-1.amaaaaaa6mmng7ian3qtuyrcjbf6zj2ii6bpb3eturdlsctrietb2hxgwnsa"
}
