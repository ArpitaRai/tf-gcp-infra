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
  depends_on          = [google_service_networking_connection.networ_connection, google_kms_crypto_key_iam_binding.crypto_key]
  deletion_protection = false
  encryption_key_name = google_kms_crypto_key.sql-key.id

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
  special          = false
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
  //depends_on = [google_sql_database_instance.db_instance]
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
# resource "google_compute_instance" "webapp-instance" {
#   name         = var.webapp_instance_name
#   machine_type = var.machine_type
#   zone         = var.zone
#   tags         = var.instance_tags
#   depends_on   = [google_sql_database_instance.db_instance, google_service_account.vm_service_account]

#   boot_disk {
#     initialize_params {
#       image = var.instance_image
#       size  = var.image_size
#       type  = var.image_type
#     }

#   }
#   network_interface {
#     access_config {
#       network_tier = var.network_tier
#       // nat_ip       = google_compute_address.static.address
#     }

#     queue_count = 0
#     stack_type  = var.stack_type
#     network     = google_compute_network.vpc.self_link
#     subnetwork  = google_compute_subnetwork.webapp_subnet.self_link
#   }
#   metadata = {
#     startup-script = <<-EOT
#     #!/bin/bash
#     set -e

#     # Change directory to /opt
#     cd /opt

#     # Create a .env file with database connection details
#     if [ ! -f /opt/.env ]; then
#       echo "MYSQL_DATABASE=${google_sql_database.database.name}" >> /opt/.env
#       echo "MYSQL_USER=${google_sql_user.database_user.name}" >> /opt/.env
#       echo "MYSQL_PASSWORD=${google_sql_user.database_user.password}" >> /opt/.env
#       echo "MYSQL_HOST=${google_sql_database_instance.db_instance.private_ip_address}" >> /opt/.env
#       echo "ENV = prod" >> /opt/.env
#     fi
#     $(cat ${file(var.script_file)})
#   EOT
#   }
#   service_account {
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.

#     email  = google_service_account.vm_service_account.email
#     scopes = [var.cloud_platform_scope] # Add required scopes
#   }

# }

#------------------------------------------------------------------------------------------------------------

# Retrieve the managed zone ID for the DNS zone
data "google_dns_managed_zone" "webapp_zone" {
  name = var.dns_var_zone # Specify your Cloud DNS zone name here
}

# Retrieve the private IP address of the VM instance
# data "google_compute_instance" "webapp_instance" {
#   depends_on = [google_compute_instance.webapp-instance]

#   name    = var.webapp_instance_name
#   zone    = var.zone
#   project = var.project_id
# }

# Create or update A record in Cloud DNS zone
# resource "google_dns_record_set" "webapp_dns" {

#   managed_zone = data.google_dns_managed_zone.webapp_zone.name
#   name         = var.webapp_dns_name
#   type         = var.webapp_dns_type_A
#   ttl          = var.webapp_ttl
#   rrdatas      = [data.google_compute_instance.webapp_instance.network_interface[0].access_config[0].nat_ip]
# }

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

resource "google_project_iam_member" "pubsub_publisher_binding" {
  project = var.project_id
  role    = var.pubsub_binding
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}


#------------------------------------------------------------------------------------------------------------

resource "google_vpc_access_connector" "connector" {
  name          = var.vpc_connector
  ip_cidr_range = var.ip_connector
  network       = google_compute_network.vpc.self_link
  region        = var.region

}

# Create Pub/Sub topic
resource "google_pubsub_topic" "verify_email" {
  name = var.topic_name
}
# Create Pub/Sub subscription for the Cloud Function
resource "google_pubsub_subscription" "verify_email_subscription" {
  name                 = var.pubsub_name
  topic                = google_pubsub_topic.verify_email.id
  ack_deadline_seconds = 20

  labels = {
    retention_duration = var.retention_time # 7 days in seconds
  }
}

resource "google_storage_bucket" "static" {
  name          = var.bucket_storage
  location      = var.region
  storage_class = var.storage_class
  depends_on    = [google_kms_crypto_key_iam_binding.crypto_key_storage]
  # encryption {
  #   default_kms_key_name = google_kms_crypto_key.storage-key.id
  # }
  uniform_bucket_level_access = true
}

data "archive_file" "default" {
  type        = var.archive_type
  output_path = var.output_path
  source_dir  = var.source_dir_path
}
resource "google_storage_bucket_object" "email-verification" {
  name   = var.bucket_object
  source = data.archive_file.default.output_path
  bucket = google_storage_bucket.static.id

}
# Define the Google Cloud Function
resource "google_cloudfunctions2_function" "user_verification" {
  name        = var.serverless_fun
  location    = var.region
  description = var.description

  event_trigger {
    event_type   = var.event_type
    pubsub_topic = google_pubsub_topic.verify_email.id
  }
  service_config {
    vpc_connector                 = google_vpc_access_connector.connector.name
    vpc_connector_egress_settings = var.egress_setting
    timeout_seconds               = 300
    environment_variables = {
      MYSQL_HOST     = google_sql_database_instance.db_instance.private_ip_address
      MYSQL_USER     = google_sql_user.database_user.name
      MYSQL_PASSWORD = google_sql_user.database_user.password
      MYSQL_DATABASE = google_sql_database.database.name
      ENV            = var.env_prod
      API_KEY        = var.api_key
      MAIL_DOMAIN    = var.mail_domain
    }


  }
  build_config {
    runtime     = var.node_js
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.static.name
        object = google_storage_bucket_object.email-verification.name
      }
    }
  }

}


#--------------------------------------- Assignment #8 ---------------------------------------------------------------------

resource "google_compute_region_instance_template" "webapp-instance-template" {
  name         = var.instance_template
  machine_type = var.machine_type
  region       = var.region
  #zone         = var.zone
  tags       = var.instance_tags
  depends_on = [google_sql_database_instance.db_instance, google_service_account.vm_service_account]

  disk {
    source_image = var.instance_image
    disk_size_gb = var.image_size
  }

  network_interface {

    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link

    # default access config, defining external IP configuration
    access_config {
      network_tier = var.network_tier
    }
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


# Compute Health Check
resource "google_compute_health_check" "webapp_health_check" {
  name                = var.health_check_name
  check_interval_sec  = 5
  timeout_sec         = 3
  healthy_threshold   = 5
  unhealthy_threshold = 5
  log_config {
    enable = true
  }
  http_health_check {
    port         = var.allowed_ports
    request_path = var.healthz_url

  }

}

# Instance Group Manager

resource "google_compute_region_instance_group_manager" "webapp-server" {
  name                      = var.instance_group_name
  base_instance_name        = var.base_name_instance_group
  region                    = var.region
  distribution_policy_zones = [var.region2, var.region3, var.region4]

  version {
    instance_template = google_compute_region_instance_template.webapp-instance-template.self_link
  }

  all_instances_config {
    metadata = {
      metadata_key = var.metadata_value
    }
    labels = {
      label_key = var.local_value
    }
  }

  # target_pools = [google_compute_target_pool.appserver.id]
  # target_size  = 2

  named_port {
    name = var.instance_port_name
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.webapp_health_check.id
    initial_delay_sec = 300
  }
}

# Compute Autoscaler
resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name   = var.autoscaler_name
  target = google_compute_region_instance_group_manager.webapp-server.id
  autoscaling_policy {
    min_replicas    = 3
    max_replicas    = 6
    cooldown_period = 60
    cpu_utilization {
      target = 0.05
    }
  }
}

module "gce-lb-http" {
  source                          = "GoogleCloudPlatform/lb-http/google"
  version                         = "~> 9.0"
  managed_ssl_certificate_domains = [var.ssl_domain]
  ssl                             = true
  project                         = var.project_id
  name                            = var.lb_name
  target_tags                     = var.instance_tags
  load_balancing_scheme           = var.lb_scheme
  backends = {
    default = {
      port        = var.lb_backend_ports
      protocol    = var.lb_backend_protocol
      port_name   = var.lb_port_name
      timeout_sec = 10
      enable_cdn  = false


      health_check = {
        request_path = var.lb_healthz
        port         = var.lb_healthz_port
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Each node pool instance group should be added to the backend.
          group = google_compute_region_instance_group_manager.webapp-server.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }
  }
  http_forward = false
}


# # Create or update A record in Cloud DNS zone to point to the load balancer IP
resource "google_dns_record_set" "webapp_dns" {
  managed_zone = data.google_dns_managed_zone.webapp_zone.name
  name         = var.webapp_dns_name
  type         = var.webapp_dns_type_A
  ttl          = var.webapp_ttl
  rrdatas      = [module.gce-lb-http.external_ip]
}

#-----------------------------------------Assignment 9------------------------------------------------------------------

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}
data "google_storage_project_service_account" "gcs_account" {}
resource "random_id" "random_suffix" {
  byte_length = 4
}

resource "google_kms_key_ring" "webapp-keyring" {
  name     = "webapp-keyring-${random_id.random_suffix.hex}"
  project  = var.project_id
  provider = google-beta
  location = "us-east1"
}

resource "google_kms_crypto_key" "sql-key" {
  name            = "sql-crypto-key"
  key_ring        = google_kms_key_ring.webapp-keyring.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "2592000s"
  lifecycle {
    prevent_destroy = false
  }

}
resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.sql-key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = ["serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}"
  ]
}


resource "google_kms_crypto_key" "storage-key" {
  name            = "storage-crypto-key"
  key_ring        = google_kms_key_ring.webapp-keyring.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "2592000s"
  lifecycle {
    prevent_destroy = false
  }

}


resource "google_kms_crypto_key_iam_binding" "crypto_key_storage" {
  crypto_key_id = google_kms_crypto_key.storage-key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

# resource "google_kms_crypto_key" "vm-key" {
#   name            = "vm-crypto-key"
#   key_ring        = google_kms_key_ring.webapp-keyring.id
#   purpose         = "ENCRYPT_DECRYPT"
#   rotation_period = "2592000s"
#   lifecycle {
#     prevent_destroy = false
#   }

# }

# resource "google_kms_crypto_key_iam_binding" "sql-key-binding" {
#   crypto_key_id = google_kms_crypto_key.sql-key.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#   members = [
#     "serviceAccount:${google_service_account.key_service_account.email}",
#   ]
# }

# resource "google_kms_crypto_key_iam_binding" "storage-key-binding" {
#   crypto_key_id = google_kms_crypto_key.storage-key.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#   members = [
#     "serviceAccount:${google_service_account.key_service_account.email}",
#   ]
# }

# resource "google_kms_crypto_key_iam_binding" "vm-key-binding" {
#   crypto_key_id = google_kms_crypto_key.vm-key.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#   members = [
#     "serviceAccount:${google_service_account.key_service_account.email}",
#   ]
# }

# resource "google_project_iam_member" "sql_admin_binding" {
#   project = var.project_id
#   role    = "roles/cloudsql.admin"
#   member  = "serviceAccount:${google_service_account.key_service_account.email}"
# }


resource "google_secret_manager_secret" "secret-db-name" {
  secret_id = "MYSQL_DATABASE"
  labels = {
    label = "db-name"
  }
  replication {
    auto {}
  }
}


resource "google_secret_manager_secret_version" "secret-version-basic" {
  secret      = google_secret_manager_secret.secret-db-name.id
  secret_data = google_sql_database.database.name
}

resource "google_secret_manager_secret" "secret-db-user" {
  secret_id = "MYSQL_USER"
  labels = {
    label = "db-user"
  }
  replication {
    auto {}
  }
}


resource "google_secret_manager_secret_version" "secret-version-basic1" {
  secret      = google_secret_manager_secret.secret-db-user.id
  secret_data = google_sql_user.database_user.name
}

resource "google_secret_manager_secret" "secret-db-password" {
  secret_id = "MYSQL_PASSWORD"
  labels = {
    label = "db-password"
  }
  replication {
    auto {}
  }
}


resource "google_secret_manager_secret_version" "secret-version-basic2" {
  secret      = google_secret_manager_secret.secret-db-password.id
  secret_data = google_sql_user.database_user.password
}

resource "google_secret_manager_secret" "secret-db-host" {
  secret_id = "MYSQL_HOST"
  labels = {
    label = "db-host"
  }
  replication {
    auto {}
  }
}


resource "google_secret_manager_secret_version" "secret-version-basic3" {
  secret      = google_secret_manager_secret.secret-db-host.id
  secret_data = google_sql_database_instance.db_instance.private_ip_address
}

resource "google_secret_manager_secret" "secret-db-env" {
  secret_id = "ENV"
  labels = {
    label = "prod-env"
  }
  replication {
    auto {}
  }
}


resource "google_secret_manager_secret_version" "secret-version-basic4" {
  secret      = google_secret_manager_secret.secret-db-env.id
  secret_data = "ENV"
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
  source_ranges = [var.source_ranges1, var.source_ranges2] # Allow traffic from any IP address on the internet
  # source_ranges = [module.gce-lb-http.external_ip]

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



