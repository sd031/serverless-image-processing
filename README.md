# Serverless Image Processing System

A simple serverless application that automatically resizes images uploaded to S3 using AWS Lambda, with SNS notifications and CloudWatch monitoring.

## 🎯 Project Overview

**Concepts Covered:**
- **S3**: Source and destination buckets for image storage
- **Lambda**: Python function for image processing
- **SNS**: Email notifications for processing status
- **CloudWatch**: Logs and alarms for monitoring

**Architecture Flow:**
1. User uploads an image to the source S3 bucket
2. S3 triggers Lambda function automatically
3. Lambda downloads, resizes, and uploads the image to destination bucket
4. SNS sends email notification with processing details
5. CloudWatch logs all activities and triggers alarms on errors

## 📋 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Python 3.11 or higher
- pip (Python package manager)
- Bash shell (for deployment scripts)

## 🚀 Quick Start

### 1. Configure AWS CLI

```bash
aws configure
```

Enter your AWS credentials:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

### 2. Deploy the System

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Prompt for your email address (for SNS notifications)
- Ask for AWS region (default: us-east-1)
- Create Lambda deployment package with dependencies
- Deploy CloudFormation stack with all resources
- Update Lambda function code

**Important:** Check your email and confirm the SNS subscription!

### 3. Test the System

Upload an image to the source bucket:

```bash
# Replace with your actual bucket name from deployment output
aws s3 cp test-image.jpg s3://image-processor-source-{ACCOUNT_ID}/
```

You should receive an email notification with processing details!

## 📁 Project Structure

```
aws_project_2/
├── lambda_function.py      # Main Lambda function for image processing
├── requirements.txt        # Python dependencies (Pillow, boto3)
├── cloudformation.yaml     # Infrastructure as Code template
├── deploy.sh              # Deployment script
├── cleanup.sh             # Resource cleanup script
├── test_local.py          # Local testing script
├── .gitignore            # Git ignore rules
└── README.md             # This file
```

## 🔧 Configuration

The Lambda function uses these environment variables (set automatically):

- `DESTINATION_BUCKET`: S3 bucket for processed images
- `SNS_TOPIC_ARN`: SNS topic for notifications
- `RESIZE_WIDTH`: Target width (default: 800px)
- `RESIZE_HEIGHT`: Target height (default: 600px)

To modify resize dimensions, edit the CloudFormation template before deployment.

## 📊 Monitoring

### View Lambda Logs

```bash
aws logs tail /aws/lambda/image-processor-function --follow
```

### CloudWatch Alarms

The system includes two alarms:
1. **Lambda Errors**: Triggers when function has errors
2. **Lambda Duration**: Triggers when execution time is high

Both alarms send notifications to your email via SNS.

### Check Processing Status

After uploading an image:
1. Check your email for SNS notification
2. View CloudWatch logs for detailed execution info
3. Verify processed image in destination bucket:

```bash
aws s3 ls s3://image-processor-processed-{ACCOUNT_ID}/resized/
```

## 🧪 Testing

### Local Testing (Structure Only)

```bash
python test_local.py
```

Note: This tests the function structure but requires AWS credentials and actual S3 buckets to fully work.

### End-to-End Testing

1. Upload various image formats:
```bash
aws s3 cp image.jpg s3://SOURCE_BUCKET/
aws s3 cp photo.png s3://SOURCE_BUCKET/
aws s3 cp picture.gif s3://SOURCE_BUCKET/
```

2. Check email notifications
3. Verify resized images in destination bucket
4. Review CloudWatch logs

## 📦 Resources Created

The CloudFormation stack creates:

- **2 S3 Buckets**: Source and destination
- **1 Lambda Function**: Image processor (Python 3.11)
- **1 SNS Topic**: Email notifications
- **1 IAM Role**: Lambda execution role with S3 and SNS permissions
- **1 CloudWatch Log Group**: Lambda logs (7-day retention)
- **2 CloudWatch Alarms**: Error and duration monitoring

## 🔍 How It Works

### Lambda Function Features

- **Image Format Support**: JPG, JPEG, PNG, GIF, BMP, TIFF, WEBP
- **Smart Resizing**: Maintains aspect ratio
- **RGBA Handling**: Converts RGBA to RGB automatically
- **Error Handling**: Sends failure notifications via SNS
- **Detailed Logging**: CloudWatch logs for debugging

### Processing Steps

1. Lambda receives S3 event notification
2. Validates file is an image
3. Downloads image from source bucket
4. Resizes while maintaining aspect ratio
5. Uploads to destination bucket with `resized/` prefix
6. Sends success notification with details:
   - Source and destination paths
   - Original and resized dimensions
   - Processing status

## 💰 Cost Considerations

This is a simple project with minimal costs:

- **S3**: Pay for storage and requests (minimal for testing)
- **Lambda**: Free tier includes 1M requests/month
- **SNS**: Free tier includes 1,000 email notifications/month
- **CloudWatch**: Free tier includes 5GB logs/month

**Estimated cost for testing**: < $1/month

## 🧹 Cleanup

To delete all resources and avoid charges:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

This will:
1. Empty both S3 buckets
2. Delete the CloudFormation stack
3. Remove all associated resources

## 🛠️ Troubleshooting

### Issue: Lambda function fails

**Check:**
- CloudWatch logs: `aws logs tail /aws/lambda/image-processor-function --follow`
- Verify image format is supported
- Ensure Lambda has sufficient memory (default: 512MB)

### Issue: No SNS notification received

**Check:**
- Confirm SNS subscription in email
- Check spam folder
- Verify SNS topic ARN in Lambda environment variables

### Issue: Deployment fails

**Check:**
- AWS credentials are configured: `aws sts get-caller-identity`
- You have necessary IAM permissions
- Bucket names are unique (includes account ID)
- Python dependencies install correctly

### Issue: Image not processed

**Check:**
- File extension is in supported formats
- Source bucket has correct Lambda trigger
- Lambda has S3 read/write permissions

## 📚 Learning Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Amazon SNS Documentation](https://docs.aws.amazon.com/sns/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [Pillow (PIL) Documentation](https://pillow.readthedocs.io/)

## 🎓 Key Concepts Demonstrated

1. **Event-Driven Architecture**: S3 events trigger Lambda automatically
2. **Serverless Computing**: No server management required
3. **Infrastructure as Code**: CloudFormation for reproducible deployments
4. **Monitoring & Alerting**: CloudWatch logs and alarms
5. **Notification System**: SNS for real-time updates
6. **IAM Security**: Least privilege access for Lambda

## 🔐 Security Best Practices

- S3 buckets have public access blocked
- Lambda uses IAM role with minimal required permissions
- No hardcoded credentials in code
- CloudWatch logs for audit trail

## 📝 Next Steps

To extend this project:

1. **Add more image operations**: Watermarking, format conversion, compression
2. **Support batch processing**: Process multiple images at once
3. **Add API Gateway**: Create REST API for on-demand processing
4. **Implement DynamoDB**: Track processing history
5. **Add Step Functions**: Orchestrate complex workflows
6. **Create thumbnails**: Generate multiple sizes
7. **Add image validation**: Check dimensions, file size, content

## 📄 License

This is a learning project - feel free to use and modify as needed!

## 🤝 Contributing

This is a simple educational project. Feel free to fork and enhance!

---

**Happy Learning! 🚀**
# serverless-image-processing
