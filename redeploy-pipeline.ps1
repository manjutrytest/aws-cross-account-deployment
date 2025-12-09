# Redeploy Pipeline in Account 821706771879

Write-Host "Deploying Pipeline in Account 821706771879" -ForegroundColor Cyan

# Set credentials - Configure these in your environment or AWS CLI
# $env:AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
# $env:AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
# $env:AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"

$account = aws sts get-caller-identity --query Account --output text
Write-Host "Account: $account"

if ($account -ne "821706771879") {
    Write-Host "Wrong account!" -ForegroundColor Red
    exit 1
}

Set-Location pipeline
terraform init
terraform apply -auto-approve
Set-Location ..

Write-Host "Done!" -ForegroundColor Green
