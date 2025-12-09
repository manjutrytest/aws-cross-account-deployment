# Cross-Account Deployment Script
# Run this script to deploy infrastructure step by step

param(
    [Parameter(Mandatory=$false)]
    [string]$TargetProfile = "target-account",
    
    [Parameter(Mandatory=$false)]
    [string]$GithubRepo = "your-org/your-repo"
)

Write-Host "=== Cross-Account Deployment Script ===" -ForegroundColor Cyan
Write-Host ""

# Check current account
Write-Host "Checking current AWS account..." -ForegroundColor Yellow
$currentAccount = aws sts get-caller-identity --query Account --output text
Write-Host "Current Account: $currentAccount" -ForegroundColor Green

if ($currentAccount -ne "047861165149") {
    Write-Host "ERROR: Please configure AWS CLI for source account (047861165149)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Step 1: Deploy IAM Roles in Target Account ===" -ForegroundColor Cyan
Write-Host "This requires credentials for target account (821706771879)" -ForegroundColor Yellow
Write-Host ""

$deployIAM = Read-Host "Do you have target account credentials configured? (y/n)"

if ($deployIAM -eq "y") {
    Write-Host "Deploying IAM roles in target account..." -ForegroundColor Yellow
    
    Set-Location iam
    
    # Check if target account profile exists
    $targetAccount = aws sts get-caller-identity --profile $TargetProfile --query Account --output text 2>$null
    
    if ($targetAccount -eq "821706771879") {
        Write-Host "Target account verified: $targetAccount" -ForegroundColor Green
        
        terraform init
        terraform plan
        
        $confirm = Read-Host "Apply IAM roles? (yes/no)"
        if ($confirm -eq "yes") {
            terraform apply -auto-approve
            Write-Host "IAM roles deployed successfully!" -ForegroundColor Green
        }
    } else {
        Write-Host "ERROR: Target account profile not found or incorrect account" -ForegroundColor Red
        Write-Host "Please configure AWS CLI profile for target account:" -ForegroundColor Yellow
        Write-Host "  aws configure --profile $TargetProfile" -ForegroundColor White
        exit 1
    }
    
    Set-Location ..
} else {
    Write-Host ""
    Write-Host "Please configure target account credentials first:" -ForegroundColor Yellow
    Write-Host "  aws configure --profile target-account" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=== Step 2: Deploy Pipeline in Source Account ===" -ForegroundColor Cyan
Write-Host ""

$deployPipeline = Read-Host "Deploy CodePipeline in source account? (y/n)"

if ($deployPipeline -eq "y") {
    Write-Host "Deploying pipeline infrastructure..." -ForegroundColor Yellow
    
    Set-Location pipeline
    
    terraform init
    terraform plan -var="github_repo=$GithubRepo"
    
    $confirm = Read-Host "Apply pipeline? (yes/no)"
    if ($confirm -eq "yes") {
        terraform apply -auto-approve -var="github_repo=$GithubRepo"
        Write-Host "Pipeline deployed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "1. Go to AWS Console -> Developer Tools -> Connections" -ForegroundColor White
        Write-Host "2. Find 'github-connection' and complete the authorization" -ForegroundColor White
        Write-Host "3. Push this code to your GitHub repository" -ForegroundColor White
        Write-Host "4. Pipeline will automatically trigger" -ForegroundColor White
    }
    
    Set-Location ..
}

Write-Host ""
Write-Host "=== Deployment Script Complete ===" -ForegroundColor Green
