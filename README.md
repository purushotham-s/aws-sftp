**Sample SFTP Deployment on AWS**

This is a sample SFTP deployment with upload only configuration. An EC2 instance is used to serve SFTP with S3 as storage backend.
The setup also has a simple lambda automation where files uploaded through SFTP are processed, a lambda function extracts first 20
letters of the 2nd line from the file and stores it in a dynamodb table along with the file name and then discards the uploaded file. 
Another lambda function is defined to fetch stored records from the dynamodb table, this function is triggered through an API which
users can query using a API key. A simple Architecture diagram for this project is given below:

![alt text](https://github.com/purushotham-s/aws-sftp/blob/main/sftp_arch.JPG?raw=true)

**Steps to deploy this setup:**

This project is defined in Terraform, deploying it will require a user account with permissions to create/delete/update S3, IAM, EC2,
Lambda, API Gateway, Dynamodb resources. To simplify things the management instance and the SFTP instance are merged. A directory 
service can be configured instead of using PAM authentication and then managed from a seperated EC2 instance using relevant tools.

* Install AWS CLI by following the instructions on https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 
* Initialize your aws credentials by running: `$ aws configure`
* Install terraform by following the instructions on - https://learn.hashicorp.com/tutorials/terraform/install-cli
* Clone this git repository by running - `$ git clone https://github.com/purushotham-s/aws-sftp.git`
* Traverse into the aws-sftp directory - `$ cd aws-sftp`
* Initialize terraform by running - `$ terraform init`
* Create the setup by running - `$ terraform apply` # Make sure to properly examine the terraform plan before applying it.
* After the terraform state is applied successfully a SSH key to the EC2 instance will be created on the working directory. It can be used to login to the SFTP EC2 instance, before logging-in we will have to change the permission of the ssh key by running - `$ chmod 400 sftp-key.pem`
* Run - `$ terraform output` to display IP address of the SFTP EC2 instance and the API URL. To login to the EC2 instance, run - `ssh -i sftp-key.pem ec2-user@<instance-ip>`
* Once logged into the SFTP instance, we can create sftp users and API Keys by running - `$ manage-sftp-users`, the script will prompt for username and password for the new sftp user, provides a API key and the API URL after the user is created.
* To upload files to the sftp server with the newly create SFTP user, run - `$ sftp <sftp-user>@<instance-ip>` and once logged in, run `$ put <file_name> incoming/`.
* To query the API run - `$ curl -X GET https:<API_URL>?file_name=<uploaded_filename> -H "x-api-key: <API_KEY>"`
* To destroy the environment, run - `$ terraform destroy` 

Example deployment:

```
$ git clone https://github.com/purushotham-s/aws-sftp.git
Cloning into 'aws-sftp'...
remote: Enumerating objects: 60, done.
remote: Counting objects: 100% (60/60), done.
remote: Compressing objects: 100% (43/43), done.
remote: Total 60 (delta 30), reused 39 (delta 16), pack-reused 0
Receiving objects: 100% (60/60), 57.90 KiB | 1.75 MiB/s, done.
Resolving deltas: 100% (30/30), done.

$ cd aws-sftp/

$ terraform init

$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
symbols:
  + create

Terraform will perform the following actions:

  # aws_api_gateway_api_key.apigw_dev_key will be created
  + resource "aws_api_gateway_api_key" "apigw_dev_key" {
      + arn               = (known after apply)
      + created_date      = (known after apply)
      + description       = "Managed by Terraform"
      + enabled           = true
      + id                = (known after apply)
.................
.................
Plan: 31 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + api_url            = (known after apply)
  + instance_public_ip = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes  
.................
.................
Apply complete! Resources: 31 added, 0 changed, 0 destroyed.

Outputs:

api_url = "https://<API_URL>/dev/sftp-data" # Redacted
instance_public_ip = "<EC2_INSTANCE_IP>"    # Redacted 

$ chmod 400 sftp-key.pem

$ ssh -i sftp-key.pem ec2-user@<EC2_INSTANCE_IP>
[ec2-user@ip ~]$ manage-sftp-users
Enter SFTP Username: sftp-user1
Password:
API KEY: <REDACTED>
API URL: https://<REDACTED>.execute-api.us-east-1.amazonaws.com/dev/sftp-data

[user-client@ip ~]$ echo -e "Hello\nHello there! Foo......" > test.txt

[user-client@ip ~]$ sftp sftp-user1@<EC2_INSTANCE_IP>
password:
sftp> put test.txt incoming
Uploading test.txt to /incoming/test.txt

[user-client@ip ~]$ curl -X GET https://<REDACTED>.execute-api.us-east-1.amazonaws.com/dev/sftp-data?file_name='test.txt' -H 'x-api-key: <REDACTED>'
Hello there! Foo....

```
