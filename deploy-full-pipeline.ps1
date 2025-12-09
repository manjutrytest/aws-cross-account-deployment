# Full Pipeline Deployment Script
# Deploys cross-account infrastructure with CodePipeline

param(
    [Parameter(Mandatory=$true)]
    [string]$GithubRepo,
    
    [Parameter(Mandatory=$false)]
    [string]$GithubBranch = "main",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetProfile = "target-account"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Cross-Account Infrastructure Deployment Pipeline      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verify source account
Write-Host "Step 1: Verifying source account..." -ForegroundColor Yellow
$sourceAccount = aws sts get-caller-identity --query Account --output text
Write-Host "  ✓ Source Account: $sourceAccount" -ForegroundColor Green

if ($sourceAccount -ne "047861165149") {
    Write-Host "  ✗ ERROR: Expected source account 047861165149" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Verifying target account access..." -ForegroundColor Yellow

try {
    $targetAccount = aws sts get-caller-identity --profile $TargetProfile --query Account --output text 2>$null
    
    if ($targetAccount -eq "821706771879") {
        Write-Host "  ✓ Target Account: $targetAccount" -ForegroundColor Green
    } else {
        Write-Host "  ✗ ERROR: Expected target account 821706771879, got $targetAccount" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✗ ERROR: Cannot access target account" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please configure target account credentials first:" -ForegroundColor Yellow
    Write-Host "  Run: .\setup-target-account.ps1" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 1: Deploy IAM Roles in Target Account              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Set-Location iam

Write-Host "Initializing Terraform..." -ForegroundColor Yellow
$env:AWS_PROFILE = $TargetProfile
terraform init

Write-Host ""
Write-Host "Planning IAM role deployment..." -ForegroundColor Yellow
terraform plan -out=iam.tfplan

Write-Host ""
$confirm = Read-Host "Deploy IAM roles in target account? (yes/no)"

if ($confirm -eq "yes") {
    Write-Host "Applying IAM roles..." -ForegroundColor Yellow
    terraform apply iam.tfplan
    
    Write-Host ""
    Write-Host "  ✓ IAM roles deployed successfully!" -ForegroundColor Green
    
    # Get the role ARN
    $roleArn = terraform output -raw terraform_role_arn
    Write-Host "  Role ARN: $roleArn" -ForegroundColor Cyan
} else {
    Write-Host "  Deployment cancelled" -ForegroundColor Red
    Set-Location ..
    exit 0
}

Set-Location ..

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 2: Deploy Pipeline in Source Account                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Set-Location pipeline

Write-Host "Initializing Terraform..." -ForegroundColor Yellow
$env:AWS_PROFILE = "default"
terraform init

Write-Host ""
Write-Host "Planning pipeline deployment..." -ForegroundColor Yellow
Write-Host "  GitHub Repo: $GithubRepo" -ForegroundColor Cyan
Write-Host "  Branch: $GithubBranch" -ForegroundColor Cyan
Write-Host ""

terraform plan -var="github_repo=$GithubRepo" -var="github_branch=$GithubBranch" -out=pipeline.tfplan

Write-Host ""
$confirm = Read-Host "Deploy CodePipeline infrastructure? (yes/no)"

if ($confirm -eq "yes") {
    Write-Host "Applying pipeline infrastructure..." -ForegroundColor Yellow
    terraform apply pipeline.tfplan
    
    Write-Host ""
    Write-Host "  ✓ Pipeline deployed successfully!" -ForegroundColor Green
    
    $pipelineName = terraform output -raw pipeline_name
    $connectionArn = terraform output -raw github_connection_arn
    
    Write-Host ""
    Write-Host "Pipeline Name: $pipelineName" -ForegroundColor Cyan
    Write-Host "Connection ARN: $connectionArn" -ForegroundColor Cyan
} else {
    Write-Host "  Deployment cancelled" -ForegroundColor Red
    Set-Location ..
    exit 0
}

Set-Location ..

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 3: Post-Deployment Steps                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Connect GitHub:" -ForegroundColor White
Write-Host "   - Go to: https://console.aws.amazon.com/codesuite/settings/connections" -ForegroundColor Cyan
Write-Host "   - Find: github-connection" -ForegroundColor Cyan
Write-Host "   - Click: 'Update pending connection'" -ForegroundColor Cyan
Write-Host "   - Authorize AWS to access your GitHub repository" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. Initialize Git repository (if not already done):" -ForegroundColor White
Write-Host "   git init" -ForegroundColor Cyan
Write-Host "   git add ." -ForegroundColor Cyan
Write-Host "   git commit -m 'Initial infrastructure setup'" -ForegroundColor Cyan
Write-Host "   git remote add origin https://github.com/$GithubRepo.git" -ForegroundColor Cyan
Write-Host "   git push -u origin $GithubBranch" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Monitor pipeline execution:" -ForegroundColor White
Write-Host "   - Go to: https://console.aws.amazon.com/codesuite/codepipeline/pipelines" -ForegroundColor Cyan
Write-Host "   - Find: terraform-deployment-pipeline" -ForegroundColor Cyan
Write-Host "   - Watch the pipeline execute through stages:" -ForegroundColor Cyan
Write-Host "     • Source (pulls from GitHub)" -ForegroundColor Gray
Write-Host "     • Plan (runs terraform plan)" -ForegroundColor Gray
Write-Host "     • Approve (manual approval required)" -ForegroundColor Gray
Write-Host "     • Deploy (runs terraform apply)" -ForegroundColor Gray
Write-Host ""

Write-Host "4. When pipeline reaches 'Approve' stage:" -ForegroundColor White
Write-Host "   - Review the Terraform plan in CodeBuild logs" -ForegroundColor Cyan
Write-Host "   - Click 'Review' and approve the deployment" -ForegroundColor Cyan
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Deployment Script Complete!                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "Resources Created:" -ForegroundColor Yellow
Write-Host "  ✓ Cross-account IAM role in target account" -ForegroundColor Green
Write-Host "  ✓ S3 buckets for artifacts and Terraform state" -ForegroundColor Green
Write-Host "  ✓ DynamoDB table for state locking" -ForegroundColor Green
Write-Host "  ✓ CodeBuild project for Terraform execution" -ForegroundColor Green
Write-Host "  ✓ CodePipeline for automated deployment" -ForegroundColor Green
Write-Host "  ✓ GitHub connection (pending authorization)" -ForegroundColor Green
Write-Host ""

Write-Host "Estimated Monthly Cost: ~$143.29 USD" -ForegroundColor Cyan
Write-Host "  - EC2 t3.medium: $139.53" -ForegroundColor Gray
Write-Host "  - VPC & Networking: $3.65" -ForegroundColor Gray
Write-Host "  - EBS 40GB: Included" -ForegroundColor Gray
Write-Host ""
