# Push to GitHub without credentials
Set-Location $PSScriptRoot

# Remove git
Remove-Item -Recurse -Force .git -ErrorAction SilentlyContinue

# Remove credentials file
Remove-Item target-creds.ps1 -ErrorAction SilentlyContinue

# Initialize fresh repo
git init
git add .
git commit -m "Initial cross-account infrastructure deployment"
git branch -M main
git remote add origin https://github.com/manjutrytest/aws-cross-account-deployment.git
git push -u origin main --force

Write-Host ""
Write-Host "Successfully pushed to GitHub!" -ForegroundColor Green
