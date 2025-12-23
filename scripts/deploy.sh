#!/bin/bash

# AWS ECS Terraform Deployment Script
# Usage: ./scripts/deploy.sh <environment>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Environment not specified"
    echo "Usage: $0 <environment>"
    echo "Available environments: dev, staging, prod"
    exit 1
fi

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Available environments: dev, staging, prod"
    exit 1
fi

print_status "Starting deployment for environment: $ENVIRONMENT"

# Change to project root
cd "$PROJECT_ROOT"

# Check if required files exist
if [ ! -f "environments/$ENVIRONMENT/terraform.tfvars" ]; then
    print_error "Configuration file not found: environments/$ENVIRONMENT/terraform.tfvars"
    exit 1
fi

if [ ! -f "backend-config/$ENVIRONMENT.hcl" ]; then
    print_error "Backend configuration not found: backend-config/$ENVIRONMENT.hcl"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS CLI not configured or credentials not available"
    exit 1
fi

print_status "AWS credentials validated"

# Initialize Terraform with backend configuration
print_status "Initializing Terraform..."
terraform init -backend-config="backend-config/$ENVIRONMENT.hcl" -reconfigure

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Format Terraform files
print_status "Formatting Terraform files..."
terraform fmt -recursive

# Plan deployment
print_status "Planning deployment..."
terraform plan -var-file="environments/$ENVIRONMENT/terraform.tfvars" -out="terraform-$ENVIRONMENT.tfplan"

# Ask for confirmation before applying
echo ""
print_warning "Review the plan above carefully."
read -p "Do you want to apply these changes? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_status "Deployment cancelled by user"
    rm -f "terraform-$ENVIRONMENT.tfplan"
    exit 0
fi

# Apply changes
print_status "Applying changes..."
terraform apply "terraform-$ENVIRONMENT.tfplan"

# Clean up plan file
rm -f "terraform-$ENVIRONMENT.tfplan"

# Get outputs
print_status "Deployment completed successfully!"
echo ""
print_status "Application URL:"
terraform output application_url

print_status "Load Balancer DNS:"
terraform output load_balancer_dns_name

if [ "$ENVIRONMENT" = "prod" ]; then
    print_status "Dashboard URL:"
    terraform output dashboard_url
fi

print_status "Deployment completed for environment: $ENVIRONMENT"