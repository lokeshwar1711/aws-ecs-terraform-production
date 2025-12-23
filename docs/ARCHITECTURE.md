# AWS ECS Terraform Architecture

## Overview

This document provides a comprehensive overview of the AWS ECS infrastructure architecture deployed using Terraform.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud (Region: us-west-2)                  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                              VPC (10.0.0.0/16)                         │ │
│  │                                                                         │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │  Availability Zone A          │          Availability Zone B      │ │ │
│  │  │                               │                                   │ │ │
│  │  │  ┌─────────────────────┐     │     ┌─────────────────────┐      │ │ │
│  │  │  │   Public Subnet     │     │     │   Public Subnet     │      │ │ │
│  │  │  │   10.0.1.0/24       │     │     │   10.0.2.0/24       │      │ │ │
│  │  │  │                     │     │     │                     │      │ │ │
│  │  │  │  ┌───────────────┐  │     │     │  ┌───────────────┐  │      │ │ │
│  │  │  │  │  NAT Gateway  │  │     │     │  │  NAT Gateway  │  │      │ │ │
│  │  │  │  └───────────────┘  │     │     │  └───────────────┘  │      │ │ │
│  │  │  └──────────┬──────────┘     │     └──────────┬──────────┘      │ │ │
│  │  │             │                 │                │                  │ │ │
│  │  │  ┌──────────▼──────────┐     │     ┌──────────▼──────────┐      │ │ │
│  │  │  │  Private Subnet     │     │     │  Private Subnet     │      │ │ │
│  │  │  │  10.0.11.0/24       │     │     │  10.0.12.0/24       │      │ │ │
│  │  │  │                     │     │     │                     │      │ │ │
│  │  │  │  ┌──────────────┐   │     │     │  ┌──────────────┐   │      │ │ │
│  │  │  │  │  ECS Task    │   │     │     │  │  ECS Task    │   │      │ │ │
│  │  │  │  │  Container   │   │     │     │  │  Container   │   │      │ │ │
│  │  │  │  └──────────────┘   │     │     │  └──────────────┘   │      │ │ │
│  │  │  │                     │     │     │                     │      │ │ │
│  │  │  └─────────────────────┘     │     └─────────────────────┘      │ │ │
│  │  └──────────────────────────────┴──────────────────────────────────┘ │ │
│  │                                                                         │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Application Load Balancer                       │ │ │
│  │  │               (Internet-facing, Port 80/443)                       │ │ │
│  │  └───────────────────────────────────────────────────────────────────┘ │ │
│  │                                 │                                       │ │
│  └─────────────────────────────────┼───────────────────────────────────────┘ │
│                                    │                                         │
│  ┌─────────────────────────────────▼───────────────────────────────────────┐ │
│  │                          Internet Gateway                                │ │
│  └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐   │
│  │   CloudWatch       │  │    ECS Cluster     │  │  Auto Scaling      │   │
│  │   Logs & Metrics   │  │    (Fargate)       │  │  Policies          │   │
│  └────────────────────┘  └────────────────────┘  └────────────────────┘   │
│                                                                              │
│  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐   │
│  │   Route53          │  │    ACM             │  │  Secrets Manager   │   │
│  │   DNS              │  │    SSL/TLS Cert    │  │  Secrets           │   │
│  └────────────────────┘  └────────────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

                                    │
                                    ▼
                              [ Internet ]
```

## Component Details

### 1. Network Layer

#### VPC (Virtual Private Cloud)
- **CIDR Block**: 10.0.0.0/16 (65,536 IP addresses)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled
- **Multi-AZ**: Deployed across 2+ Availability Zones

#### Public Subnets
- **Purpose**: Host internet-facing resources (ALB, NAT Gateway)
- **CIDR**: 10.0.1.0/24, 10.0.2.0/24
- **Auto-assign Public IP**: Enabled
- **Resources**: Application Load Balancer, NAT Gateway

#### Private Subnets
- **Purpose**: Host ECS tasks and internal resources
- **CIDR**: 10.0.11.0/24, 10.0.12.0/24
- **Internet Access**: Via NAT Gateway only
- **Resources**: ECS Tasks, RDS instances (if used)

#### Internet Gateway
- Provides internet connectivity for public subnets
- Attached to VPC
- Used by ALB for ingress/egress traffic

#### NAT Gateway
- Enables outbound internet access for private subnets
- One per AZ for high availability (configurable)
- Elastic IP assigned
- Used by ECS tasks for external API calls, package downloads

### 2. Compute Layer

#### ECS Cluster
- **Launch Type**: AWS Fargate (serverless)
- **Capacity Providers**: FARGATE, FARGATE_SPOT
- **Container Insights**: Enabled
- **Task Definition**: Defined with CPU/memory requirements

#### ECS Service
- **Desired Count**: Configurable (default: 2)
- **Launch Type**: Fargate
- **Network Mode**: awsvpc
- **Health Check Grace Period**: 60 seconds
- **Deployment**: Rolling updates with min/max healthy percentages

#### Task Definition
- **CPU**: 256-4096 vCPU units
- **Memory**: 512-30720 MB
- **Network Mode**: awsvpc (each task gets ENI)
- **Log Driver**: awslogs (CloudWatch Logs)

### 3. Load Balancing Layer

#### Application Load Balancer (ALB)
- **Scheme**: Internet-facing
- **Subnets**: Deployed in public subnets across AZs
- **Listeners**: 
  - HTTP (port 80) → HTTPS redirect
  - HTTPS (port 443) → Target Group
- **Security**: SSL/TLS termination at ALB
- **Health Checks**: Configured on target groups

#### Target Group
- **Type**: IP targets (required for Fargate)
- **Protocol**: HTTP
- **Port**: Configurable (default: 3000)
- **Health Check**:
  - Path: /health
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Healthy threshold: 2
  - Unhealthy threshold: 3

### 4. Security Layer

#### Security Groups

**ALB Security Group**:
```hcl
Ingress:
  - Port 80 (HTTP) from 0.0.0.0/0
  - Port 443 (HTTPS) from 0.0.0.0/0
Egress:
  - All traffic to ECS security group
```

**ECS Security Group**:
```hcl
Ingress:
  - Application port from ALB security group
Egress:
  - Port 443 to 0.0.0.0/0 (HTTPS)
  - Port 80 to 0.0.0.0/0 (HTTP)
```

#### IAM Roles

**ECS Task Execution Role**:
- Pull container images from ECR
- Write logs to CloudWatch
- Retrieve secrets from Secrets Manager
- Retrieve parameters from Parameter Store

**ECS Task Role**:
- Application-specific permissions
- Access to AWS services (S3, DynamoDB, etc.)
- Least privilege principle applied

### 5. Auto Scaling

#### Target Tracking Policies

**CPU-based Scaling**:
- Target: 70% CPU utilization
- Scale out when > 70%
- Scale in when < 50%
- Cooldown period: 300 seconds

**Memory-based Scaling**:
- Target: 80% memory utilization
- Scale out when > 80%
- Scale in when < 60%
- Cooldown period: 300 seconds

**Custom Metrics**:
- ALB request count per target
- Application-specific metrics

#### Scaling Limits
- **Min Capacity**: 2 tasks
- **Max Capacity**: 10 tasks (configurable)
- **Scale-out**: Add 1 task at a time
- **Scale-in**: Remove 1 task at a time

### 6. Monitoring & Logging

#### CloudWatch Logs
- **Log Groups**: Per ECS service
- **Retention**: 7-90 days (configurable)
- **Log Stream**: Per task
- **Format**: JSON structured logging

#### CloudWatch Metrics
- ECS cluster metrics
- Service metrics (CPU, memory, network)
- ALB metrics (request count, latency, errors)
- Custom application metrics

#### CloudWatch Alarms
- High CPU utilization (> 80%)
- High memory utilization (> 90%)
- ALB 5XX errors (> 10/min)
- Unhealthy target count (> 0)
- Task count below minimum

#### SNS Topics
- Critical alerts → PagerDuty
- Warning alerts → Slack
- Info alerts → Email

### 7. Data Persistence

#### S3 Buckets
- **Terraform State**: Encrypted, versioned
- **Application Logs**: Lifecycle policies applied
- **Backup Storage**: Intelligent-Tiering

#### DynamoDB
- **State Locking**: Terraform state lock table
- **On-demand Billing**: Cost-effective for low traffic

### 8. DNS & SSL/TLS

#### Route53
- **Hosted Zone**: Domain management
- **Record Sets**: 
  - A record (alias) → ALB
  - AAAA record (IPv6) → ALB
- **Health Checks**: ALB health monitoring

#### ACM (AWS Certificate Manager)
- **SSL/TLS Certificate**: Wildcard or specific domain
- **Validation**: DNS validation
- **Renewal**: Automatic
- **Protocols**: TLS 1.2, TLS 1.3

## Data Flow

### Incoming Request Flow

1. **Client Request** → Internet → AWS Edge Location (CloudFront optional)
2. **Route53** → Resolves domain to ALB IP
3. **Internet Gateway** → Routes traffic to VPC
4. **ALB** → Receives request, terminates SSL, performs health checks
5. **Target Group** → Routes to healthy ECS task
6. **ECS Task** → Processes request in private subnet
7. **Application** → Returns response
8. **ALB** → Returns response to client
9. **CloudWatch** → Logs captured throughout

### Outgoing Request Flow

1. **ECS Task** → Initiates outbound request (e.g., external API)
2. **Private Subnet** → Routes to NAT Gateway
3. **NAT Gateway** → Translates private IP to public IP
4. **Internet Gateway** → Routes traffic to internet
5. **External Service** → Receives request
6. **Response** → Returns via same path

## High Availability

### Multi-AZ Deployment
- Resources distributed across multiple AZs
- ALB routes traffic to healthy targets in any AZ
- ECS tasks spread across AZs using spread strategy

### Fault Tolerance
- **ALB**: Automatically fails over to healthy targets
- **NAT Gateway**: One per AZ (optional)
- **ECS Service**: Replaces failed tasks automatically
- **Auto Scaling**: Maintains desired capacity

### Disaster Recovery
- **RTO**: < 15 minutes (automated recovery)
- **RPO**: Near-zero for stateless applications
- **Backup**: Terraform state versioned in S3
- **Multi-Region**: Can be deployed to multiple regions

## Security Best Practices

1. **Network Isolation**: Private subnets for compute resources
2. **Least Privilege**: IAM roles with minimum permissions
3. **Encryption**: 
   - At rest: S3, EBS, RDS encryption enabled
   - In transit: TLS 1.2+ enforced
4. **Secrets Management**: AWS Secrets Manager for sensitive data
5. **Security Groups**: Restrictive ingress/egress rules
6. **VPC Flow Logs**: Network traffic monitoring
7. **CloudTrail**: API call auditing
8. **GuardDuty**: Threat detection enabled

## Cost Optimization

### Current Cost Drivers
1. **NAT Gateway**: $0.045/hour + data transfer
2. **ECS Fargate**: $0.04048/vCPU/hour + $0.004445/GB/hour
3. **ALB**: $0.0225/hour + $0.008/LCU
4. **Data Transfer**: $0.09/GB outbound

### Optimization Strategies
1. **Fargate Spot**: Use for non-critical workloads (70% savings)
2. **Single NAT**: Use one NAT for dev environment
3. **Reserved Capacity**: Commit to Savings Plans
4. **Right-sizing**: Monitor and adjust task resources
5. **Log Retention**: Reduce retention period
6. **S3 Lifecycle**: Archive old logs to Glacier

## Scalability

### Current Limits
- **ECS Service**: 2-10 tasks (configurable)
- **ALB**: Can handle 1000s of requests/second
- **VPC**: 65,536 IPs available
- **Fargate**: Regional limits apply (soft limits)

### Scaling Strategies
- **Horizontal**: Add more ECS tasks
- **Vertical**: Increase task CPU/memory
- **Auto Scaling**: Dynamic based on metrics
- **Caching**: Add CloudFront, ElastiCache
- **Database**: Read replicas, sharding

## Maintenance

### Regular Tasks
- **Weekly**: Review CloudWatch dashboards
- **Monthly**: Cost analysis and optimization
- **Quarterly**: Security audit and updates
- **Annually**: Disaster recovery testing

### Updates
- **Terraform**: Keep providers updated
- **Container Images**: Regular security patching
- **AWS Services**: Monitor deprecation notices
- **SSL Certificates**: Auto-renewed via ACM

## Troubleshooting

### Common Issues

**Tasks Not Starting**:
- Check task definition (CPU/memory)
- Verify IAM role permissions
- Review CloudWatch Logs
- Check security group rules

**High Latency**:
- Review ALB target health
- Check task resource utilization
- Analyze CloudWatch metrics
- Review application logs

**Auto Scaling Not Working**:
- Verify CloudWatch alarms
- Check IAM permissions
- Review scaling policies
- Monitor cooldown periods

## References

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
