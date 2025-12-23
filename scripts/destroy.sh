#!/bin/bash

# AWS ECS Terraform Destroy Script
# Usage: ./scripts/destroy.sh <environment>

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

print_warning "⚠️  DESTRUCTIVE OPERATION ⚠️"
print_warning "This will destroy ALL resources in the $ENVIRONMENT environment"
echo ""

# Extra confirmation for production
if [ "$ENVIRONMENT" = "prod" ]; then
    print_error "🚨 PRODUCTION ENVIRONMENT DETECTED 🚨"
    print_warning "You are about to destroy the PRODUCTION environment!"
    echo ""
    read -p "Type 'DELETE PRODUCTION' to confirm: " -r
    echo ""
    if [[ ! $REPLY = "DELETE PRODUCTION" ]]; then
        print_status "Destruction cancelled - confirmation text did not match"
        exit 0
    fi
fi

# Standard confirmation
read -p "Are you absolutely sure you want to destroy the $ENVIRONMENT environment? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_status "Destruction cancelled by user"
    exit 0
fi

print_status "Starting destruction of environment: $ENVIRONMENT"

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
terraform init -backend-config="backend-config/$ENVIRONMENT.hcl"

# Plan destruction
print_status "Planning destruction..."
terraform plan -destroy -var-file="environments/$ENVIRONMENT/terraform.tfvars" -out="destroy-$ENVIRONMENT.tfplan"

# Final confirmation
echo ""
print_warning "Review the destruction plan above carefully."
read -p "Proceed with destruction? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_status "Destruction cancelled by user"
    rm -f "destroy-$ENVIRONMENT.tfplan"
    exit 0
fi

# Apply destruction
print_status "Destroying infrastructure..."
terraform apply "destroy-$ENVIRONMENT.tfplan"

# Clean up plan file
rm -f "destroy-$ENVIRONMENT.tfplan"

print_status "Infrastructure destroyed successfully for environment: $ENVIRONMENT"
print_warning "Remember to clean up the S3 bucket and DynamoDB table used for Terraform state if no longer needed"