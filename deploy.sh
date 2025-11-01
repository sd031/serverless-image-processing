#!/bin/bash

# Serverless Image Processing System Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="image-processor"
STACK_NAME="${PROJECT_NAME}-stack"
REGION="us-west-2"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Serverless Image Processing Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Please run: aws configure"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials configured${NC}"
echo ""

# Get email address for SNS notifications
read -p "Enter email address for notifications: " EMAIL_ADDRESS

if [[ ! "$EMAIL_ADDRESS" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}Error: Invalid email address${NC}"
    exit 1
fi

# Get AWS region
read -p "Enter AWS region (default: us-west-2): " INPUT_REGION
REGION=${INPUT_REGION:-$REGION}

echo ""
echo -e "${YELLOW}Creating Lambda deployment package...${NC}"

# Create a temporary directory for the Lambda package
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="${TEMP_DIR}/package"
mkdir -p "$PACKAGE_DIR"

# Install Python dependencies for Linux (Lambda runtime)
echo "Installing dependencies for Lambda (Linux x86_64)..."
pip install -r requirements.txt -t "$PACKAGE_DIR" \
    --platform manylinux2014_x86_64 \
    --only-binary=:all: \
    --python-version 3.11 \
    --implementation cp \
    --quiet 2>&1 | grep -v "dependency conflicts" || true

# Copy Lambda function
cp lambda_function.py "$PACKAGE_DIR/"

# Create ZIP file
cd "$PACKAGE_DIR"
zip -r ../lambda_package.zip . > /dev/null
cd - > /dev/null

echo -e "${GREEN}✓ Lambda package created${NC}"
echo ""

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Deploy CloudFormation stack
echo -e "${YELLOW}Deploying CloudFormation stack...${NC}"
aws cloudformation deploy \
    --template-file cloudformation.yaml \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        ProjectName="$PROJECT_NAME" \
        EmailAddress="$EMAIL_ADDRESS" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION"

echo -e "${GREEN}✓ CloudFormation stack deployed${NC}"
echo ""

# Get Lambda function name from stack outputs
LAMBDA_FUNCTION_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionName'].OutputValue" \
    --output text \
    --region "$REGION")

# Update Lambda function code
echo -e "${YELLOW}Updating Lambda function code...${NC}"
aws lambda update-function-code \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --zip-file "fileb://${TEMP_DIR}/lambda_package.zip" \
    --region "$REGION" > /dev/null

echo -e "${GREEN}✓ Lambda function code updated${NC}"
echo ""

# Get Lambda ARN
LAMBDA_ARN=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionArn'].OutputValue" \
    --output text \
    --region "$REGION")

# Get source bucket name
SOURCE_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='SourceBucketName'].OutputValue" \
    --output text \
    --region "$REGION")

# Configure S3 bucket notification
echo -e "${YELLOW}Configuring S3 bucket notification...${NC}"
aws s3api put-bucket-notification-configuration \
    --bucket "$SOURCE_BUCKET" \
    --notification-configuration "{
        \"LambdaFunctionConfigurations\": [
            {
                \"LambdaFunctionArn\": \"$LAMBDA_ARN\",
                \"Events\": [\"s3:ObjectCreated:*\"]
            }
        ]
    }" \
    --region "$REGION"

echo -e "${GREEN}✓ S3 notification configured${NC}"
echo ""

# Clean up
rm -rf "$TEMP_DIR"

# Get destination bucket name
DESTINATION_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='DestinationBucketName'].OutputValue" \
    --output text \
    --region "$REGION")

# Get stack outputs
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Source Bucket: $SOURCE_BUCKET"
echo "Destination Bucket: $DESTINATION_BUCKET"
echo "Lambda Function: $LAMBDA_FUNCTION_NAME"
echo ""
echo -e "${YELLOW}Important:${NC} Check your email ($EMAIL_ADDRESS) and confirm the SNS subscription!"
echo ""
echo -e "${GREEN}To test the system:${NC}"
echo "  aws s3 cp test-image.jpg s3://$SOURCE_BUCKET/ --region $REGION"
echo ""
echo -e "${GREEN}To view logs:${NC}"
echo "  aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow --region $REGION"
echo ""
echo -e "${GREEN}To delete the stack:${NC}"
echo "  ./cleanup.sh"
echo ""
