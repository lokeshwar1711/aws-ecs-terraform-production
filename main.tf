# AWS ECS Production Infrastructure
# Main configuration file

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided during terraform init
    # See backend-config/ directory for environment-specific configs
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.app_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values
locals {
  name_prefix = "${var.app_name}-${var.environment}"
  
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  # AZ configuration
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  name_prefix        = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  availability_zones = local.azs
  
  # Subnet configuration
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  enable_vpn_gateway     = var.enable_vpn_gateway
  
  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  
  # ALB security group
  alb_ingress_cidrs = var.alb_ingress_cidrs
  
  # ECS security group
  ecs_ingress_ports = var.ecs_ingress_ports
  
  tags = local.common_tags
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load-balancer"

  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  
  # Subnet configuration
  public_subnet_ids = module.networking.public_subnet_ids
  
  # Security groups
  security_group_ids = [module.security.alb_security_group_id]
  
  # SSL/TLS configuration
  domain_name           = var.domain_name
  certificate_arn       = var.certificate_arn
  enable_deletion_protection = var.environment == "prod" ? true : false
  
  # Health check configuration
  health_check_path     = var.health_check_path
  health_check_matcher  = var.health_check_matcher
  
  tags = local.common_tags
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  name_prefix = local.name_prefix
  
  # Cluster configuration
  cluster_name = "${local.name_prefix}-cluster"
  
  # Service configuration
  service_name          = "${local.name_prefix}-service"
  task_definition_family = "${local.name_prefix}-task"
  
  # Container configuration
  container_image       = var.container_image
  container_port        = var.container_port
  container_cpu         = var.container_cpu
  container_memory      = var.container_memory
  
  # Network configuration
  vpc_id            = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_ids = [module.security.ecs_security_group_id]
  
  # Load balancer integration
  target_group_arn = module.load_balancer.target_group_arn
  
  # Scaling configuration
  desired_count = var.desired_count
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity
  
  # Platform configuration
  platform_version = var.platform_version
  
  # Logging configuration
  log_group_name        = "/ecs/${local.name_prefix}"
  log_retention_days    = var.log_retention_days
  
  # Environment variables
  environment_variables = var.environment_variables
  secrets              = var.secrets
  
  tags = local.common_tags
}

# Auto Scaling Module
module "auto_scaling" {
  source = "./modules/auto-scaling"

  name_prefix = local.name_prefix
  
  # ECS service configuration
  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
  
  # Scaling configuration
  min_capacity = var.min_capacity
  max_capacity = var.max_capacity
  
  # CPU scaling policy
  cpu_target_value     = var.cpu_target_value
  cpu_scale_in_cooldown = var.cpu_scale_in_cooldown
  cpu_scale_out_cooldown = var.cpu_scale_out_cooldown
  
  # Memory scaling policy
  memory_target_value     = var.memory_target_value
  memory_scale_in_cooldown = var.memory_scale_in_cooldown
  memory_scale_out_cooldown = var.memory_scale_out_cooldown
  
  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  count = var.enable_monitoring ? 1 : 0

  name_prefix = local.name_prefix
  
  # ECS configuration
  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
  
  # Load balancer configuration
  load_balancer_arn_suffix = module.load_balancer.load_balancer_arn_suffix
  target_group_arn_suffix  = module.load_balancer.target_group_arn_suffix
  
  # Notification configuration
  sns_topic_arn = var.sns_topic_arn
  
  # Alert thresholds
  cpu_high_threshold    = var.cpu_high_threshold
  memory_high_threshold = var.memory_high_threshold
  
  tags = local.common_tags
}