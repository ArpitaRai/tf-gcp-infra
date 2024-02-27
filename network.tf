# Create a Terraform configuration file (network.tf) for networking setup
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Service Networking API
# resource "google_project_service" "servicenetworking" {
#   project = var.project_id
#   service = "servicenetworking.googleapis.com"
# }


# VPC creation
resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

# Subnet creation
resource "google_compute_subnetwork" "webapp_subnet" {
  name                     = "webapp"
  ip_cidr_range            = var.webapp_subnet_cidr
  network                  = google_compute_network.vpc.self_link
  region                   = var.region
  private_ip_google_access = true # Enable private IP Google access

}

resource "google_compute_subnetwork" "db_subnet" {
  name                     = "db"
  ip_cidr_range            = var.db_subnet_cidr
  network                  = google_compute_network.vpc.self_link
  region                   = var.region
  private_ip_google_access = true # Enable private IP Google access

}


#------------------------------------------------------------------------------------------------------------
# Use to create a global external IP address
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = var.purpose
  address_type  = var.address_type
  prefix_length = var.prefix_length
  network       = google_compute_network.vpc.id
}

# Plays a key role in establishing a connection between a Virtual Private Cloud (VPC) network and 
# a service provided by Google or a third-party.
resource "google_service_networking_connection" "networ_connection" {
  network                 = google_compute_network.vpc.id
  service                 = var.api_service
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "db_instance" {
  name             = "private-ip-sql-instance"
  region           = var.region
  database_version = var.sql-db

  depends_on = [google_service_networking_connection.networ_connection]

  settings {
    tier = var.tier
    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.vpc.self_link
    }
  }

  deletion_protection = false
}

# Randomly generated password
resource "random_password" "generated_password" {
  length           = var.password_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

}
# Use to configure custom route advertisements for a network peering connection
resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering              = google_service_networking_connection.networ_connection.peering
  network              = google_compute_network.vpc.name
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_sql_database" "database" {
  name     = "webapp"
  instance = google_sql_database_instance.db_instance.name
}

#Cloud SQL user creation
resource "google_sql_user" "database_user" {
  name     = "webapp"
  instance = google_sql_database_instance.db_instance.name
  password = random_password.generated_password.result
}


#------------------------------------------------------------------------------------------------------------


# Route creation for webapp subnet
resource "google_compute_route" "webapp_route" {
  depends_on = [
    google_sql_database_instance.db_instance,
  ]
  name             = "webapp-route"
  network          = google_compute_network.vpc.self_link
  dest_range       = var.dest_range
  priority         = var.proiority
  next_hop_gateway = var.next_hop_gateway
}

resource "google_compute_instance" "webapp-instance" {
  boot_disk {
    initialize_params {
      image = var.instance_image
      size  = var.image_size
      type  = var.image_type
    }

  }

  machine_type = var.machine_type
  name         = "webapp-instance"

  network_interface {
    access_config {
      network_tier = var.network_tier
    }

    queue_count = 0
    stack_type  = var.stack_type
    network     = google_compute_network.vpc.self_link
    subnetwork  = google_compute_subnetwork.webapp_subnet.self_link
  }

  zone = var.zone
  tags = var.instance_tags
  metadata = {
    startup-script = <<-EOT
    #!/bin/bash
    set -e

    # Change directory to /opt/csye6225dir
    cd /opt/csye6225dir

    # Create a .env file with database connection details
    if [ ! -f /opt/.env ]; then
      echo "MYSQL_DATABASE=${google_sql_database.database.name}" >> /opt/csye6225dir/.env
      echo "MYSQL_USER=${google_sql_user.database_user.name}" >> /opt/csye6225dir/.env
      echo "MYSQL_PASSWORD=${google_sql_user.database_user.password}" >> /opt/csye6225dir/.env
      echo "MYSQL_HOST=${google_sql_database_instance.db_instance.private_ip_address}" >> /opt/csye6225dir/.env
    fi
    # Run npm install with elevated privileges
    sudo npm install

    # Include the external script content
    $(cat ${file(var.script_file)})
  EOT
}

}

# Create a firewall rule to allow traffic to your application port
resource "google_compute_firewall" "allow_app_traffic" {
  name    = var.allowed_firewall_name
  network = google_compute_network.vpc.self_link
  allow {
    protocol = var.protocol
    ports    = [var.allowed_ports] # Specify the port your application listens to
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
    ports    = [var.denied_ports] # SSH port
  }
  target_tags   = var.instance_tags
  source_ranges = var.source_ranges # Deny traffic from any IP address on the internet
}

# resource "google_compute_firewall" "allow_ssh" {
#   name    = "allow-ssh"
#   network = google_compute_network.vpc.self_link

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["web-application"]
# }
