# Variables for Security Module

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to access ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecs_ingress_ports" {
  description = "Ports allowed for ECS tasks"
  type        = list(number)
  default     = [80, 443]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}