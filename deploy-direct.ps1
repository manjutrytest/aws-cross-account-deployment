# Direct Terraform Deployment Script
# Bypasses CodePipeline and deploys directly to target account

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Direct Cross-Account Infrastructure Deployment         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will deploy infrastructure directly to the target account" -ForegroundColor Yellow
Write-Host "bypassing the CodePipeline due to CodeBuild quota limitations." -ForegroundColor Yellow
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "terraform")) {
    Write-Host "Error: terraform directory not found. Please run from project root." -ForegroundColor Red
    exit 1
}

# Verify current account
Write-Host "Verifying AWS credentials..." -ForegroundColor Yellow
$currentAccount = aws sts get-caller-identity --query Account --output text

Write-Host "Current Account: $currentAccount" -ForegroundColor Cyan

if ($currentAccount -eq "047861165149") {
    Write-Host ""
    Write-Host "You are currently authenticated as the SOURCE account." -ForegroundColor Yellow
    Write-Host "We need to deploy to the TARGET account (821706771879)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please provide target account credentials:" -ForegroundColor White
    Write-Host ""
    
    $accessKey = Read-Host "AWS Access Key ID"
    $secretKey = Read-Host "AWS Secret Access Key" -AsSecureString
    $sessionToken = Read-Host "AWS Session Token (press Enter if not using temporary credentials)"
    
    # Convert secure string to plain text
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey)
    $secretKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    # Set environment variables
    $env:AWS_ACCESS_KEY_ID = $accessKey
    $env:AWS_SECRET_ACCESS_KEY = $secretKeyPlain
    if ($sessionToken) {
        $env:AWS_SESSION_TOKEN = $sessionToken
    }
    
    # Verify target account
    $targetAccount = aws sts get-caller-identity --query Account --output text
    
    if ($targetAccount -ne "821706771879") {
        Write-Host ""
        Write-Host "Error: Credentials are for account $targetAccount, not 821706771879" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "✓ Target account verified: $targetAccount" -ForegroundColor Green
}
elseif ($currentAccount -eq "821706771879") {
    Write-Host "✓ Already authenticated as target account" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "Warning: Current account ($currentAccount) is neither source nor target" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (yes/no)"
    if ($continue -ne "yes") {
        exit 0
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Deploying Infrastructure with Terraform                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Set-Location terraform

# Initialize Terraform
Write-Host "Step 1: Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform init failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Terraform initialized" -ForegroundColor Green
Write-Host ""

# Plan
Write-Host "Step 2: Creating Terraform plan..." -ForegroundColor Yellow
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform plan failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Terraform plan created" -ForegroundColor Green
Write-Host ""

# Review and confirm
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║     REVIEW THE PLAN ABOVE                                   ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "Resources to be created:" -ForegroundColor White
Write-Host "  - VPC (10.0.0.0/16)" -ForegroundColor Gray
Write-Host "  - Public Subnet (10.0.1.0/24)" -ForegroundColor Gray
Write-Host "  - Internet Gateway" -ForegroundColor Gray
Write-Host "  - EC2 Instance (t3.medium, Windows Server 2022)" -ForegroundColor Gray
Write-Host "  - EBS Volume (40 GB gp3)" -ForegroundColor Gray
Write-Host "  - Elastic IP" -ForegroundColor Gray
Write-Host "  - Security Group (RDP access)" -ForegroundColor Gray
Write-Host ""
Write-Host "Estimated Monthly Cost: ~$143.29 USD" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Do you want to apply this plan? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    Set-Location ..
    exit 0
}

# Apply
Write-Host ""
Write-Host "Step 3: Applying Terraform configuration..." -ForegroundColor Yellow
terraform apply tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform apply failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     Deployment Completed Successfully!                      ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Get outputs
Write-Host "Deployment Outputs:" -ForegroundColor Yellow
terraform output

Write-Host ""
Write-Host "Resources deployed to:" -ForegroundColor White
Write-Host "  Account: 821706771879" -ForegroundColor Cyan
Write-Host "  Region: eu-north-1" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify EC2 instance in AWS Console" -ForegroundColor White
Write-Host "  2. Connect via RDP using the Elastic IP" -ForegroundColor White
Write-Host "  3. Check CloudFormation stacks for tracking" -ForegroundColor White
Write-Host ""

Set-Location ..
