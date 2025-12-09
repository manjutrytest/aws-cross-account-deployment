# Deploy this in TARGET account (047861165149)
# This role allows the source account to deploy resources

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "source_account_id" {
  description = "Source AWS account ID"
  type        = string
  default     = "821706771879"
}

variable "target_account_id" {
  description = "Target AWS account ID"
  type        = string
  default     = "047861165149"
}

# Role for Terraform to assume in target account
resource "aws_iam_role" "terraform_deployment" {
  name = "TerraformDeploymentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "terraform-deployment"
          }
        }
      }
    ]
  })

  tags = {
    Name = "TerraformDeploymentRole"
  }
}

resource "aws_iam_role_policy" "terraform_deployment" {
  name = "TerraformDeploymentPolicy"
  role = aws_iam_role.terraform_deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "vpc:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "iam:*",
          "cloudformation:*"
        ]
        Resource = "*"
      }
    ]
  })
}

output "terraform_role_arn" {
  description = "ARN of the Terraform deployment role"
  value       = aws_iam_role.terraform_deployment.arn
}
