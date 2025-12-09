# Quick Deployment Guide

## Current Status
✅ Authenticated as source account: 047861165149
✅ Terraform installed: v1.13.4
✅ AWS CLI installed: v2.32.10

## Deployment Steps

### Step 1: Configure Target Account Access

You need credentials for the target account (821706771879). Choose one option:

**Option A: Configure AWS CLI Profile**
```powershell
aws configure --profile target-account
# Enter target account credentials when prompted
```

**Option B: Use AWS SSO**
```powershell
aws configure sso --profile target-account
```

**Option C: Manual IAM Role Deployment**
If you have console access to target account:
1. Log into AWS Console for account 821706771879
2. Go to CloudFormation
3. Create stack with template: `iam/cloudformation-iam-role.yaml` (I'll create this)
4. This creates the cross-account role

### Step 2: Deploy IAM Roles (Target Account)

```powershell
cd iam
terraform init
terraform apply
cd ..
```

### Step 3: Deploy Pipeline (Source Account)

```powershell
cd pipeline
terraform init

# Update with your GitHub repo
terraform apply -var="github_repo=your-org/your-repo"
cd ..
```

### Step 4: Connect GitHub

1. Go to AWS Console → Developer Tools → Connections
2. Find "github-connection"
3. Click "Update pending connection"
4. Authorize AWS to access your GitHub

### Step 5: Initialize Git and Push

```powershell
git init
git add .
git commit -m "Initial infrastructure setup"
git remote add origin https://github.com/your-org/your-repo.git
git push -u origin main
```

### Step 6: Monitor Pipeline

1. Go to AWS Console → CodePipeline
2. Find "terraform-deployment-pipeline"
3. Watch it execute and approve when ready

## Alternative: Deploy Without Pipeline

If you want to deploy directly without CodePipeline:

```powershell
cd terraform
terraform init
terraform apply
```

This requires you to have assumed the cross-account role first.
