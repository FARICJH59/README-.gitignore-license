# AxiomCore Infrastructure Variables

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
  default     = ""
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "api_image" {
  description = "Docker image for API service"
  type        = string
  default     = "axiomcore/api:latest"
}

variable "frontend_image" {
  description = "Docker image for frontend service"
  type        = string
  default     = "axiomcore/frontend:latest"
}

variable "api_cpu" {
  description = "CPU units for API service"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory (MB) for API service"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "CPU units for frontend service"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (MB) for frontend service"
  type        = number
  default     = 512
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}
