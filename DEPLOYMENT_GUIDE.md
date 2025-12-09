# Cross-Account Deployment Guide

## Prerequisites

1. AWS CLI configured with credentials for both accounts
2. Terraform v1.0+ installed
3. Appropriate IAM permissions in both accounts

## Step-by-Step Deployment

### Step 1: Set Up Cross-Account IAM Roles (Target Account)

First, deploy the IAM roles in the **target account (821706771879)**:

```bash
cd iam
terraform init
terraform plan
terraform apply
```

This creates the `TerraformDeploymentRole` that allows the source account to deploy resources.

**Important**: Note the role ARN from the output - you'll need it.

### Step 2: Deploy Pipeline Infrastructure (Source Account)

Deploy the CodePipeline infrastructure in the **source account (047861165149)**:

```bash
cd pipeline
terraform init

# Update variables if needed
terraform plan -var="github_repo=your-org/your-repo"
terraform apply
```

This creates:
- S3 buckets for artifacts and Terraform state
- DynamoDB table for state locking
- CodeBuild project
- CodePipeline with GitHub integration

### Step 3: Connect GitHub

After the pipeline is created:

1. Go to AWS Console → Developer Tools → Connections
2. Find the "github-connection" 
3. Click "Update pending connection"
4. Authorize AWS to access your GitHub repository

### Step 4: Push Code to GitHub

Push this entire repository to your GitHub repo:

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/your-org/your-repo.git
git push -u origin main
```

### Step 5: Monitor Pipeline Execution

1. Go to AWS Console → CodePipeline
2. Find "terraform-deployment-pipeline"
3. Watch the pipeline execute:
   - **Source**: Pulls code from GitHub
   - **Plan**: Runs `terraform plan`
   - **Approve**: Manual approval required
   - **Deploy**: Runs `terraform apply`

### Step 6: Approve Deployment

When the pipeline reaches the "Approve" stage:

1. Review the Terraform plan in CodeBuild logs
2. Click "Review" in the pipeline
3. Approve or reject the deployment

### Step 7: Verify Deployment

After successful deployment:

```bash
# Check CloudFormation stacks in target account
aws cloudformation list-stacks --region eu-north-1 --profile target-account

# Get outputs
cd terraform
terraform output
```

## CloudFormation Integration

Terraform automatically creates CloudFormation stacks for tracking. View them in:
- AWS Console → CloudFormation → Stacks
- Look for stacks prefixed with your project name

## Reusability

To deploy to additional accounts or regions:

1. Update `terraform/variables.tf` with new values
2. Create new IAM roles in the new target account
3. Update pipeline configuration
4. Push changes to trigger deployment

## Troubleshooting

### Pipeline Fails at Plan Stage
- Check CodeBuild logs for Terraform errors
- Verify cross-account role permissions
- Ensure S3 backend is accessible

### Cannot Assume Role
- Verify the role exists in target account
- Check trust relationship allows source account
- Confirm external ID matches

### GitHub Connection Pending
- Complete the connection authorization in AWS Console
- Ensure GitHub app has repository access

## Cost Estimate

Based on your BOM:
- **EC2 t3.medium**: ~$139.53/month
- **VPC & Networking**: ~$3.65/month
- **EBS 40GB**: Included in EC2 cost
- **Total**: ~$143.29/month

## Security Best Practices

1. Use least-privilege IAM policies
2. Enable MFA for manual approvals
3. Encrypt S3 buckets and EBS volumes
4. Regularly rotate credentials
5. Enable CloudTrail for audit logging
6. Use VPC endpoints to avoid internet traffic

## Cleanup

To destroy all resources:

```bash
# In source account
cd pipeline
terraform destroy

# In target account (via pipeline or manually)
cd terraform
terraform destroy

# In target account
cd iam
terraform destroy
```
