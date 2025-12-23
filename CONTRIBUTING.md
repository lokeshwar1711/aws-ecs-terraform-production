# Contributing to AWS ECS Terraform Infrastructure

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Pre-commit hooks installed (`pre-commit install`)
- Docker (for local testing)
- Go >= 1.19 (for testing with Terratest)

### Setting Up Development Environment

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/aws-ecs-terraform-production.git
   cd aws-ecs-terraform-production
   ```

3. Install pre-commit hooks:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

4. Create a branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Making Changes

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/add-new-monitoring
   ```

2. **Make your changes** following the coding standards

3. **Test locally**:
   ```bash
   terraform fmt -recursive
   terraform validate
   terraform plan
   ```

4. **Run pre-commit checks**:
   ```bash
   pre-commit run --all-files
   ```

5. **Commit your changes** with descriptive messages:
   ```bash
   git commit -m "feat: add CloudWatch dashboard for ECS metrics"
   ```

### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - A new feature
- `fix:` - A bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements
- `ci:` - CI/CD changes

Examples:
```
feat: add auto-scaling module for ECS service
fix: correct IAM policy for task execution role
docs: update README with new deployment instructions
refactor: simplify networking module structure
test: add integration tests for load balancer module
```

## Coding Standards

### Terraform Standards

1. **Formatting**: Always run `terraform fmt -recursive` before committing

2. **Naming Conventions**:
   - Use snake_case for resource names, variables, and outputs
   - Resource names should be descriptive: `aws_ecs_cluster.main` not `aws_ecs_cluster.c`
   - Prefix resources with module name in tags

3. **Module Structure**:
   ```
   module/
   ├── main.tf          # Main resources
   ├── variables.tf     # Input variables
   ├── outputs.tf       # Output values
   ├── versions.tf      # Provider version constraints
   └── README.md        # Module documentation
   ```

4. **Variables**:
   - Always provide descriptions
   - Use validation blocks when appropriate
   - Set sensible defaults where possible
   - Group related variables

   ```hcl
   variable "cluster_name" {
     description = "Name of the ECS cluster"
     type        = string
     
     validation {
       condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
       error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens"
     }
   }
   ```

5. **Outputs**:
   - Provide clear descriptions
   - Export all values that might be useful for other modules
   - Sensitive outputs should be marked as sensitive

   ```hcl
   output "cluster_id" {
     description = "ID of the ECS cluster"
     value       = aws_ecs_cluster.main.id
   }
   ```

6. **Resource Tagging**:
   - All resources must be tagged
   - Use the common tags pattern
   - Include: Name, Environment, Project, ManagedBy

7. **Documentation**:
   - Each module must have a README.md
   - Document all variables and outputs
   - Include usage examples
   - Explain architectural decisions

### HCL Best Practices

1. **Use locals for computed values**:
   ```hcl
   locals {
     name_prefix = "${var.project}-${var.environment}"
     common_tags = merge(var.tags, {
       Environment = var.environment
       ManagedBy   = "terraform"
     })
   }
   ```

2. **Use data sources for existing resources**:
   ```hcl
   data "aws_caller_identity" "current" {}
   data "aws_region" "current" {}
   ```

3. **Avoid hardcoded values**:
   - Use variables or data sources
   - Use locals for complex expressions

4. **Use dynamic blocks sparingly**:
   - Only when the configuration is truly dynamic
   - Prefer explicit blocks when possible

5. **Module versioning**:
   - Pin module versions in production
   - Use version constraints

## Testing

### Local Testing

1. **Format check**:
   ```bash
   terraform fmt -check -recursive
   ```

2. **Validation**:
   ```bash
   terraform validate
   ```

3. **Plan review**:
   ```bash
   terraform plan -out=tfplan
   ```

4. **Security scanning**:
   ```bash
   tfsec .
   checkov -d .
   ```

### Integration Testing

We use Terratest for integration testing:

```bash
cd tests/
go test -v -timeout 30m
```

### Testing Checklist

Before submitting a PR, ensure:

- [ ] Code is formatted (`terraform fmt`)
- [ ] Validation passes (`terraform validate`)
- [ ] No security issues (tfsec/checkov)
- [ ] Documentation is updated
- [ ] Tests pass (if applicable)
- [ ] Examples work
- [ ] CHANGELOG.md is updated

## Pull Request Process

1. **Update documentation**:
   - Update README.md if adding features
   - Update CHANGELOG.md with your changes
   - Update module READMEs if modifying modules

2. **Ensure quality**:
   - All tests pass
   - No linting errors
   - Code is properly formatted

3. **Create Pull Request**:
   - Use a descriptive title
   - Reference related issues
   - Provide context and motivation
   - Include screenshots/outputs if relevant

4. **PR Template**:
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] Terraform fmt
   - [ ] Terraform validate
   - [ ] Security scan
   - [ ] Manual testing
   
   ## Checklist
   - [ ] Documentation updated
   - [ ] CHANGELOG.md updated
   - [ ] Tests added/updated
   ```

5. **Review Process**:
   - Maintain professional and respectful communication
   - Be open to feedback and suggestions
   - Make requested changes promptly
   - Squash commits before merging (if requested)

## Module Development

When creating a new module:

1. Create proper directory structure
2. Write comprehensive README.md
3. Include examples/ directory with working examples
4. Add validation for inputs
5. Document all outputs
6. Write tests
7. Follow existing patterns

## Documentation

- Use clear, concise language
- Include code examples
- Explain the "why" not just the "what"
- Keep documentation up to date
- Use diagrams where helpful

## Questions?

If you have questions:
- Check existing issues and discussions
- Review the documentation
- Create a new issue with the `question` label

Thank you for contributing! 🎉
