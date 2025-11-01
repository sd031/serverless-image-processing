#!/bin/bash

# Test script to upload images to the source bucket

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Image Upload Test Script${NC}"
echo ""

# Get stack name
STACK_NAME="image-processor-stack"
REGION="us-east-1"

# Get region from user
read -p "Enter AWS region (default: us-east-1): " INPUT_REGION
REGION=${INPUT_REGION:-$REGION}

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
    echo -e "${RED}Stack '$STACK_NAME' not found. Please deploy first using ./deploy.sh${NC}"
    exit 1
fi

# Get source bucket name
SOURCE_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='SourceBucketName'].OutputValue" \
    --output text \
    --region "$REGION")

echo "Source Bucket: $SOURCE_BUCKET"
echo ""

# Check if image file is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: ./test_upload.sh <image-file>${NC}"
    echo ""
    echo "Example:"
    echo "  ./test_upload.sh my-photo.jpg"
    echo ""
    echo "If you don't have a test image, you can download one:"
    echo "  curl -o test-image.jpg https://picsum.photos/1920/1080"
    exit 1
fi

IMAGE_FILE="$1"

# Check if file exists
if [ ! -f "$IMAGE_FILE" ]; then
    echo -e "${RED}Error: File '$IMAGE_FILE' not found${NC}"
    exit 1
fi

# Upload image
echo -e "${YELLOW}Uploading $IMAGE_FILE to $SOURCE_BUCKET...${NC}"
aws s3 cp "$IMAGE_FILE" "s3://$SOURCE_BUCKET/" --region "$REGION"

echo -e "${GREEN}✓ Upload complete!${NC}"
echo ""
echo "Processing started. You should receive an email notification shortly."
echo ""
echo -e "${GREEN}To view logs:${NC}"
echo "  aws logs tail /aws/lambda/image-processor-function --follow --region $REGION"
echo ""
echo -e "${GREEN}To check processed image:${NC}"
DEST_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='DestinationBucketName'].OutputValue" \
    --output text \
    --region "$REGION")
echo "  aws s3 ls s3://$DEST_BUCKET/resized/ --region $REGION"
echo ""
