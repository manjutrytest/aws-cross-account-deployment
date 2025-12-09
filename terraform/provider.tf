terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "bom-terraform-state-047861165149"
    key            = "cross-account/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.target_region
  
  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/TerraformCloudFormationRole"
  }
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      SourceAccount = var.source_account_id
    }
  }
}
