variable "project_id" {
  description = "Google Cloud Project ID"
  default     = "dev-gcp-414704"
}

variable "region" {
  description = "Google Cloud region"
  default     = "us-east1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "my-vpc"
}

variable "webapp_subnet_cidr" {
  description = "CIDR range for the webapp subnet"
  default     = "10.0.1.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR range for the db subnet"
  default     = "10.0.2.0/24"
}

variable "next_hop_gateway" {
  description = "Next hop gateway of webapp route"
  default     = "default-internet-gateway"
}

variable "dest_range" {
  description = "Destination range for webapp route"
  default     = "0.0.0.0/0"
}

variable "proiority" {
  description = "value of priority for webapp route"
  default     = 1000
}

variable "routing_mode" {
  description = "Routing mode"
  default     = "REGIONAL"
}

variable "source_ranges" {
  default = ["0.0.0.0/0"]
}

variable "instance_tags" {
  default = ["web-application"]
}

variable "allowed_firewall_name" {
  default = "allow-app-traffic"
}

variable "denied_firewall_name" {
  default = "deny-ssh-from-internet"
}

variable "allowed_ports" {
  default = "8080" # Add more ports as needed
}

variable "denied_ports" {
  default = "22" # Add more ports as needed
}

variable "protocol" {
  default = "tcp"
}

variable "instance_image" {
  default = "projects/dev-gcp-414704/global/images/webapp-packer-image-24-03-19-17-36-55"
}

variable "image_size" {
  default = 100
}

variable "image_type" {
  default = "pd-balanced"
}

variable "zone" {
  default = "us-east1-d"
}

variable "script_file" {
  default = "start-service.sh"
}

variable "stack_type" {
  default = "IPV4_ONLY"
}

variable "network_tier" {
  default = "PREMIUM"
}

variable "machine_type" {
  default = "n1-standard-4"
}

variable "sql-db" {
  default = "MYSQL_8_0"
}
variable "purpose" {
  default = "VPC_PEERING"
}

variable "address_type" {
  default = "INTERNAL"
}

variable "prefix_length" {
  default = 16
}

variable "tier" {
  default = "db-f1-micro"
}

variable "password_length" {
  default = 16
}

variable "api_service" {
  default = "servicenetworking.googleapis.com"
}

variable "disk_type" {
  default = "pd-ssd"
}

variable "disk_size" {
  default = 100
}

variable "tf_version" {
  default = ">= 4.35.0"
}

variable "availability_type" {
  default = "REGIONAL"
}

variable "webapp_subnet_name" {
  default = "webapp"
}

variable "db_subnet_name" {
  default = "db"
}

variable "private_ip_address_name" {
  default = "private-ip-address"
}

variable "db_instance_name" {
  default = "private-ip-sql-instance"
}

variable "special_character" {
  default = "!#$%&*()-_=+[]{}<>:?"
}

variable "database_name" {
  default = "webapp"
}

variable "db_user_name" {
  default = "webapp"
}

variable "webapp_route_name" {
  default = "webapp-route"
}

variable "webapp_instance_name" {
  default = "webapp-instance"
}

variable "allowed_sql_port" {
  default = "3060"
}

variable "webapp_denyall_firewall_name" {
  default = "webapp-denyall-irewall"
}

variable "higher_priority" {
  default = 1000
}

variable "lower_priority" {
  default = 999
}

variable "dns_var_zone" {
  default = "arpita-webapp-zone"
}

variable "webapp_dns_name" {
  default = "arpitara.me."
}

variable "webapp_dns_type_A" {
  default = "A"
}

variable "webapp_ttl" {
  default = 5
}

variable "vm_service_account_id" {
  default = "vm-service-account"
}

variable "vm_service_display_name" {
  default = "VM Service Account"
}

variable "logging_role" {
  default = "roles/logging.admin"
}

variable "metric_role" {
  default = "roles/monitoring.metricWriter"
}

variable "cloud_platform_scope" {
  default = "cloud-platform"
}

variable "stack_type_ipv4" {
  default = "ipv4-address"
}