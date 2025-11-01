#!/bin/bash

# Cleanup script for Serverless Image Processing System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="image-processor"
STACK_NAME="${PROJECT_NAME}-stack"
REGION="us-east-1"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Serverless Image Processing Cleanup${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Get AWS region
read -p "Enter AWS region (default: us-east-1): " INPUT_REGION
REGION=${INPUT_REGION:-$REGION}

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
    echo -e "${RED}Stack '$STACK_NAME' not found in region $REGION${NC}"
    exit 1
fi

# Get bucket names
SOURCE_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='SourceBucketName'].OutputValue" \
    --output text \
    --region "$REGION")

DESTINATION_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='DestinationBucketName'].OutputValue" \
    --output text \
    --region "$REGION")

echo "Stack: $STACK_NAME"
echo "Source Bucket: $SOURCE_BUCKET"
echo "Destination Bucket: $DESTINATION_BUCKET"
echo ""

read -p "Are you sure you want to delete all resources? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

# Empty S3 buckets
echo ""
echo -e "${YELLOW}Emptying S3 buckets...${NC}"

if [ ! -z "$SOURCE_BUCKET" ]; then
    echo "Emptying $SOURCE_BUCKET..."
    aws s3 rm "s3://$SOURCE_BUCKET" --recursive --region "$REGION" 2>/dev/null || true
    echo -e "${GREEN}✓ Source bucket emptied${NC}"
fi

if [ ! -z "$DESTINATION_BUCKET" ]; then
    echo "Emptying $DESTINATION_BUCKET..."
    aws s3 rm "s3://$DESTINATION_BUCKET" --recursive --region "$REGION" 2>/dev/null || true
    echo -e "${GREEN}✓ Destination bucket emptied${NC}"
fi

# Delete CloudFormation stack
echo ""
echo -e "${YELLOW}Deleting CloudFormation stack...${NC}"
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION"

echo -e "${GREEN}✓ Stack deleted successfully${NC}"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
