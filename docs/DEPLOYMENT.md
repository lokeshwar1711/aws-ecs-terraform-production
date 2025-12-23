# Deployment Guide

This guide walks you through deploying the AWS ECS infrastructure from scratch to production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Environment Configuration](#environment-configuration)
4. [Backend Setup](#backend-setup)
5. [Development Deployment](#development-deployment)
6. [Production Deployment](#production-deployment)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

Install the following tools before proceeding:

```bash
# Terraform
terraform version  # Should be >= 1.5.0

# AWS CLI
aws --version  # Should be >= 2.0

# Pre-commit (optional but recommended)
pre-commit --version

# Docker (for building application images)
docker --version
```

### AWS Account Setup

1. **AWS Account**: Active AWS account with admin or appropriate permissions
2. **IAM User**: Create IAM user with programmatic access
3. **Required Permissions**:
   - EC2 (VPC, Security Groups, NAT Gateway)
   - ECS (Cluster, Service, Task Definition)
   - ELB (Application Load Balancer)
   - IAM (Roles, Policies)
   - CloudWatch (Logs, Metrics)
   - Route53 (optional, for DNS)
   - ACM (optional, for SSL certificates)

### Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Verify configuration
aws sts get-caller-identity
```

Output should show your account ID and user ARN.

## Initial Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd aws-ecs-terraform-production
```

### 2. Install Pre-commit Hooks (Recommended)

```bash
pip install pre-commit
pre-commit install
```

This ensures code quality and security checks before each commit.

### 3. Review Project Structure

```bash
tree -L 2
```

Familiarize yourself with the directory structure.

## Environment Configuration

### 1. Choose Environment

This project supports multiple environments:
- `dev` - Development environment
- `prod` - Production environment

### 2. Configure Variables

Copy and customize the example file:

```bash
# For development
cp terraform.tfvars.example environments/dev/terraform.tfvars

# Edit the file
vim environments/dev/terraform.tfvars
```

### 3. Required Variables

Update these variables in your `terraform.tfvars`:

```hcl
# Basic Configuration
app_name    = "myapp"
environment = "dev"
aws_region  = "us-west-2"
owner       = "devops-team"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
az_count            = 2

# ECS Configuration
ecs_task_cpu        = "256"
ecs_task_memory     = "512"
ecs_desired_count   = 2
ecs_min_capacity    = 2
ecs_max_capacity    = 10

# Container Configuration
container_name  = "app"
container_image = "<account-id>.dkr.ecr.us-west-2.amazonaws.com/myapp:latest"
container_port  = 3000

# Optional: Domain Configuration
domain_name = "dev.example.com"  # Leave empty if not using Route53

# Cost Center Tags
cost_center = "engineering"
```

### 4. Optional Variables

Configure additional features:

```hcl
# Auto Scaling
enable_autoscaling           = true
autoscaling_cpu_target       = 70
autoscaling_memory_target    = 80

# Monitoring
enable_monitoring            = true
alarm_email_endpoints        = ["devops@example.com"]

# NAT Gateway
single_nat_gateway          = true  # Set false for HA (more expensive)

# Logging
log_retention_days          = 7  # Reduce for dev to save costs
```

## Backend Setup

### 1. Create S3 Bucket for State

```bash
# Set variables
REGION="us-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="terraform-state-${ACCOUNT_ID}-${REGION}"

# Create bucket
aws s3api create-bucket \
  --bucket ${BUCKET_NAME} \
  --region ${REGION} \
  --create-bucket-configuration LocationConstraint=${REGION}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### 2. Create DynamoDB Table for Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${REGION}
```

### 3. Update Backend Configuration

Edit `backend-config/dev.hcl`:

```hcl
bucket         = "terraform-state-<account-id>-us-west-2"
key            = "dev/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-state-lock"
encrypt        = true
```

## Development Deployment

### 1. Initialize Terraform

```bash
terraform init -backend-config=backend-config/dev.hcl
```

Expected output:
```
Terraform has been successfully initialized!
```

### 2. Validate Configuration

```bash
terraform validate
```

Should return: `Success! The configuration is valid.`

### 3. Format Code

```bash
terraform fmt -recursive
```

### 4. Plan Deployment

```bash
terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan-dev
```

Review the plan carefully:
- Check resource counts
- Verify network configuration
- Review estimated costs

### 5. Apply Configuration

```bash
terraform apply tfplan-dev
```

Type `yes` when prompted.

Deployment time: ~10-15 minutes

### 6. Save Outputs

```bash
terraform output > outputs.txt
```

Important outputs:
- `alb_dns_name` - Load balancer endpoint
- `ecs_cluster_name` - Cluster name
- `vpc_id` - VPC ID

## Production Deployment

Production deployment requires additional approval and checks.

### 1. Review Changes

```bash
# Compare with dev
terraform plan -var-file=environments/prod/terraform.tfvars
```

### 2. Production Checklist

Before deploying to production:

- [ ] All tests pass in dev environment
- [ ] Security scan completed (tfsec, checkov)
- [ ] Cost estimation reviewed
- [ ] Backup strategy documented
- [ ] Monitoring and alerts configured
- [ ] Disaster recovery plan documented
- [ ] Change request approved
- [ ] Deployment window scheduled
- [ ] Rollback plan prepared
- [ ] Stakeholders notified

### 3. Deploy to Production

```bash
# Initialize with prod backend
terraform init -backend-config=backend-config/prod.hcl

# Plan
terraform plan -var-file=environments/prod/terraform.tfvars -out=tfplan-prod

# Apply (requires approval)
terraform apply tfplan-prod
```

### 4. Post-Deployment Verification

Run health checks:

```bash
./scripts/health-check.sh <alb-dns-name>
```

## Verification

### 1. Check ECS Service

```bash
# Get cluster name
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)

# List services
aws ecs list-services --cluster ${CLUSTER_NAME}

# Describe service
aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services myapp-dev \
  --query 'services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount}'
```

### 2. Test Load Balancer

```bash
# Get ALB DNS
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health endpoint
curl http://${ALB_DNS}/health

# Expected response: {"status":"healthy",...}
```

### 3. Check Logs

```bash
# View task logs
aws logs tail /ecs/myapp-dev --follow

# Or use AWS Console → CloudWatch → Log Groups
```

### 4. Verify Auto Scaling

```bash
# Describe auto scaling target
aws application-autoscaling describe-scalable-targets \
  --service-namespace ecs \
  --resource-ids service/${CLUSTER_NAME}/myapp-dev
```

### 5. Monitor Metrics

Access CloudWatch Console:
```bash
# Open CloudWatch dashboard
aws cloudwatch list-dashboards

# Or use the AWS Console
```

## Updating the Deployment

### Making Changes

1. **Update Configuration**:
   ```bash
   vim environments/dev/terraform.tfvars
   ```

2. **Plan Changes**:
   ```bash
   terraform plan -var-file=environments/dev/terraform.tfvars
   ```

3. **Apply Changes**:
   ```bash
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

### Rolling Updates

To update container image:

```bash
# Update container_image variable in terraform.tfvars
container_image = "<account-id>.dkr.ecr.us-west-2.amazonaws.com/myapp:v2.0.0"

# Apply changes
terraform apply -var-file=environments/dev/terraform.tfvars
```

ECS will perform a rolling update:
- Start new tasks with new image
- Wait for health checks to pass
- Drain and stop old tasks

## Destroying Infrastructure

### Development Environment

```bash
# Plan destruction
terraform plan -destroy -var-file=environments/dev/terraform.tfvars

# Destroy (requires confirmation)
terraform destroy -var-file=environments/dev/terraform.tfvars
```

### Production Environment

⚠️ **WARNING**: This will delete all production infrastructure!

```bash
# Requires manual approval
terraform destroy -var-file=environments/prod/terraform.tfvars
```

## Troubleshooting

### Common Issues

#### Issue: Terraform Init Fails

**Error**: `Error configuring the backend "s3"`

**Solution**:
```bash
# Verify S3 bucket exists
aws s3 ls s3://terraform-state-<account-id>-us-west-2

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock

# Check AWS credentials
aws sts get-caller-identity
```

#### Issue: Tasks Not Starting

**Error**: Tasks stuck in PENDING state

**Solution**:
```bash
# Check stopped tasks
aws ecs list-tasks --cluster ${CLUSTER_NAME} --desired-status STOPPED

# Describe stopped task
aws ecs describe-tasks --cluster ${CLUSTER_NAME} --tasks <task-id>

# Common causes:
# - Insufficient memory/CPU
# - Image pull errors (check ECR permissions)
# - Invalid task definition
# - Security group issues
```

#### Issue: Health Check Failures

**Error**: Targets marked unhealthy

**Solution**:
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Verify application health endpoint
curl http://<task-ip>:3000/health

# Check task logs
aws logs tail /ecs/myapp-dev --follow

# Adjust health check settings if needed:
# - Increase timeout
# - Increase interval
# - Adjust healthy threshold
```

#### Issue: Permission Denied Errors

**Error**: `AccessDenied` when applying Terraform

**Solution**:
```bash
# Verify IAM permissions
aws iam get-user

# Attach required policies:
# - AmazonEC2FullAccess
# - AmazonECS_FullAccess
# - ElasticLoadBalancingFullAccess
# - CloudWatchFullAccess
# - IAMFullAccess (or specific policies)
```

### Getting Help

- **AWS Support**: For AWS-specific issues
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **GitHub Issues**: Report bugs or request features
- **Team Slack**: #devops-support channel

## Next Steps

After successful deployment:

1. **Configure Monitoring**: Set up CloudWatch dashboards and alarms
2. **Set Up CI/CD**: Integrate with GitHub Actions for automated deployments
3. **Document Runbooks**: Create operational procedures
4. **Schedule Backups**: Implement backup strategy
5. **Cost Optimization**: Review and optimize costs
6. **Security Hardening**: Enable additional security features
7. **Load Testing**: Test application under load
8. **Disaster Recovery**: Test DR procedures

## Additional Resources

- [Architecture Documentation](./ARCHITECTURE.md)
- [Security Best Practices](../SECURITY.md)
- [Contributing Guidelines](../CONTRIBUTING.md)
- [Cost Optimization Guide](./COST_OPTIMIZATION.md)
