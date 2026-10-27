locals {
  # swarm-1, swarm-2, swarm-3 ...
  nodes  = [for i in range(var.node_count) : "swarm-${i + 1}"]
  leader = local.nodes[0]
  tag    = "swarm"
}

# ---------------------------------------------------------------- Addresses

# Public address of swarm-1. The DNS A record points here, so it must survive VM restarts.
resource "google_compute_address" "swarm1_public" {
  name         = "swarm-1-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

# Fixed private address of swarm-1, used by the other nodes to join the swarm.
resource "google_compute_address" "swarm1_internal" {
  name         = "swarm-1-internal-ip"
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = var.subnetwork
}

# ---------------------------------------------------------------- Identity

# The nodes share a token through GCE guest attributes. A node that joins reads
# the leader's attributes, which needs read-only access to Compute Engine.
resource "google_service_account" "swarm_node" {
  account_id   = "swarm-node"
  display_name = "Docker Swarm nodes"
}

resource "google_project_iam_member" "swarm_node_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.swarm_node.email}"
}

# ---------------------------------------------------------------- Firewall

# Caddy: HTTPS, certificate validation (port 80) and the HTTP to HTTPS redirect.
resource "google_compute_firewall" "swarm_web" {
  name          = "swarm-web"
  network       = var.network
  direction     = "INGRESS"
  source_ranges = var.web_source_ranges
  target_tags   = [local.tag]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# SSH for administration, CI deploys and tunnels to the databases and Portainer.
resource "google_compute_firewall" "swarm_ssh" {
  name          = "swarm-ssh"
  network       = var.network
  direction     = "INGRESS"
  source_ranges = var.ssh_source_ranges
  target_tags   = [local.tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Swarm control and overlay traffic, allowed only between the swarm nodes themselves.
resource "google_compute_firewall" "swarm_internal" {
  name        = "swarm-internal"
  network     = var.network
  direction   = "INGRESS"
  source_tags = [local.tag]
  target_tags = [local.tag]

  allow {
    protocol = "tcp"
    ports    = ["2377", "7946"]
  }
  allow {
    protocol = "udp"
    ports    = ["7946", "4789"]
  }
}

# No rules exist for 8022, 8077, 5422, 5477 or 9443 on purpose. The APIs, the
# databases and Portainer stay on the private network and are reached through
# Caddy or an SSH tunnel.

# ---------------------------------------------------------------- VMs

resource "google_compute_instance" "node" {
  for_each = toset(local.nodes)

  name         = each.key
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [local.tag]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.boot_disk_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    # Only swarm-1 has a fixed internal address and a public one. The others get
    # an ephemeral public address, which they need for package installs.
    network_ip = each.key == local.leader ? google_compute_address.swarm1_internal.address : null

    access_config {
      nat_ip = each.key == local.leader ? google_compute_address.swarm1_public.address : null
    }
  }

  service_account {
    email  = google_service_account.swarm_node.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-guest-attributes = "TRUE"
    startup-script = templatefile("${path.module}/scripts/startup.sh.tftpl", {
      is_leader   = each.key == local.leader
      leader_name = local.leader
      leader_ip   = google_compute_address.swarm1_internal.address
      project_id  = var.project_id
      zone        = var.zone
    })
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true

  depends_on = [
    google_project_iam_member.swarm_node_compute_viewer,
    google_compute_firewall.swarm_internal,
  ]
}
