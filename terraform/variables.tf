variable "target_account_id" {
  description = "Target AWS account ID"
  type        = string
  default     = "047861165149"
}

variable "target_region" {
  description = "Target AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "source_account_id" {
  description = "Source AWS account ID"
  type        = string
  default     = "821706771879"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 40
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cross-account-infra"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
