#!/bin/bash

# Health Check Script for AWS ECS Application
# Usage: ./scripts/health-check.sh <environment>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[HEALTH CHECK]${NC} $1"
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

print_header "Starting health check for environment: $ENVIRONMENT"

# Change to project root
cd "$PROJECT_ROOT"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS CLI not configured or credentials not available"
    exit 1
fi

# Initialize Terraform to get outputs
print_status "Initializing Terraform..."
terraform init -backend-config="backend-config/$ENVIRONMENT.hcl" > /dev/null 2>&1

# Get application URL
APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "")
ALB_DNS=$(terraform output -raw load_balancer_dns_name 2>/dev/null || echo "")
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")

if [ -z "$APP_URL" ] || [ -z "$ALB_DNS" ]; then
    print_error "Could not retrieve application URL from Terraform outputs"
    exit 1
fi

print_status "Application URL: $APP_URL"
print_status "Load Balancer DNS: $ALB_DNS"

# Function to check HTTP endpoint
check_http_endpoint() {
    local url=$1
    local expected_code=${2:-200}
    
    print_status "Checking HTTP endpoint: $url"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "$expected_code" ]; then
        print_status "✅ HTTP check passed (Status: $response)"
        return 0
    else
        print_error "❌ HTTP check failed (Status: $response, Expected: $expected_code)"
        return 1
    fi
}

# Function to check ECS service health
check_ecs_service() {
    print_status "Checking ECS service health..."
    
    if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
        print_warning "ECS cluster or service name not available"
        return 1
    fi
    
    # Get service details
    service_info=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query 'services[0]' 2>/dev/null || echo "{}")
    
    if [ "$service_info" = "{}" ]; then
        print_error "❌ Could not retrieve ECS service information"
        return 1
    fi
    
    # Check running task count
    running_count=$(echo "$service_info" | jq -r '.runningCount // 0')
    desired_count=$(echo "$service_info" | jq -r '.desiredCount // 0')
    
    print_status "ECS Service Status:"
    print_status "  Running Tasks: $running_count"
    print_status "  Desired Tasks: $desired_count"
    
    if [ "$running_count" -eq "$desired_count" ] && [ "$running_count" -gt 0 ]; then
        print_status "✅ ECS service is healthy"
        return 0
    else
        print_error "❌ ECS service is unhealthy"
        return 1
    fi
}

# Function to check target group health
check_target_group_health() {
    print_status "Checking target group health..."
    
    # Get target group ARN
    tg_arn=$(terraform output -raw target_group_arn 2>/dev/null || echo "")
    
    if [ -z "$tg_arn" ]; then
        print_warning "Target group ARN not available"
        return 1
    fi
    
    # Get target health
    health_info=$(aws elbv2 describe-target-health \
        --target-group-arn "$tg_arn" \
        --query 'TargetHealthDescriptions' 2>/dev/null || echo "[]")
    
    healthy_count=$(echo "$health_info" | jq '[.[] | select(.TargetHealth.State == "healthy")] | length')
    total_count=$(echo "$health_info" | jq 'length')
    
    print_status "Target Group Health:"
    print_status "  Healthy Targets: $healthy_count"
    print_status "  Total Targets: $total_count"
    
    if [ "$healthy_count" -gt 0 ] && [ "$healthy_count" -eq "$total_count" ]; then
        print_status "✅ All targets are healthy"
        return 0
    else
        print_error "❌ Some targets are unhealthy"
        return 1
    fi
}

# Function to check CloudWatch alarms
check_cloudwatch_alarms() {
    print_status "Checking CloudWatch alarms..."
    
    # Get alarms for this application
    alarms=$(aws cloudwatch describe-alarms \
        --alarm-name-prefix "myapp-$ENVIRONMENT" \
        --query 'MetricAlarms[?StateValue==`ALARM`].AlarmName' \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$alarms" ]; then
        print_status "✅ No active CloudWatch alarms"
        return 0
    else
        print_error "❌ Active CloudWatch alarms detected:"
        echo "$alarms" | tr '\t' '\n' | while read -r alarm; do
            print_error "  - $alarm"
        done
        return 1
    fi
}

# Run health checks
echo ""
print_header "Running comprehensive health checks..."
echo ""

# Initialize counters
total_checks=0
passed_checks=0

# HTTP endpoint check
total_checks=$((total_checks + 1))
if check_http_endpoint "$APP_URL"; then
    passed_checks=$((passed_checks + 1))
fi

echo ""

# ECS service check
total_checks=$((total_checks + 1))
if check_ecs_service; then
    passed_checks=$((passed_checks + 1))
fi

echo ""

# Target group health check
total_checks=$((total_checks + 1))
if check_target_group_health; then
    passed_checks=$((passed_checks + 1))
fi

echo ""

# CloudWatch alarms check
total_checks=$((total_checks + 1))
if check_cloudwatch_alarms; then
    passed_checks=$((passed_checks + 1))
fi

echo ""
print_header "Health Check Summary"
print_status "Passed: $passed_checks/$total_checks checks"

if [ "$passed_checks" -eq "$total_checks" ]; then
    print_status "🎉 All health checks passed! Application is healthy."
    exit 0
else
    print_error "⚠️  Some health checks failed. Please investigate."
    exit 1
fi