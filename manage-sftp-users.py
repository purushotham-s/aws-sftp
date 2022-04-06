#!/usr/bin/python3
"""Script to create SFTP users with API Key"""
import os
import subprocess
import getpass
import crypt
import boto3

aws_client = boto3.client('apigateway', region_name = 'us-east-1')

def add_sftp_user(username, password, sftp_group='sftp-upload'):
    try:
        subprocess.run(['sudo', 'useradd', '-p', password, '-G', sftp_group, username ])
    except Exception as error:
        print(f"Error creating sftp user: {error}")

def generate_api_key(username, api_id, apiusage_plan_id):
    try:
        response = aws_client.create_api_key(
            name = username,
            enabled = True,
            generateDistinctId=True,
            stageKeys=[
                {
                    'restApiId': api_id,
                    'stageName': 'dev'
                },
            ],
        )

        print(f"API KEY: {response['value']}")

        aws_client.create_usage_plan_key(
            usagePlanId = apiusage_plan_id,
            keyId = response['id'],
            keyType ='API_KEY'
        )

    except Exception as error:
        print(f"Error generating API Key: {error}")

def main():
    try:
        username = input("Enter SFTP Username: ")
        ppassword = getpass.getpass()
        password = crypt.crypt(ppassword, "22")
        add_sftp_user(username, password)
        rest_apis = aws_client.get_rest_apis()['items']

        for rest_api in rest_apis:
            if rest_api['name'] == 'sftp_api':
                api_id = rest_api['id']

        usage_plans = aws_client.get_usage_plans()['items']

        for usage_plan in usage_plans:
            if usage_plan['name'] == 'apigw_usage_plan':
                apiusage_plan_id = usage_plan['id']

        generate_api_key(username, api_id, apiusage_plan_id)
    except Exception as error:
        print(error)

if __name__ == '__main__':
    main()
