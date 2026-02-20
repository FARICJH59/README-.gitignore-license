terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration should be provided via -backend-config flags during init
  # Example: terraform init \
  #   -backend-config="bucket=axiomcore-terraform-state" \
  #   -backend-config="key=aws/terraform.tfstate" \
  #   -backend-config="region=us-east-1" \
  #   -backend-config="encrypt=true" \
  #   -backend-config="dynamodb_table=axiomcore-terraform-locks"
  backend "s3" {
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Configuration
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"
  
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  cluster_version  = var.eks_cluster_version
  node_groups      = var.node_groups
}

# RDS Database
module "rds" {
  source = "./modules/rds"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  database_subnets   = module.vpc.database_subnets
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage
}

# ElastiCache Redis
module "elasticache" {
  source = "./modules/elasticache"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnets      = module.vpc.private_subnets
  node_type    = var.redis_node_type
}

# S3 Buckets
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
  buckets      = var.s3_buckets
}

# Route53 DNS
module "route53" {
  source = "./modules/route53"
  
  project_name  = var.project_name
  domain_name   = var.domain_name
  create_zone   = var.create_dns_zone
}

# ACM SSL Certificates
module "acm" {
  source = "./modules/acm"
  
  domain_name             = var.domain_name
  subject_alternative_names = var.ssl_subject_alternative_names
  route53_zone_id         = module.route53.zone_id
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  certificate_arn = module.acm.certificate_arn
}

# CloudWatch Monitoring
module "cloudwatch" {
  source = "./modules/cloudwatch"
  
  project_name = var.project_name
  environment  = var.environment
  log_retention_days = var.log_retention_days
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  eks_cluster_name = module.eks.cluster_name
}

# Outputs
output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "rds_endpoint" {
  value       = module.rds.endpoint
  description = "RDS database endpoint"
  sensitive   = true
}

output "redis_endpoint" {
  value       = module.elasticache.endpoint
  description = "ElastiCache Redis endpoint"
}

output "alb_dns_name" {
  value       = module.alb.dns_name
  description = "Application Load Balancer DNS name"
}

output "s3_bucket_names" {
  value       = module.s3.bucket_names
  description = "S3 bucket names"
}
