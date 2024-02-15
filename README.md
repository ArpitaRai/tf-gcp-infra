# Terraform Infrastructure Deployment

This repository contains Terraform code for deploying a simple Google Cloud Platform (GCP) infrastructure, including a Virtual Private Cloud (VPC) with subnets and routes. The infrastructure is defined as code and follows best practices.

## Requirements

Before you begin, ensure you have the following tools installed:

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://www.terraform.io/downloads.html)

## Google Cloud Platform Setup

1. **Enable GCP Service APIs:**
   - Go to the [Google Cloud Console](https://console.cloud.google.com/).
   - Navigate to the project and enable the required services (APIs) manually.
   - Once services are enabled, it may take 10-15 minutes for them to work.

   **Note:**
   - Ensure to enable the [Compute Engine API](https://cloud.google.com/compute/docs/reference/rest) for creating and managing virtual machine instances, networks, and related resources.

2. **Networking Infrastructure Setup:**
   - Create a Virtual Private Cloud (VPC) with specific requirements.
   - Configure subnets with routing mode set to regional.

## Infrastructure as Code with Terraform

### Installation and Setup

1. **Install and Set Up GCP CLI and Terraform:**
   - Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install).
   - Install [Terraform](https://www.terraform.io/downloads.html).
   - Run `gcloud auth login` to authenticate with your GCP account.

2. **Create Terraform Configuration:**
   - Organize the Terraform configuration files.
   - Avoid hardcoding values; use variables and environment files.
   - Allow flexibility to create multiple VPCs in the same project and region.

### Deployment

1. **Initialize Terraform:**
   ```bash
   terraform init

2. **Validate your infrastructure changes.:**
    ```bash
   terraform validate

3. **Apply your infrastructure changes.:**
    ```bash
   terraform apply 