"""
Local testing script for Lambda function
This script simulates the Lambda execution locally for testing
"""

import json
import os
from lambda_function import lambda_handler

# Mock event from S3
def create_test_event(bucket_name, object_key):
    """Create a mock S3 event for testing"""
    return {
        "Records": [
            {
                "eventVersion": "2.1",
                "eventSource": "aws:s3",
                "awsRegion": "us-east-1",
                "eventTime": "2024-01-01T00:00:00.000Z",
                "eventName": "ObjectCreated:Put",
                "s3": {
                    "s3SchemaVersion": "1.0",
                    "configurationId": "test-config",
                    "bucket": {
                        "name": bucket_name,
                        "arn": f"arn:aws:s3:::{bucket_name}"
                    },
                    "object": {
                        "key": object_key,
                        "size": 1024,
                        "eTag": "test-etag"
                    }
                }
            }
        ]
    }

def test_lambda_locally():
    """Test Lambda function locally"""
    
    # Set environment variables
    os.environ['DESTINATION_BUCKET'] = 'test-destination-bucket'
    os.environ['SNS_TOPIC_ARN'] = 'arn:aws:sns:us-east-1:123456789012:test-topic'
    os.environ['RESIZE_WIDTH'] = '800'
    os.environ['RESIZE_HEIGHT'] = '600'
    
    # Create test event
    test_event = create_test_event(
        bucket_name='test-source-bucket',
        object_key='test-image.jpg'
    )
    
    # Mock context
    class Context:
        function_name = 'test-function'
        memory_limit_in_mb = 512
        invoked_function_arn = 'arn:aws:lambda:us-east-1:123456789012:function:test-function'
        aws_request_id = 'test-request-id'
    
    context = Context()
    
    print("Testing Lambda function locally...")
    print(f"Event: {json.dumps(test_event, indent=2)}")
    print("\n" + "="*50 + "\n")
    
    try:
        # Note: This will fail without actual AWS credentials and S3 bucket
        # It's meant to test the function structure
        response = lambda_handler(test_event, context)
        print(f"Response: {json.dumps(response, indent=2)}")
    except Exception as e:
        print(f"Error (expected without AWS resources): {str(e)}")
        print("\nThis is normal when testing locally without AWS resources.")
        print("Deploy to AWS to test with actual S3 buckets.")

if __name__ == '__main__':
    test_lambda_locally()
