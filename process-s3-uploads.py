"""This function gets triggered when new object is added to S3 bucket. It processes
the upload files and then deletes them from the bucket. Processed data is stored on 
a dynamodb table"""

import boto3

# Initialize S3 and Dynamodb client
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('sftp_table')

def lambda_handler(event, context):
    """Fetches uploaded file and checks if there is 20 characters in 2nd 
    line of the file and extracts the characters and pushes the extracted
    contents to a dynamodb table. Files are deleted regardless whether they
    have content or not
    """
    try:
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_file_name = event['Records'][0]['s3']['object']['key']
        response = s3.get_object(Bucket=bucket_name, Key=s3_file_name)
        data = response['Body'].read().decode('utf-8')
    
        if len(data.split('\n')) >= 2:
            if len(data.split('\n')[1]) >= 20:
                file_content = data.split('\n')[1][:20]
                d = {"FileName": s3_file_name, "FileContent": file_content}
                table.put_item(Item = d)
        
        s3.delete_object(Bucket=bucket_name, Key=s3_file_name)
    except Exception as err:
        print(err)
