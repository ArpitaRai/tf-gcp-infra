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





