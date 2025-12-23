# Backend configuration for production environment
bucket         = "myapp-terraform-state-prod"
key            = "prod/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "myapp-terraform-locks-prod"
encrypt        = true