# Simple deployment starter script

Write-Host "=== Cross-Account Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check connection status
Write-Host "Checking GitHub connection..." -ForegroundColor Yellow
$connJson = aws codestar-connections get-connection --connection-arn "arn:aws:codestar-connections:eu-north-1:047861165149:connection/d8abe732-84d8-45ae-968b-ef4effac75e4"
$connection = $connJson | ConvertFrom-Json

$status = $connection.Connection.ConnectionStatus
Write-Host "Status: $status" -ForegroundColor $(if ($status -eq "AVAILABLE") { "Green" } else { "Yellow" })

if ($status -ne "AVAILABLE") {
    Write-Host ""
    Write-Host "ACTION REQUIRED:" -ForegroundColor Red
    Write-Host "1. Open: https://eu-north-1.console.aws.amazon.com/codesuite/settings/connections?region=eu-north-1" -ForegroundColor Cyan
    Write-Host "2. Find 'github-connection' and click 'Update pending connection'" -ForegroundColor White
    Write-Host "3. Authorize AWS to access your GitHub repository" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Press Enter after completing authorization"
}

# Start pipeline
Write-Host ""
Write-Host "Starting pipeline execution..." -ForegroundColor Yellow
aws codepipeline start-pipeline-execution --name terraform-deployment-pipeline --region eu-north-1

Write-Host ""
Write-Host "Pipeline started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Monitor pipeline at:" -ForegroundColor Yellow
Write-Host "https://eu-north-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/terraform-deployment-pipeline/view?region=eu-north-1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pipeline Stages:" -ForegroundColor Yellow
Write-Host "  1. Source - Pulls code from GitHub" -ForegroundColor White
Write-Host "  2. Plan - Runs terraform plan" -ForegroundColor White
Write-Host "  3. Approve - MANUAL APPROVAL REQUIRED" -ForegroundColor Red
Write-Host "  4. Deploy - Runs terraform apply" -ForegroundColor White
Write-Host ""
Write-Host "You must approve at stage 3 for deployment to proceed!" -ForegroundColor Yellow
