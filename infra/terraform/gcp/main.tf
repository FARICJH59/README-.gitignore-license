terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration should be provided via -backend-config flags during init
  # Example: terraform init \
  #   -backend-config="bucket=axiomcore-terraform-state" \
  #   -backend-config="prefix=gcp/terraform.tfstate"
  backend "gcs" {
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# VPC Network
module "vpc" {
  source = "./modules/vpc"
  
  project_id   = var.gcp_project_id
  project_name = var.project_name
  environment  = var.environment
  network_name = "${var.project_name}-${var.environment}-vpc"
}

# GKE Cluster
module "gke" {
  source = "./modules/gke"
  
  project_id       = var.gcp_project_id
  project_name     = var.project_name
  environment      = var.environment
  network          = module.vpc.network_name
  subnetwork       = module.vpc.subnetwork_name
  cluster_version  = var.gke_cluster_version
  node_pools       = var.node_pools
}

# Cloud SQL
module "cloudsql" {
  source = "./modules/cloudsql"
  
  project_id       = var.gcp_project_id
  project_name     = var.project_name
  environment      = var.environment
  database_version = var.database_version
  tier             = var.database_tier
}

# Memorystore (Redis)
module "memorystore" {
  source = "./modules/memorystore"
  
  project_id   = var.gcp_project_id
  project_name = var.project_name
  environment  = var.environment
  memory_size_gb = var.redis_memory_size_gb
}

# Cloud Storage Buckets
module "storage" {
  source = "./modules/storage"
  
  project_id   = var.gcp_project_id
  project_name = var.project_name
  environment  = var.environment
  buckets      = var.storage_buckets
}

# Cloud DNS
module "dns" {
  source = "./modules/dns"
  
  project_id   = var.gcp_project_id
  project_name = var.project_name
  domain_name  = var.domain_name
  create_zone  = var.create_dns_zone
}

# SSL Certificates
module "ssl" {
  source = "./modules/ssl"
  
  project_name = var.project_name
  environment  = var.environment
  domain_names = var.ssl_domain_names
}

# Load Balancer
module "load_balancer" {
  source = "./modules/load_balancer"
  
  project_id      = var.gcp_project_id
  project_name    = var.project_name
  environment     = var.environment
  ssl_certificates = module.ssl.certificate_ids
}

# Cloud Monitoring
module "monitoring" {
  source = "./modules/monitoring"
  
  project_id   = var.gcp_project_id
  project_name = var.project_name
  environment  = var.environment
}

# IAM
module "iam" {
  source = "./modules/iam"
  
  project_id   = var.gcp_project_id
  project_name = var.project_name
  environment  = var.environment
}

# Outputs
output "gke_cluster_endpoint" {
  value       = module.gke.cluster_endpoint
  description = "GKE cluster endpoint"
  sensitive   = true
}

output "cloudsql_connection_name" {
  value       = module.cloudsql.connection_name
  description = "Cloud SQL connection name"
}

output "redis_host" {
  value       = module.memorystore.host
  description = "Memorystore Redis host"
}

output "load_balancer_ip" {
  value       = module.load_balancer.ip_address
  description = "Load balancer IP address"
}

output "storage_bucket_urls" {
  value       = module.storage.bucket_urls
  description = "Cloud Storage bucket URLs"
}
