# Deploy Pipeline in Target Account (now 821706771879)

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Deploying Pipeline in Account 821706771879             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Set target account credentials - Configure these in your environment or AWS CLI
Write-Host "Setting up target account (821706771879) credentials..." -ForegroundColor Yellow
# $env:AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
# $env:AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
# $env:AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"

# Verify account
$account = aws sts get-caller-identity --query Account --output text
Write-Host "Current Account: $account" -ForegroundColor Cyan

if ($account -ne "821706771879") {
    Write-Host "Error: Not authenticated as account 821706771879" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Authenticated as source account 821706771879" -ForegroundColor Green
Write-Host ""

# Deploy pipeline
Write-Host "Deploying CodePipeline infrastructure..." -ForegroundColor Yellow
Set-Location pipeline

terraform init
terraform apply -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS: Pipeline deployed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Authorize GitHub connection at:" -ForegroundColor White
    Write-Host "   https://eu-north-1.console.aws.amazon.com/codesuite/settings/connections?region=eu-north-1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Start pipeline execution:" -ForegroundColor White
    Write-Host "   aws codepipeline start-pipeline-execution --name terraform-deployment-pipeline --region eu-north-1" -ForegroundColor Cyan
} else {
    Write-Host "FAILED: Pipeline deployment failed" -ForegroundColor Red
}

Set-Location ..
