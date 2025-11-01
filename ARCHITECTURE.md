# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Serverless Image Processing                   │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │    User      │
    └──────┬───────┘
           │ Upload Image
           ▼
    ┌──────────────────┐
    │  Source S3       │
    │  Bucket          │◄────────────┐
    └──────┬───────────┘             │
           │                         │
           │ S3 Event Trigger        │
           ▼                         │
    ┌──────────────────┐             │
    │  Lambda          │             │
    │  Function        │             │
    │  (Python 3.11)   │             │
    └──────┬───────────┘             │
           │                         │
           │ 1. Download Image       │
           │ 2. Resize Image         │
           │ 3. Upload Processed     │
           │                         │
           ▼                         │
    ┌──────────────────┐             │
    │  Destination     │             │
    │  S3 Bucket       │             │
    └──────┬───────────┘             │
           │                         │
           │ Success/Failure         │
           ▼                         │
    ┌──────────────────┐             │
    │  SNS Topic       │             │
    └──────┬───────────┘             │
           │                         │
           │ Email Notification      │
           ▼                         │
    ┌──────────────────┐             │
    │  User Email      │             │
    └──────────────────┘             │
                                     │
    ┌──────────────────┐             │
    │  CloudWatch      │             │
    │  Logs & Alarms   │─────────────┘
    └──────────────────┘
         │
         │ Monitoring & Alerts
         ▼
    ┌──────────────────┐
    │  SNS Topic       │
    └──────────────────┘
```

## Component Details

### 1. Source S3 Bucket
- **Purpose**: Store original uploaded images
- **Trigger**: Configured to trigger Lambda on ObjectCreated events
- **Naming**: `image-processor-source-{ACCOUNT_ID}`

### 2. Lambda Function
- **Runtime**: Python 3.11
- **Memory**: 512 MB
- **Timeout**: 60 seconds
- **Dependencies**: Pillow (PIL), boto3
- **Environment Variables**:
  - `DESTINATION_BUCKET`: Target bucket for processed images
  - `SNS_TOPIC_ARN`: Topic for notifications
  - `RESIZE_WIDTH`: 800px (default)
  - `RESIZE_HEIGHT`: 600px (default)

### 3. Destination S3 Bucket
- **Purpose**: Store resized/processed images
- **Structure**: Images stored with `resized/` prefix
- **Naming**: `image-processor-processed-{ACCOUNT_ID}`

### 4. SNS Topic
- **Purpose**: Send email notifications
- **Subscriptions**: User email (configured during deployment)
- **Messages**:
  - Success: Image details, dimensions, paths
  - Failure: Error information

### 5. CloudWatch
- **Logs**: All Lambda execution logs (7-day retention)
- **Alarms**:
  - Error alarm: Triggers on Lambda errors
  - Duration alarm: Triggers on high execution time
- **Metrics**: Invocations, errors, duration, throttles

### 6. IAM Role
- **Purpose**: Lambda execution permissions
- **Policies**:
  - Read from source bucket
  - Write to destination bucket
  - Publish to SNS topic
  - Write to CloudWatch logs

## Data Flow

1. **Upload**: User uploads image to source S3 bucket
2. **Trigger**: S3 sends event notification to Lambda
3. **Process**:
   - Lambda downloads image from source bucket
   - Validates image format
   - Resizes image maintaining aspect ratio
   - Converts RGBA to RGB if needed
4. **Store**: Lambda uploads processed image to destination bucket
5. **Notify**: Lambda publishes success/failure message to SNS
6. **Alert**: User receives email notification
7. **Monitor**: CloudWatch logs execution and triggers alarms if needed

## Security

- **S3 Buckets**: Public access blocked
- **Lambda**: Runs with least privilege IAM role
- **SNS**: Email subscription requires confirmation
- **CloudWatch**: Audit trail of all operations

## Scalability

- **Automatic**: Lambda scales automatically based on load
- **Concurrent Executions**: Default AWS account limits apply
- **S3**: Unlimited storage capacity
- **Cost-Effective**: Pay only for what you use

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- BMP (.bmp)
- TIFF (.tiff)
- WebP (.webp)

## Processing Logic

```python
1. Receive S3 event
2. Extract bucket and object key
3. Validate file extension
4. Download image from S3
5. Open image with PIL
6. Convert RGBA → RGB if needed
7. Calculate new dimensions (maintain aspect ratio)
8. Resize using LANCZOS algorithm
9. Save to buffer
10. Upload to destination bucket
11. Send SNS notification
12. Log to CloudWatch
```

## Error Handling

- **Invalid Format**: Skip processing, log warning
- **Download Failure**: Retry with exponential backoff (AWS SDK default)
- **Processing Error**: Send failure notification, log error
- **Upload Failure**: Raise exception, trigger alarm
- **SNS Failure**: Log error but don't fail the function

## Monitoring Metrics

### Lambda Metrics
- **Invocations**: Number of times function is invoked
- **Errors**: Number of failed executions
- **Duration**: Execution time per invocation
- **Throttles**: Number of throttled invocations
- **Concurrent Executions**: Number of concurrent executions

### S3 Metrics
- **NumberOfObjects**: Total objects in buckets
- **BucketSizeBytes**: Total storage used
- **AllRequests**: Total API requests

### SNS Metrics
- **NumberOfMessagesPublished**: Messages sent
- **NumberOfNotificationsFailed**: Failed deliveries

## Cost Breakdown

### Lambda
- **Requests**: $0.20 per 1M requests
- **Duration**: $0.0000166667 per GB-second
- **Free Tier**: 1M requests + 400,000 GB-seconds/month

### S3
- **Storage**: $0.023 per GB/month (Standard)
- **Requests**: $0.005 per 1,000 PUT requests
- **Free Tier**: 5GB storage + 20,000 GET + 2,000 PUT/month

### SNS
- **Email**: $2.00 per 100,000 notifications
- **Free Tier**: 1,000 email notifications/month

### CloudWatch
- **Logs**: $0.50 per GB ingested
- **Free Tier**: 5GB logs/month

**Estimated Monthly Cost (Light Usage)**: < $1

## Performance Optimization

1. **Memory Allocation**: 512MB (adjust based on image sizes)
2. **Timeout**: 60 seconds (sufficient for most images)
3. **Image Quality**: 85% (balance between quality and size)
4. **Resampling**: LANCZOS (high-quality downsampling)
5. **Buffer Usage**: In-memory processing (no disk I/O)

## Future Enhancements

- [ ] Support for batch processing
- [ ] Multiple resize dimensions (thumbnails)
- [ ] Image format conversion
- [ ] Watermarking
- [ ] Content-aware resizing
- [ ] DynamoDB for processing history
- [ ] API Gateway for REST API
- [ ] Step Functions for complex workflows
- [ ] S3 Transfer Acceleration
- [ ] CloudFront distribution for processed images
