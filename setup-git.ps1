# Setup Git Repository
Set-Location $PSScriptRoot

# Remove any existing git repos
Remove-Item -Recurse -Force .git -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force pipeline\.git -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force terraform\.git -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force iam\.git -ErrorAction SilentlyContinue

# Remove .terraform directories to avoid large files
Remove-Item -Recurse -Force pipeline\.terraform -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force terraform\.terraform -ErrorAction SilentlyContinue

# Initialize git
git init
git add .
git commit -m "Initial cross-account infrastructure setup"
git branch -M main
git remote add origin https://github.com/manjutrytest/aws-cross-account-deployment.git
git push -u origin main

Write-Host ""
Write-Host "Git repository setup complete!" -ForegroundColor Green
Write-Host "Repository: https://github.com/manjutrytest/aws-cross-account-deployment" -ForegroundColor Cyan
