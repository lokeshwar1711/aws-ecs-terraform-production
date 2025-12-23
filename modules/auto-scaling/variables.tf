# Variables for Auto Scaling Module

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

# CPU Scaling Configuration
variable "cpu_target_value" {
  description = "Target CPU utilization for scaling"
  type        = number
  default     = 70.0
}

variable "cpu_scale_in_cooldown" {
  description = "Cooldown period for CPU scale in (seconds)"
  type        = number
  default     = 300
}

variable "cpu_scale_out_cooldown" {
  description = "Cooldown period for CPU scale out (seconds)"
  type        = number
  default     = 300
}

variable "cpu_high_threshold" {
  description = "CPU threshold for high utilization alarm"
  type        = number
  default     = 80.0
}

# Memory Scaling Configuration
variable "memory_target_value" {
  description = "Target memory utilization for scaling"
  type        = number
  default     = 80.0
}

variable "memory_scale_in_cooldown" {
  description = "Cooldown period for memory scale in (seconds)"
  type        = number
  default     = 300
}

variable "memory_scale_out_cooldown" {
  description = "Cooldown period for memory scale out (seconds)"
  type        = number
  default     = 300
}

variable "memory_high_threshold" {
  description = "Memory threshold for high utilization alarm"
  type        = number
  default     = 85.0
}

# Request Count Scaling Configuration
variable "enable_request_count_scaling" {
  description = "Enable request count based scaling"
  type        = bool
  default     = false
}

variable "alb_resource_label" {
  description = "ALB resource label for request count scaling"
  type        = string
  default     = ""
}

variable "request_count_target_value" {
  description = "Target request count per target for scaling"
  type        = number
  default     = 1000
}

variable "request_count_scale_in_cooldown" {
  description = "Cooldown period for request count scale in (seconds)"
  type        = number
  default     = 300
}

variable "request_count_scale_out_cooldown" {
  description = "Cooldown period for request count scale out (seconds)"
  type        = number
  default     = 300
}

# Scheduled Scaling Configuration
variable "enable_scheduled_scaling" {
  description = "Enable scheduled scaling"
  type        = bool
  default     = false
}

variable "scale_up_cron" {
  description = "Cron expression for scaling up"
  type        = string
  default     = "cron(0 8 * * MON-FRI)"
}

variable "scale_down_cron" {
  description = "Cron expression for scaling down"
  type        = string
  default     = "cron(0 18 * * MON-FRI)"
}

variable "timezone" {
  description = "Timezone for scheduled scaling"
  type        = string
  default     = "UTC"
}

variable "scheduled_min_capacity" {
  description = "Minimum capacity during business hours"
  type        = number
  default     = 2
}

variable "scheduled_max_capacity" {
  description = "Maximum capacity during business hours"
  type        = number
  default     = 20
}

# Notification Configuration
variable "sns_topic_arn" {
  description = "SNS topic ARN for scaling alerts"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}