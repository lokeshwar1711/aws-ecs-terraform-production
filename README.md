# AWS ECS Infrastructure with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-ECS-FF9900?logo=amazon-aws)](https://aws.amazon.com/ecs/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A scalable AWS ECS infrastructure built with Terraform. This project started as a learning exercise but evolved into production-ready infrastructure.

## Architecture

This infrastructure deploys containerized applications on AWS ECS with:

- **ECS Fargate Cluster** - Container orchestration
- **Application Load Balancer** - Traffic distribution and health checks  
- **Auto Scaling** - CPU and memory based scaling
- **VPC & Networking** - Multi-AZ with public/private subnets
- **Security Groups** - Network access control
- **CloudWatch** - Logging and monitoring
- **IAM Roles** - Proper permissions
- **Route53** - DNS management (optional)
- **ACM** - SSL/TLS certificates
- **S3 & DynamoDB** - Terraform state management

## Getting Started

### Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- Docker (optional, for sample app)

### Basic Setup

1. **Clone and setup**
   ```bash
   git clone <repository-url>
   cd aws-ecs-terraform-production
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Configure variables**
   ```bash
   # Edit terraform.tfvars with your specific values
   vim terraform.tfvars
   ```

3. **Initialize and deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 📁 Project Structure

```
├── modules/
│   ├── networking/          # VPC, subnets, security groups
│   ├── ecs/                # ECS cluster, service, task definitions
│   ├── load-balancer/      # ALB, target groups, listeners
│   ├── auto-scaling/       # Auto scaling policies and CloudWatch alarms
│   ├── monitoring/         # CloudWatch dashboards and alerts
│   └── security/           # IAM roles, policies, security groups
├── environments/
│   ├── dev/                # Development environment
│   ├── staging/            # Staging environment
│   └── prod/               # Production environment
├── scripts/
│   ├── deploy.sh           # Deployment automation
│   ├── destroy.sh          # Infrastructure cleanup
│   └── health-check.sh     # Application health verification
├── .github/workflows/      # CI/CD pipelines
├── docs/                   # Additional documentation
└── examples/               # Usage examples
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Deployment environment | `dev` | Yes |
| `app_name` | Application name | `myapp` | Yes |
| `aws_region` | AWS region | `us-west-2` | Yes |
| `domain_name` | Custom domain | `""` | No |
| `enable_monitoring` | Enable CloudWatch monitoring | `true` | No |

### Scaling Configuration

The infrastructure supports both manual and automatic scaling:

- **CPU-based scaling**: Scales when CPU > 70%
- **Memory-based scaling**: Scales when memory > 80%
- **Custom metrics**: Configurable CloudWatch alarms

## 🔒 Security Features

- **Network isolation** with private subnets
- **WAF integration** for application protection
- **Secrets management** with AWS Secrets Manager
- **Encryption at rest** for all storage
- **VPC Flow Logs** for network monitoring
- **IAM least privilege** access patterns

## 📊 Monitoring & Observability

- **CloudWatch Dashboards** for real-time metrics
- **Custom alarms** for proactive monitoring
- **Log aggregation** with structured logging
- **Performance insights** and cost optimization
- **Health checks** at multiple levels

## 🚀 CI/CD Integration

Includes GitHub Actions workflows for:

- **Terraform validation** and security scanning
- **Multi-environment deployments**
- **Automated testing** and rollback capabilities
- **Cost estimation** and compliance checks

## 💰 Cost Optimization

- **Fargate Spot** integration for cost savings
- **Resource tagging** for cost allocation
- **Automated scaling** to minimize idle resources
- **Reserved capacity** recommendations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📧 Email: support@yourcompany.com
- 💬 Slack: #infrastructure-support
- 📖 Wiki: [Internal Documentation](docs/)

## 🏆 Acknowledgments

- AWS Well-Architected Framework
- Terraform AWS Provider Team
- HashiCorp Best Practices Guide

---

**Built with ❤️ for scalable cloud infrastructure**
