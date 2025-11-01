# Command Reference

Quick reference for all AWS commands used in this project.

## 🚀 Deployment Commands

### Deploy the Stack
```bash
./deploy.sh
```

### Manual Deployment (if script fails)
```bash
# Create Lambda package
pip install -r requirements.txt -t package/
cp lambda_function.py package/
cd package && zip -r ../lambda_package.zip . && cd ..

# Deploy CloudFormation
aws cloudformation deploy \
  --template-file cloudformation.yaml \
  --stack-name image-processor-stack \
  --parameter-overrides ProjectName=image-processor EmailAddress=your@email.com \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Update Lambda code
aws lambda update-function-code \
  --function-name image-processor-function \
  --zip-file fileb://lambda_package.zip \
  --region us-east-1
```

## 📤 Upload Commands

### Upload Single Image
```bash
./test_upload.sh your-image.jpg
```

### Manual Upload
```bash
# Replace BUCKET_NAME with your actual bucket name
aws s3 cp image.jpg s3://image-processor-source-{ACCOUNT_ID}/
```

### Upload Multiple Images
```bash
aws s3 cp ./images/ s3://image-processor-source-{ACCOUNT_ID}/ --recursive
```

### Download Sample Test Image
```bash
curl -o test-image.jpg https://picsum.photos/1920/1080
```

## 📊 Monitoring Commands

### View Lambda Logs (Live)
```bash
aws logs tail /aws/lambda/image-processor-function --follow --region us-east-1
```

### View Recent Logs
```bash
aws logs tail /aws/lambda/image-processor-function --since 1h --region us-east-1
```

### View Specific Log Stream
```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name /aws/lambda/image-processor-function \
  --order-by LastEventTime \
  --descending \
  --max-items 5 \
  --region us-east-1

# Get specific stream
aws logs get-log-events \
  --log-group-name /aws/lambda/image-processor-function \
  --log-stream-name 'STREAM_NAME' \
  --region us-east-1
```

### Check Lambda Metrics
```bash
# Get invocation count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=image-processor-function \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region us-east-1

# Get error count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=image-processor-function \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region us-east-1
```

## 🗂️ S3 Commands

### List Source Bucket
```bash
aws s3 ls s3://image-processor-source-{ACCOUNT_ID}/ --region us-east-1
```

### List Destination Bucket
```bash
aws s3 ls s3://image-processor-processed-{ACCOUNT_ID}/resized/ --region us-east-1
```

### Download Processed Image
```bash
aws s3 cp s3://image-processor-processed-{ACCOUNT_ID}/resized/image.jpg ./ --region us-east-1
```

### Sync All Processed Images
```bash
aws s3 sync s3://image-processor-processed-{ACCOUNT_ID}/resized/ ./processed-images/ --region us-east-1
```

### Get Bucket Size
```bash
aws s3 ls s3://image-processor-source-{ACCOUNT_ID}/ --recursive --summarize --human-readable --region us-east-1
```

## 📧 SNS Commands

### List SNS Topics
```bash
aws sns list-topics --region us-east-1
```

### List Subscriptions
```bash
aws sns list-subscriptions --region us-east-1
```

### Send Test Notification
```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:{ACCOUNT_ID}:image-processor-notifications \
  --subject "Test Notification" \
  --message "This is a test message" \
  --region us-east-1
```

### Confirm Subscription (if needed)
```bash
aws sns confirm-subscription \
  --topic-arn arn:aws:sns:us-east-1:{ACCOUNT_ID}:image-processor-notifications \
  --token TOKEN_FROM_EMAIL \
  --region us-east-1
```

## 🔍 Stack Information Commands

### Get Stack Status
```bash
aws cloudformation describe-stacks \
  --stack-name image-processor-stack \
  --region us-east-1
```

### Get Stack Outputs
```bash
aws cloudformation describe-stacks \
  --stack-name image-processor-stack \
  --query 'Stacks[0].Outputs' \
  --region us-east-1
```

### Get Specific Output
```bash
# Source bucket
aws cloudformation describe-stacks \
  --stack-name image-processor-stack \
  --query "Stacks[0].Outputs[?OutputKey=='SourceBucketName'].OutputValue" \
  --output text \
  --region us-east-1

# Destination bucket
aws cloudformation describe-stacks \
  --stack-name image-processor-stack \
  --query "Stacks[0].Outputs[?OutputKey=='DestinationBucketName'].OutputValue" \
  --output text \
  --region us-east-1

# Lambda ARN
aws cloudformation describe-stacks \
  --stack-name image-processor-stack \
  --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionArn'].OutputValue" \
  --output text \
  --region us-east-1
```

### List Stack Resources
```bash
aws cloudformation list-stack-resources \
  --stack-name image-processor-stack \
  --region us-east-1
```

## 🔧 Lambda Function Commands

### Get Function Configuration
```bash
aws lambda get-function-configuration \
  --function-name image-processor-function \
  --region us-east-1
```

### Update Environment Variables
```bash
aws lambda update-function-configuration \
  --function-name image-processor-function \
  --environment Variables={RESIZE_WIDTH=1024,RESIZE_HEIGHT=768} \
  --region us-east-1
```

### Invoke Function Manually
```bash
aws lambda invoke \
  --function-name image-processor-function \
  --payload file://test-event.json \
  --region us-east-1 \
  response.json
```

### Get Function Metrics
```bash
aws lambda get-function \
  --function-name image-processor-function \
  --region us-east-1
```

## 🚨 Alarm Commands

### List Alarms
```bash
aws cloudwatch describe-alarms --region us-east-1
```

### Get Alarm State
```bash
aws cloudwatch describe-alarms \
  --alarm-names image-processor-lambda-errors \
  --region us-east-1
```

### Disable Alarm
```bash
aws cloudwatch disable-alarm-actions \
  --alarm-names image-processor-lambda-errors \
  --region us-east-1
```

### Enable Alarm
```bash
aws cloudwatch enable-alarm-actions \
  --alarm-names image-processor-lambda-errors \
  --region us-east-1
```

## 🧹 Cleanup Commands

### Automated Cleanup
```bash
./cleanup.sh
```

### Manual Cleanup
```bash
# Empty source bucket
aws s3 rm s3://image-processor-source-{ACCOUNT_ID}/ --recursive --region us-east-1

# Empty destination bucket
aws s3 rm s3://image-processor-processed-{ACCOUNT_ID}/ --recursive --region us-east-1

# Delete stack
aws cloudformation delete-stack \
  --stack-name image-processor-stack \
  --region us-east-1

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name image-processor-stack \
  --region us-east-1
```

## 🔐 IAM Commands

### Get Caller Identity
```bash
aws sts get-caller-identity
```

### List IAM Roles
```bash
aws iam list-roles --query 'Roles[?contains(RoleName, `image-processor`)]' --region us-east-1
```

### Get Role Policy
```bash
aws iam get-role \
  --role-name image-processor-lambda-role \
  --region us-east-1
```

## 📈 Cost Commands

### Get Cost Estimate
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=SERVICE \
  --region us-east-1
```

## 🧪 Testing Commands

### Test Lambda Locally
```bash
python test_local.py
```

### Validate CloudFormation Template
```bash
aws cloudformation validate-template \
  --template-body file://cloudformation.yaml \
  --region us-east-1
```

### Check Python Syntax
```bash
python -m py_compile lambda_function.py
```

### Install Dependencies Locally
```bash
pip install -r requirements.txt
```

## 📝 Useful Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Image processor aliases
alias img-deploy='cd /Users/sandipdas/aws_project_2 && ./deploy.sh'
alias img-upload='cd /Users/sandipdas/aws_project_2 && ./test_upload.sh'
alias img-logs='aws logs tail /aws/lambda/image-processor-function --follow --region us-east-1'
alias img-cleanup='cd /Users/sandipdas/aws_project_2 && ./cleanup.sh'
alias img-status='aws cloudformation describe-stacks --stack-name image-processor-stack --region us-east-1'
```

## 🔄 Common Workflows

### Complete Test Cycle
```bash
# 1. Deploy
./deploy.sh

# 2. Upload test image
./test_upload.sh test-image.jpg

# 3. Watch logs
aws logs tail /aws/lambda/image-processor-function --follow --region us-east-1

# 4. Check processed image
aws s3 ls s3://image-processor-processed-{ACCOUNT_ID}/resized/

# 5. Download result
aws s3 cp s3://image-processor-processed-{ACCOUNT_ID}/resized/test-image.jpg ./result.jpg
```

### Troubleshooting Workflow
```bash
# 1. Check stack status
aws cloudformation describe-stacks --stack-name image-processor-stack --region us-east-1

# 2. View recent logs
aws logs tail /aws/lambda/image-processor-function --since 1h --region us-east-1

# 3. Check Lambda config
aws lambda get-function-configuration --function-name image-processor-function --region us-east-1

# 4. Test SNS
aws sns publish --topic-arn arn:aws:sns:us-east-1:{ACCOUNT_ID}:image-processor-notifications --subject "Test" --message "Test" --region us-east-1

# 5. Check alarms
aws cloudwatch describe-alarms --region us-east-1
```

---

**Tip**: Replace `{ACCOUNT_ID}` with your actual AWS account ID in all commands.

**Get Account ID**:
```bash
aws sts get-caller-identity --query Account --output text
```
