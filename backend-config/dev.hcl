# Backend configuration for development environment
bucket         = "myapp-terraform-state-dev"
key            = "dev/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "myapp-terraform-locks-dev"
encrypt        = true