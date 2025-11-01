# Quick Start Guide

## 🚀 Deploy in 3 Steps

### Step 1: Configure AWS
```bash
aws configure
```

### Step 2: Deploy
```bash
./deploy.sh
```
- Enter your email when prompted
- Choose AWS region (or press Enter for us-east-1)
- **Important**: Check your email and confirm SNS subscription!

### Step 3: Test
```bash
# Upload a test image
aws s3 cp your-image.jpg s3://image-processor-source-{YOUR_ACCOUNT_ID}/

# Watch logs
aws logs tail /aws/lambda/image-processor-function --follow
```

## 📧 Check Your Email
You'll receive a notification with:
- Original image size
- Resized image dimensions
- Source and destination paths
- Processing status

## 🧹 Cleanup
```bash
./cleanup.sh
```

## 📊 View Results
```bash
# List processed images
aws s3 ls s3://image-processor-processed-{YOUR_ACCOUNT_ID}/resized/

# Download processed image
aws s3 cp s3://image-processor-processed-{YOUR_ACCOUNT_ID}/resized/your-image.jpg ./
```

## ⚠️ Troubleshooting

**No email received?**
- Check spam folder
- Confirm SNS subscription in email
- Check CloudWatch logs

**Deployment failed?**
- Verify AWS credentials: `aws sts get-caller-identity`
- Check you have necessary IAM permissions
- Ensure Python 3.11+ is installed

**Image not processed?**
- Verify image format is supported (jpg, png, gif, etc.)
- Check CloudWatch logs for errors
- Ensure file uploaded successfully to source bucket

## 💡 Tips

1. **Supported formats**: JPG, PNG, GIF, BMP, TIFF, WebP
2. **Default resize**: 800x600 (maintains aspect ratio)
3. **Processed images**: Stored with `resized/` prefix
4. **Logs retention**: 7 days
5. **Cost**: < $1/month for testing

## 📚 More Info
- See `README.md` for detailed documentation
- See `ARCHITECTURE.md` for system design
- See `lambda_function.py` for processing logic

---
**Need help?** Check the full README.md file!
