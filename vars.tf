# Vars file (vars.tf) to store variable values
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
  default = ["8080"] # Add more ports as needed
}

variable "denied_ports" {
  default = ["22"] # Add more ports as needed
}

variable "protocol" {
  default = "tcp"
}

variable "instance_image" {
  default = "projects/dev-gcp-414704/global/images/webapp-packer-image-24-02-21-01-55-31"
}

variable "image_size" {
  default = 100
}

variable "image_type" {
  default = "pd-balanced"
}

variable "zone" {
  default = "us-east1-b"
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
  default = "e2-micro"
}