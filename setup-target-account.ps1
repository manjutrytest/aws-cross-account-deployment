# Script to help configure target account access

Write-Host "=== Target Account Configuration ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "You need credentials for target account: 821706771879" -ForegroundColor Yellow
Write-Host ""
Write-Host "Choose your authentication method:" -ForegroundColor White
Write-Host "1. AWS Access Keys (Access Key ID + Secret Access Key)" -ForegroundColor White
Write-Host "2. AWS SSO" -ForegroundColor White
Write-Host "3. I'll do it manually" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (1/2/3)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Configuring AWS CLI profile with access keys..." -ForegroundColor Yellow
        Write-Host ""
        aws configure --profile target-account
        
        Write-Host ""
        Write-Host "Verifying target account..." -ForegroundColor Yellow
        $targetAccount = aws sts get-caller-identity --profile target-account --query Account --output text 2>$null
        
        if ($targetAccount -eq "821706771879") {
            Write-Host "✓ Target account verified: $targetAccount" -ForegroundColor Green
            Write-Host ""
            Write-Host "Profile 'target-account' is ready!" -ForegroundColor Green
        } else {
            Write-Host "✗ Account mismatch. Expected: 821706771879, Got: $targetAccount" -ForegroundColor Red
        }
    }
    "2" {
        Write-Host ""
        Write-Host "Configuring AWS SSO..." -ForegroundColor Yellow
        Write-Host ""
        aws configure sso --profile target-account
        
        Write-Host ""
        Write-Host "Logging in to SSO..." -ForegroundColor Yellow
        aws sso login --profile target-account
        
        Write-Host ""
        Write-Host "Verifying target account..." -ForegroundColor Yellow
        $targetAccount = aws sts get-caller-identity --profile target-account --query Account --output text
        
        if ($targetAccount -eq "821706771879") {
            Write-Host "✓ Target account verified: $targetAccount" -ForegroundColor Green
        } else {
            Write-Host "✗ Account mismatch. Expected: 821706771879, Got: $targetAccount" -ForegroundColor Red
        }
    }
    "3" {
        Write-Host ""
        Write-Host "Manual configuration steps:" -ForegroundColor Yellow
        Write-Host "1. Run: aws configure --profile target-account" -ForegroundColor White
        Write-Host "2. Enter your target account credentials" -ForegroundColor White
        Write-Host "3. Verify with: aws sts get-caller-identity --profile target-account" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host ""
Write-Host "Next step: Run the main deployment script" -ForegroundColor Cyan
Write-Host "  .\deploy-full-pipeline.ps1 -GithubRepo 'your-org/your-repo'" -ForegroundColor White
