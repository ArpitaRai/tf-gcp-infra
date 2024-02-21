# Create a Terraform configuration file (network.tf) for networking setup
provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC creation
resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

# Subnet creation
resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "webapp"
  ip_cidr_range = var.webapp_subnet_cidr
  network       = google_compute_network.vpc.self_link
  region        = var.region
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "db"
  ip_cidr_range = var.db_subnet_cidr
  network       = google_compute_network.vpc.self_link
  region        = var.region
}

# Route creation for webapp subnet
resource "google_compute_route" "webapp_route" {
  name             = "webapp-route"
  network          = google_compute_network.vpc.self_link
  dest_range       = var.dest_range
  priority         = var.proiority
  next_hop_gateway = var.next_hop_gateway
}

resource "google_compute_instance" "webapp-instance" {
  boot_disk {
    initialize_params {
      image = "projects/dev-gcp-414704/global/images/webapp-packer-image-24-02-21-01-55-31"
      size  = 100
      type  = "pd-balanced"
    }

  }

  machine_type = "e2-micro"
  name         = "webapp-instance"

  network_interface {
       access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
  }

  zone = "us-east1-b"
  tags = var.instance_tags
  metadata = {
    startup-script = file("start-service.sh")
  }

}

# Create a firewall rule to allow traffic to your application port
resource "google_compute_firewall" "allow_app_traffic" {
  name    = var.allowed_firewall_name
  network = google_compute_network.vpc.self_link
  allow {
    protocol = var.protocol
    ports    = ["8080"] # Specify the port your application listens to
  }
  target_tags   = var.instance_tags
  source_ranges = var.source_ranges # Allow traffic from any IP address on the internet
}

# Create a firewall rule to disallow traffic to SSH port from the internet
resource "google_compute_firewall" "deny_ssh_from_internet" {
  name    = var.denied_firewall_name
  network = google_compute_network.vpc.self_link

  deny {
    protocol = var.protocol
    ports    = ["22"] # SSH port
  }
  target_tags   = var.instance_tags
  source_ranges = var.source_ranges # Deny traffic from any IP address on the internet
}
