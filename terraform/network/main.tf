resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id

  cidr_blocks = [
    "10.0.0.0/24"
  ]
  display_name = "cluster-vcn"
  dns_label    = "internal"
}

resource "oci_core_default_security_list" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id

  display_name = "Outbound only (default)"

  egress_security_rules {
    protocol    = "all" // TCP
    description = "Allow outbound"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol    = "all"
    description = "Allow inter-subnet traffic"
    source      = "10.0.0.0/24"
  }
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  enabled        = true
}

resource "oci_core_default_route_table" "this" {
  compartment_id             = var.compartment_id
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "this" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.this.id
  cidr_block        = oci_core_vcn.this.cidr_blocks[0]
  display_name      = "cluster subnet"
  security_list_ids = [oci_core_vcn.this.default_security_list_id]
}

resource "oci_core_network_security_group" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "Permit SSH"
}

# TODO should be removed
resource "oci_core_network_security_group_security_rule" "allow_ssh" {
  network_security_group_id = oci_core_network_security_group.this.id
  protocol                  = "6" // TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
  direction = "INGRESS"
}

resource "oci_core_network_security_group_security_rule" "allow_control_plane" {
  network_security_group_id = oci_core_network_security_group.this.id
  protocol                  = "6" // TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
  direction = "INGRESS"
}
