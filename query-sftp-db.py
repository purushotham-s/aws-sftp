"""This function is triggered by a API query, it takes file_name as input
and returns the 20 character contents of the file"""

import json
import boto3

# Initialize Dynamodb client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('sftp_table')

def lambda_handler(event, context):
    """Fetches and returns file content based on queryStringParameters input"""
    try:
        response = table.get_item(
            Key={
               'FileName': event['queryStringParameters']['file_name']
            })
        content = response['Item']['FileContent']
        return {
            'statusCode': 200,
            'body' : content
        }
    except Exception as err:
        print(err)
