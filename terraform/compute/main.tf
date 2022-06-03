locals {
  server_instance_config = {
    shape_id = "VM.Standard.A1.Flex"
    ocpus    = 2
    ram      = 12
    // Canonical-Ubuntu-20.04-aarch64-2021.12.01-0
    source_id   = "ocid1.image.oc1.eu-zurich-1.aaaaaaaaeyxjpvayorruw2jr6abmpltxyxw2xj4umg5ciycpdhpvpimom2qq"
    source_type = "image"
    server_ip_1 = "10.0.0.11"
    server_ip_2 = "10.0.0.12"
    // release: v0.21.5-k3s2r1
    k3os_image = "https://github.com/rancher/k3os/releases/download/v0.21.5-k3s2r1/k3os-arm64.iso"
    metadata = {
      "ssh_authorized_keys" = join("\n", var.ssh_authorized_keys)
    }
  }
  worker_instance_config = {
    shape_id = "VM.Standard.E2.1.Micro"
    ocpus    = 1
    ram      = 1
    // Canonical-Ubuntu-20.04-aarch64-2021.12.01-0
    source_id   = "ocid1.image.oc1.eu-zurich-1.aaaaaaaagtij76alknlqce5rkagwhxaxfpkolwz7undfxaqz5wd2am6nweqa"
    source_type = "image"
    worker_ips = [
      "10.0.0.13",
      "10.0.0.14"
    ]
    // release: v0.21.5-k3s2r1
    k3os_image = "https://github.com/rancher/k3os/releases/download/v0.21.5-k3s2r1/k3os-amd64.iso"
    metadata = {
      "ssh_authorized_keys" = join("\n", var.ssh_authorized_keys)
    }
  }
}

data "oci_identity_availability_domain" "ad_1" {
  compartment_id = var.compartment_id
  ad_number      = 1
}

resource "random_string" "cluster_token" {
  length           = 48
  special          = true
  number           = true
  lower            = true
  upper            = true
  override_special = "^@~*#%/.+:;_"
}

resource "oci_core_instance" "server_1" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  display_name        = "k3s-server-1"
  shape               = local.server_instance_config.shape_id
  source_details {
    source_id   = local.server_instance_config.source_id
    source_type = local.server_instance_config.source_type
  }
  shape_config {
    memory_in_gbs = local.server_instance_config.ram
    ocpus         = local.server_instance_config.ocpus
  }
  create_vnic_details {
    subnet_id  = var.cluster_subnet_id
    private_ip = local.server_instance_config.server_ip_1
    nsg_ids    = [var.permit_ssh_nsg_id]
  }
  metadata = {
    "ssh_authorized_keys" = local.server_instance_config.metadata.ssh_authorized_keys
    "user_data" = base64encode(
      templatefile("${path.module}/templates/server_user_data.sh",
        {
          server_1_ip    = local.server_instance_config.server_ip_1,
          host_name      = "k3s-server-1",
          ssh_public_key = var.ssh_authorized_keys[0],
          token          = random_string.cluster_token.result,
          k3os_image     = local.server_instance_config.k3os_image
          tls_san        = var.k3s_tls_san
      })
    )
  }
  lifecycle {
    ignore_changes = [
      availability_domain
    ]
  }
}

resource "oci_core_instance" "server_2" {
  depends_on          = [oci_core_instance.server_1]
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  display_name        = "k3s-server-2"
  shape               = local.server_instance_config.shape_id

  source_details {
    source_id   = local.server_instance_config.source_id
    source_type = local.server_instance_config.source_type
  }

  shape_config {
    memory_in_gbs = local.server_instance_config.ram
    ocpus         = local.server_instance_config.ocpus
  }

  create_vnic_details {
    subnet_id  = var.cluster_subnet_id
    private_ip = local.server_instance_config.server_ip_2
    nsg_ids    = [var.permit_ssh_nsg_id]
  }

  metadata = {
    "ssh_authorized_keys" = local.server_instance_config.metadata.ssh_authorized_keys
    "user_data" = base64encode(
      templatefile("${path.module}/templates/server_user_data.sh",
        {
          server_1_ip    = local.server_instance_config.server_ip_1,
          host_name      = "k3s-server-2",
          ssh_public_key = var.ssh_authorized_keys[0],
          token          = random_string.cluster_token.result,
          k3os_image     = local.server_instance_config.k3os_image
          tls_san        = var.k3s_tls_san
      })
    )
  }
  lifecycle {
    ignore_changes = [
      availability_domain
    ]
  }
}

resource "oci_core_instance" "worker" {
  depends_on          = [oci_core_instance.server_2]
  count               = 2
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  display_name        = "k3s-worker-${count.index + 1}"
  shape               = local.worker_instance_config.shape_id

  source_details {
    source_id   = local.worker_instance_config.source_id
    source_type = local.worker_instance_config.source_type
  }

  shape_config {
    memory_in_gbs = local.worker_instance_config.ram
    ocpus         = local.worker_instance_config.ocpus
  }

  create_vnic_details {
    subnet_id  = var.cluster_subnet_id
    nsg_ids    = [var.permit_ssh_nsg_id]
    private_ip = local.worker_instance_config.worker_ips[count.index]
  }

  metadata = {
    "ssh_authorized_keys" = local.worker_instance_config.metadata.ssh_authorized_keys
    "user_data" = base64encode(
      templatefile("${path.module}/templates/worker_user_data.sh",
        {
          server_1_ip    = local.server_instance_config.server_ip_1,
          host_name      = "k3s-worker-${count.index + 1}",
          ssh_public_key = var.ssh_authorized_keys[0],
          token          = random_string.cluster_token.result,
          k3os_image     = local.worker_instance_config.k3os_image
    }))
  }
  lifecycle {
    ignore_changes = [
      availability_domain
    ]
  }
}
