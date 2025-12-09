# Deployment Troubleshooting

## Issue: CodeBuild Quota Exceeded

**Error Message:**
```
Error calling startBuild: Cannot have more than 0 builds in queue for the account
Service: AWSCodeBuild
Status Code: 400
Error Code: AccountLimitExceededException
```

**Root Cause:**
Your AWS account has a CodeBuild concurrent build limit of 0, which prevents any CodeBuild projects from running.

## Solutions

### Solution 1: Request Quota Increase (Recommended)

1. **Open AWS Service Quotas Console:**
   ```
   https://eu-north-1.console.aws.amazon.com/servicequotas/home/services/codebuild/quotas
   ```

2. **Find and increase these quotas:**
   - "Concurrent running builds for Linux/Small environment" - Request increase to at least 1
   - "Concurrent running builds" - Request increase to at least 1

3. **Submit the request:**
   - Click on the quota
   - Click "Request quota increase"
   - Enter desired value (minimum 1, recommended 5)
   - Submit request

4. **Wait for approval** (usually 24-48 hours)

5. **Retry pipeline** after approval:
   ```powershell
   aws codepipeline start-pipeline-execution --name terraform-deployment-pipeline --region eu-north-1
   ```

### Solution 2: Deploy Directly with Terraform (Immediate)

Since CodeBuild is not available, deploy the infrastructure directly using Terraform:

#### Step 1: Configure Target Account Credentials

```powershell
# Set target account credentials as environment variables
$env:AWS_ACCESS_KEY_ID="<TARGET_ACCOUNT_ACCESS_KEY>"
$env:AWS_SECRET_ACCESS_KEY="<TARGET_ACCOUNT_SECRET_KEY>"
$env:AWS_SESSION_TOKEN="<TARGET_ACCOUNT_SESSION_TOKEN>"  # If using temporary credentials
```

#### Step 2: Initialize and Deploy

```powershell
cd terraform
terraform init
terraform plan
terraform apply
```

This will deploy directly to the target account without using CodePipeline.

### Solution 3: Use Different AWS Region

Some regions may have different quota limits. Try deploying the pipeline in a different region:

1. Update `pipeline/pipeline.tf` to use a different region (e.g., us-east-1)
2. Redeploy the pipeline
3. Update `terraform/variables.tf` to match the new region

### Solution 4: Use AWS CloudFormation Instead

Deploy using CloudFormation directly without CodeBuild:

```powershell
# Convert Terraform to CloudFormation or use the provided CloudFormation template
aws cloudformation create-stack --stack-name cross-account-infra --template-body file://iam/cloudformation-iam-role.yaml --region eu-north-1
```

## Verification Steps

### Check Current Quotas

```powershell
aws service-quotas list-service-quotas --service-code codebuild --region eu-north-1 --query 'Quotas[?contains(QuotaName, `build`)].[QuotaName,Value]' --output table
```

### Check CodeBuild Projects

```powershell
aws codebuild list-projects --region eu-north-1
```

### Check Pipeline Status

```powershell
aws codepipeline get-pipeline-state --name terraform-deployment-pipeline --region eu-north-1
```

## Alternative: Manual Deployment Steps

If you cannot use CodeBuild, follow these manual steps:

### 1. Set up credentials for target account

```powershell
# Configure AWS CLI with target account credentials
aws configure --profile target-account
```

### 2. Deploy infrastructure

```powershell
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the changes
terraform apply -auto-approve
```

### 3. Verify deployment

```powershell
# Check EC2 instances
aws ec2 describe-instances --region eu-north-1 --profile target-account

# Check VPC
aws ec2 describe-vpcs --region eu-north-1 --profile target-account

# Get outputs
terraform output
```

## Expected Resources After Deployment

- **VPC**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24 (public)
- **EC2 Instance**: t3.medium Windows Server
- **EBS Volume**: 40 GB gp3
- **Elastic IP**: Public IP for EC2
- **Security Group**: Allows RDP (port 3389)
- **Internet Gateway**: For internet access

## Cost Estimate

**Monthly**: ~$143.29 USD
- EC2 t3.medium: $139.53
- VPC & Networking: $3.65
- EBS 40GB: Included

## Support

If you continue to face issues:

1. **Check AWS Support Center** for quota increase status
2. **Contact AWS Support** if quota increase is urgent
3. **Use alternative deployment method** (direct Terraform) in the meantime

## Next Steps

Choose one of the solutions above based on your requirements:
- **Need automation?** → Request quota increase (Solution 1)
- **Need immediate deployment?** → Use direct Terraform (Solution 2)
- **Have flexibility?** → Try different region (Solution 3)
