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
  name                     = var.webapp_subnet_name
  ip_cidr_range            = var.webapp_subnet_cidr
  network                  = google_compute_network.vpc.self_link
  region                   = var.region
  private_ip_google_access = true # Enable private IP Google access

}

resource "google_compute_subnetwork" "db_subnet" {
  name                     = var.db_subnet_name
  ip_cidr_range            = var.db_subnet_cidr
  network                  = google_compute_network.vpc.self_link
  region                   = var.region
  private_ip_google_access = true # Enable private IP Google access

}



#------------------------------------------------------------------------------------------------------------
# Use to create a global external IP address
resource "google_compute_global_address" "private_ip_address" {
  name          = var.private_ip_address_name
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
  name                = var.db_instance_name
  region              = var.region
  database_version    = var.sql-db
  depends_on          = [google_service_networking_connection.networ_connection]
  deletion_protection = false

  settings {
    tier              = var.tier
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    availability_type = var.availability_type
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.self_link
    }
  }
}

# Randomly generated password
resource "random_password" "generated_password" {
  length           = var.password_length
  special          = true
  override_special = var.special_character

}
# Use to configure custom route advertisements for a network peering connection
resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering              = google_service_networking_connection.networ_connection.peering
  network              = google_compute_network.vpc.name
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.db_instance.name
}

#Cloud SQL user creation
resource "google_sql_user" "database_user" {
  name     = var.db_user_name
  instance = google_sql_database_instance.db_instance.name
  password = random_password.generated_password.result
}

# Route creation for webapp subnet
resource "google_compute_route" "webapp_route" {
  depends_on = [
    google_sql_database_instance.db_instance,
  ]
  name             = var.webapp_route_name
  network          = google_compute_network.vpc.self_link
  dest_range       = var.dest_range
  priority         = var.proiority
  next_hop_gateway = var.next_hop_gateway
}
resource "google_compute_address" "static" {
  name = var.stack_type_ipv4
}
resource "google_compute_instance" "webapp-instance" {
  name         = var.webapp_instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.instance_tags
  depends_on   = [google_sql_database_instance.db_instance, google_service_account.vm_service_account]

  boot_disk {
    initialize_params {
      image = var.instance_image
      size  = var.image_size
      type  = var.image_type
    }

  }
  network_interface {
    access_config {
      network_tier = var.network_tier
     // nat_ip       = google_compute_address.static.address
    }

    queue_count = 0
    stack_type  = var.stack_type
    network     = google_compute_network.vpc.self_link
    subnetwork  = google_compute_subnetwork.webapp_subnet.self_link
  }
  metadata = {
    startup-script = <<-EOT
    #!/bin/bash
    set -e

    # Change directory to /opt
    cd /opt

    # Create a .env file with database connection details
    if [ ! -f /opt/.env ]; then
      echo "MYSQL_DATABASE=${google_sql_database.database.name}" >> /opt/.env
      echo "MYSQL_USER=${google_sql_user.database_user.name}" >> /opt/.env
      echo "MYSQL_PASSWORD=${google_sql_user.database_user.password}" >> /opt/.env
      echo "MYSQL_HOST=${google_sql_database_instance.db_instance.private_ip_address}" >> /opt/.env
      echo "ENV = prod" >> /opt/.env
    fi
    $(cat ${file(var.script_file)})
  EOT
  }
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.

    email  = google_service_account.vm_service_account.email
    scopes = [var.cloud_platform_scope] # Add required scopes
  }

}

#------------------------------------------------------------------------------------------------------------

# Retrieve the managed zone ID for the DNS zone
data "google_dns_managed_zone" "webapp_zone" {
  name = var.dns_var_zone # Specify your Cloud DNS zone name here
}

# Retrieve the private IP address of the VM instance
data "google_compute_instance" "webapp_instance" {
  depends_on = [google_compute_instance.webapp-instance]

  name    = var.webapp_instance_name
  zone    = var.zone
  project = var.project_id
}

# Create or update A record in Cloud DNS zone
resource "google_dns_record_set" "webapp_dns" {

  managed_zone = data.google_dns_managed_zone.webapp_zone.name
  name         = var.webapp_dns_name
  type         = var.webapp_dns_type_A
  ttl          = var.webapp_ttl
  rrdatas      = [data.google_compute_instance.webapp_instance.network_interface[0].access_config[0].nat_ip]
}

# Create a Service Account
resource "google_service_account" "vm_service_account" {
  account_id   = var.vm_service_account_id
  display_name = var.vm_service_display_name
}

# Bind Roles to the Service Account
resource "google_project_iam_binding" "logging_admin_binding" {
  # depends_on = [google_service_account.vm_service_account]

  project = var.project_id
  role    = var.logging_role

  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer_binding" {
  # depends_on = [google_service_account.vm_service_account]

  project = var.project_id
  role    = var.metric_role

  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}

#------------------------------------------------------------------------------------------------------------

#Firewall rules for the webapp

# Firewall explicitly denies all traffic
resource "google_compute_firewall" "webapp_denyall_firewall" {
  name        = var.webapp_denyall_firewall_name
  network     = google_compute_network.vpc.self_link
  target_tags = var.instance_tags
  priority    = var.higher_priority

  deny {
    protocol = var.protocol
    ports    = []
  }

  source_ranges = var.source_ranges
}

# Create a firewall rule to allow traffic to your application port
resource "google_compute_firewall" "allow_app_traffic" {
  name     = var.allowed_firewall_name
  network  = google_compute_network.vpc.self_link
  priority = var.lower_priority

  allow {
    protocol = var.protocol
    ports    = [var.allowed_ports, var.allowed_sql_port] # Specify the port your application listens to
  }
  target_tags   = var.instance_tags
  source_ranges = var.source_ranges # Allow traffic from any IP address on the internet
}

# Create a firewall rule to disallow traffic to SSH port from the internet
resource "google_compute_firewall" "deny_ssh_from_internet" {
  name     = var.denied_firewall_name
  network  = google_compute_network.vpc.self_link
  priority = var.lower_priority


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
