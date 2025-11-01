import json
import boto3
import os
from PIL import Image
from io import BytesIO

# Initialize AWS clients
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')

# Environment variables
DESTINATION_BUCKET = os.environ.get('DESTINATION_BUCKET')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
RESIZE_WIDTH = int(os.environ.get('RESIZE_WIDTH', '800'))
RESIZE_HEIGHT = int(os.environ.get('RESIZE_HEIGHT', '600'))

def lambda_handler(event, context):
    """
    Lambda function to resize images uploaded to S3
    """
    try:
        # Get the S3 event details
        for record in event['Records']:
            # Extract bucket and object key
            source_bucket = record['s3']['bucket']['name']
            source_key = record['s3']['object']['key']
            
            print(f"Processing image: {source_key} from bucket: {source_bucket}")
            
            # Skip if file is not an image
            if not is_image_file(source_key):
                print(f"Skipping non-image file: {source_key}")
                continue
            
            # Download the image from S3
            response = s3_client.get_object(Bucket=source_bucket, Key=source_key)
            image_content = response['Body'].read()
            
            # Open and resize the image
            image = Image.open(BytesIO(image_content))
            print(f"Original image size: {image.size}")
            
            # Resize the image while maintaining aspect ratio
            resized_image = resize_image(image, RESIZE_WIDTH, RESIZE_HEIGHT)
            print(f"Resized image size: {resized_image.size}")
            
            # Save resized image to buffer
            buffer = BytesIO()
            image_format = image.format if image.format else 'JPEG'
            resized_image.save(buffer, format=image_format, quality=85)
            buffer.seek(0)
            
            # Upload resized image to destination bucket
            destination_key = f"resized/{source_key}"
            s3_client.put_object(
                Bucket=DESTINATION_BUCKET,
                Key=destination_key,
                Body=buffer,
                ContentType=response['ContentType']
            )
            
            print(f"Uploaded resized image to: {DESTINATION_BUCKET}/{destination_key}")
            
            # Send SNS notification
            send_notification(source_bucket, source_key, destination_key, 
                            image.size, resized_image.size)
            
        return {
            'statusCode': 200,
            'body': json.dumps('Image processing completed successfully!')
        }
        
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        
        # Send failure notification
        send_failure_notification(str(e))
        
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing image: {str(e)}')
        }

def is_image_file(filename):
    """
    Check if the file is an image based on extension
    """
    image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp']
    return any(filename.lower().endswith(ext) for ext in image_extensions)

def resize_image(image, max_width, max_height):
    """
    Resize image while maintaining aspect ratio
    """
    # Convert RGBA to RGB if necessary
    if image.mode == 'RGBA':
        background = Image.new('RGB', image.size, (255, 255, 255))
        background.paste(image, mask=image.split()[3])
        image = background
    elif image.mode not in ('RGB', 'L'):
        image = image.convert('RGB')
    
    # Calculate new dimensions maintaining aspect ratio
    original_width, original_height = image.size
    aspect_ratio = original_width / original_height
    
    if original_width > max_width or original_height > max_height:
        if aspect_ratio > 1:
            # Landscape
            new_width = max_width
            new_height = int(max_width / aspect_ratio)
        else:
            # Portrait
            new_height = max_height
            new_width = int(max_height * aspect_ratio)
        
        return image.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    return image

def send_notification(source_bucket, source_key, destination_key, 
                      original_size, resized_size):
    """
    Send SNS notification upon successful processing
    """
    try:
        message = {
            'status': 'SUCCESS',
            'source_bucket': source_bucket,
            'source_key': source_key,
            'destination_bucket': DESTINATION_BUCKET,
            'destination_key': destination_key,
            'original_size': f"{original_size[0]}x{original_size[1]}",
            'resized_size': f"{resized_size[0]}x{resized_size[1]}"
        }
        
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject='Image Processing Success',
            Message=json.dumps(message, indent=2)
        )
        
        print("SNS notification sent successfully")
        
    except Exception as e:
        print(f"Error sending SNS notification: {str(e)}")

def send_failure_notification(error_message):
    """
    Send SNS notification upon processing failure
    """
    try:
        message = {
            'status': 'FAILURE',
            'error': error_message
        }
        
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject='Image Processing Failed',
            Message=json.dumps(message, indent=2)
        )
        
        print("Failure notification sent successfully")
        
    except Exception as e:
        print(f"Error sending failure notification: {str(e)}")
