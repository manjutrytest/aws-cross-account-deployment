# Update Pipeline to use MEDIUM compute type

Write-Host "Updating CodeBuild compute type to MEDIUM..." -ForegroundColor Yellow

Set-Location pipeline

# Plan the changes
Write-Host "Planning Terraform changes..." -ForegroundColor Yellow
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform plan failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host ""
Write-Host "Changes to apply:" -ForegroundColor Cyan
Write-Host "  - CodeBuild compute type: SMALL -> MEDIUM" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Apply these changes? (yes/no)"

if ($confirm -eq "yes") {
    Write-Host "Applying changes..." -ForegroundColor Yellow
    terraform apply tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Pipeline updated successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Pushing updated code to GitHub..." -ForegroundColor Yellow
        Set-Location ..
        git add pipeline/pipeline.tf
        git commit -m "Update CodeBuild to MEDIUM compute type"
        git push origin main
        
        Write-Host ""
        Write-Host "Starting pipeline execution..." -ForegroundColor Yellow
        aws codepipeline start-pipeline-execution --name terraform-deployment-pipeline --region eu-north-1
        
        Write-Host ""
        Write-Host "Pipeline execution started!" -ForegroundColor Green
        Write-Host "Monitor at: https://eu-north-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/terraform-deployment-pipeline/view?region=eu-north-1" -ForegroundColor Cyan
    } else {
        Write-Host "Terraform apply failed!" -ForegroundColor Red
    }
} else {
    Write-Host "Update cancelled" -ForegroundColor Yellow
}

Set-Location ..
