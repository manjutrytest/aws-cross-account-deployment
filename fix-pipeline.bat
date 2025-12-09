@echo off
echo Updating CodeBuild project to MEDIUM compute type...
cd pipeline
terraform apply -auto-approve
cd ..
echo.
echo Committing changes to Git...
git add pipeline/pipeline.tf
git commit -m "Fix: Update CodeBuild to MEDIUM compute type"
git push origin main
echo.
echo Restarting pipeline...
aws codepipeline start-pipeline-execution --name terraform-deployment-pipeline --region eu-north-1
echo.
echo Done! Monitor pipeline at:
echo https://eu-north-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/terraform-deployment-pipeline/view?region=eu-north-1
pause
