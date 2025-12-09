# Script to help authorize GitHub connection and monitor deployment

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     GitHub Connection Authorization & Deployment          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check connection status
Write-Host "Checking GitHub connection status..." -ForegroundColor Yellow
$connection = aws codestar-connections get-connection --connection-arn "arn:aws:codestar-connections:eu-north-1:047861165149:connection/d8abe732-84d8-45ae-968b-ef4effac75e4" | ConvertFrom-Json

Write-Host "Connection Status: " -NoNewline
if ($connection.Connection.ConnectionStatus -eq "AVAILABLE") {
    Write-Host "AVAILABLE [OK]" -ForegroundColor Green
}
else {
    Write-Host "PENDING ⚠" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ACTION REQUIRED: Authorize GitHub Connection" -ForegroundColor Red
    Write-Host ""
    Write-Host "Steps to authorize:" -ForegroundColor White
    Write-Host "1. Open this URL in your browser:" -ForegroundColor White
    Write-Host "   https://eu-north-1.console.aws.amazon.com/codesuite/settings/connections?region=eu-north-1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Find connection: github-connection" -ForegroundColor White
    Write-Host "3. Click 'Update pending connection'" -ForegroundColor White
    Write-Host "4. Click 'Install a new app' or select existing GitHub app" -ForegroundColor White
    Write-Host "5. Authorize AWS CodeStar to access your repository" -ForegroundColor White
    Write-Host ""
    
    $continue = Read-Host "Have you completed the authorization? (yes/no)"
    
    if ($continue -ne "yes") {
        Write-Host "Please complete the authorization and run this script again." -ForegroundColor Yellow
        exit 0
    }
    
    # Recheck status
    Write-Host ""
    Write-Host "Rechecking connection status..." -ForegroundColor Yellow
    $connection = aws codestar-connections get-connection --connection-arn "arn:aws:codestar-connections:eu-north-1:047861165149:connection/d8abe732-84d8-45ae-968b-ef4effac75e4" | ConvertFrom-Json
    
    if ($connection.Connection.ConnectionStatus -ne "AVAILABLE") {
        Write-Host "Connection still pending. Please ensure authorization is complete." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Connection Status: AVAILABLE [OK]" -ForegroundColor Green
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Triggering Pipeline Execution                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Start pipeline execution
Write-Host "Starting pipeline execution..." -ForegroundColor Yellow
$execution = aws codepipeline start-pipeline-execution --name terraform-deployment-pipeline --region eu-north-1 | ConvertFrom-Json

Write-Host "Pipeline execution started!" -ForegroundColor Green
Write-Host "Execution ID: $($execution.pipelineExecutionId)" -ForegroundColor Cyan
Write-Host ""

# Monitor pipeline
Write-Host "Monitoring pipeline execution..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring (pipeline will continue running)" -ForegroundColor Gray
Write-Host ""

$lastStatus = ""
while ($true) {
    Start-Sleep -Seconds 10
    
    $state = aws codepipeline get-pipeline-state --name terraform-deployment-pipeline --region eu-north-1 | ConvertFrom-Json
    
    foreach ($stage in $state.stageStates) {
        $stageName = $stage.stageName
        $stageStatus = if ($stage.latestExecution) { $stage.latestExecution.status } else { "Not Started" }
        
        $statusDisplay = switch ($stageStatus) {
            "Succeeded" { "[OK] $stageStatus" }
            "InProgress" { "[RUNNING] $stageStatus" }
            "Failed" { "[FAILED] $stageStatus" }
            default { "[PENDING] $stageStatus" }
        }
        
        $color = switch ($stageStatus) {
            "Succeeded" { "Green" }
            "InProgress" { "Yellow" }
            "Failed" { "Red" }
            default { "Gray" }
        }
        
        $currentStatus = "$stageName : $statusDisplay"
        if ($currentStatus -ne $lastStatus) {
            Write-Host "  $stageName : " -NoNewline
            Write-Host $statusDisplay -ForegroundColor $color
            $lastStatus = $currentStatus
        }
        
        # Check for approval stage
        if ($stageName -eq "Approve" -and $stageStatus -eq "InProgress") {
            Write-Host ""
            Write-Host "[!] MANUAL APPROVAL REQUIRED [!]" -ForegroundColor Yellow
            Write-Host "Go to: https://eu-north-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/terraform-deployment-pipeline/view?region=eu-north-1" -ForegroundColor Cyan
            Write-Host "Click 'Review' and approve the deployment" -ForegroundColor White
            Write-Host ""
        }
    }
    
    # Check if pipeline is complete
    $pipelineStatus = $state.stageStates[-1].latestExecution.status
    if ($pipelineStatus -eq "Succeeded") {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║     Pipeline Execution Completed Successfully!             ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Infrastructure deployed to target account (821706771879)" -ForegroundColor Green
        Write-Host "Region: eu-north-1" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Verify deployment:" -ForegroundColor Yellow
        Write-Host "  aws ec2 describe-instances --region eu-north-1" -ForegroundColor White
        break
    } elseif ($pipelineStatus -eq "Failed") {
        Write-Host ""
        Write-Host "Pipeline execution failed. Check CodeBuild logs for details." -ForegroundColor Red
        break
    }
}

Write-Host ""
Write-Host "View full pipeline details:" -ForegroundColor Yellow
Write-Host "https://eu-north-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/terraform-deployment-pipeline/view?region=eu-north-1" -ForegroundColor Cyan
