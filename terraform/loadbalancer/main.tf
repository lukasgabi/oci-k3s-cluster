resource "oci_load_balancer_load_balancer" "this" {
  #Required
  compartment_id = var.compartment_id
  display_name   = "k3s-loadbalancer"
  shape          = "Flexible"
  subnet_ids     = [var.subnet_id]

  network_security_group_ids = [oci_core_network_security_group.this.id]

  reserved_ips {
    id = var.public_ip_id
  }
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
}

resource "oci_core_network_security_group" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "K3s Ingress Loadbalancer"
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

resource "oci_core_network_security_group_security_rule" "allow_http" {
  network_security_group_id = oci_core_network_security_group.this.id
  protocol                  = "6" // TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
  direction = "INGRESS"
}

resource "oci_core_network_security_group_security_rule" "allow_https" {
  network_security_group_id = oci_core_network_security_group.this.id
  protocol                  = "6" // TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
  direction = "INGRESS"
}

resource "oci_load_balancer_backend_set" "http" {
  health_checker {
    protocol = "TCP"
    port     = 80
  }
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = "k3s-backend-http"
  policy           = "WEIGHTED ROUND ROBIN"
}

resource "oci_load_balancer_backend" "http" {
  for_each         = toset(["10.0.0.11", "10.0.0.12", "10.0.0.13", "10.0.0.14"])
  backendset_name  = oci_load_balancer_backend_set.http.name
  ip_address       = each.key
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  port             = 80
}

resource "oci_load_balancer_listener" "http" {
  default_backend_set_name = oci_load_balancer_backend_set.http.name
  load_balancer_id         = oci_load_balancer_load_balancer.this.id
  name                     = "http-listener"
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "https" {
  health_checker {
    protocol = "TCP"
    port     = 443
  }
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = "k3s-backend-https"
  policy           = "WEIGHTED ROUND ROBIN"
}

resource "oci_load_balancer_backend" "https" {
  for_each         = toset(["10.0.0.11", "10.0.0.12", "10.0.0.13", "10.0.0.14"])
  backendset_name  = oci_load_balancer_backend_set.https.name
  ip_address       = each.key
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  port             = 443
}

resource "oci_load_balancer_listener" "https" {
  default_backend_set_name = oci_load_balancer_backend_set.https.name
  load_balancer_id         = oci_load_balancer_load_balancer.this.id
  name                     = "https-listener"
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "api" {
  health_checker {
    protocol = "TCP"
    port     = 6443
  }
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = "k3s-backend-api"
  policy           = "WEIGHTED ROUND ROBIN"
}

resource "oci_load_balancer_backend" "api" {
  for_each         = toset(["10.0.0.11", "10.0.0.12"])
  backendset_name  = oci_load_balancer_backend_set.api.name
  ip_address       = each.key
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  port             = 6443
}

resource "oci_load_balancer_listener" "api" {
  default_backend_set_name = oci_load_balancer_backend_set.api.name
  load_balancer_id         = oci_load_balancer_load_balancer.this.id
  name                     = "kube-api-listener"
  port                     = 6443
  protocol                 = "TCP"
}
