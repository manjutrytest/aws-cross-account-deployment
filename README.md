# Cross-Account Infrastructure Deployment

## Overview
This project deploys infrastructure from a source AWS account to a target account using Terraform and CodePipeline.

## Architecture
- **Source Account**: 047861165149
- **Target Account**: 821706771879
- **Target Region**: eu-north-1

## Components
- EC2 instance (t3.medium, Windows Server, 40GB EBS)
- VPC with public IPv4 address
- CodePipeline for automated deployment
- CloudFormation stack for tracking

## Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform installed (v1.0+)
3. Cross-account IAM roles configured
4. S3 bucket for Terraform state and pipeline artifacts

## Deployment Steps
1. Set up cross-account roles (see `iam/` directory)
2. Deploy pipeline infrastructure: `cd pipeline && terraform init && terraform apply`
3. Push code to trigger pipeline
4. Monitor deployment in CodePipeline console

## Directory Structure
- `terraform/` - Infrastructure as Code
- `pipeline/` - CodePipeline configuration
- `iam/` - Cross-account IAM roles
- `buildspec.yml` - CodeBuild specification
