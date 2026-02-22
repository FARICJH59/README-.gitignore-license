# AxiomCore Infrastructure as Code - Main Configuration
# AWS Provider configuration for production deployment

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state management
  backend "s3" {
    bucket         = "axiomcore-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "axiomcore-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "AxiomCore"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "FARICJH59"
    }
  }
}

# VPC Configuration
module "vpc" {
  source = "./modules/vpc"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

# ECS Cluster for container orchestration
module "ecs_cluster" {
  source = "./modules/ecs"
  
  environment    = var.environment
  cluster_name   = "axiomcore-${var.environment}"
  vpc_id         = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
  certificate_arn = var.ssl_certificate_arn
}

# RDS Database (optional)
# module "database" {
#   source = "./modules/rds"
#   
#   environment         = var.environment
#   vpc_id              = module.vpc.vpc_id
#   private_subnet_ids  = module.vpc.private_subnet_ids
#   instance_class      = var.db_instance_class
# }

# ElastiCache Redis (optional)
# module "cache" {
#   source = "./modules/elasticache"
#   
#   environment        = var.environment
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnet_ids
# }

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = module.ecs_cluster.cluster_name
}
