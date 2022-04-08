**Sample SFTP Deployment on AWS**

This is a sample SFTP deployment with upload only configuration. An EC2 instance is used to serve SFTP with S3 as storage backend.
The setup also has a simple lambda automation where files uploaded through SFTP are processed, a lambda function extracts first 20
letters of the 2nd line from the file and stores it in a dynamodb table along with the file name and then discards the uploaded file. 
Another lambda function is defined to fetch stored records from the dynamodb table, this function is triggered through an API which
users can query using a API key. A simple Architecture diagram for this project is given below:

![alt text](https://github.com/purushotham-s/aws-sftp/blob/main/sftp_arch.JPG?raw=true)

**Steps to deploy this setup:**

This project is defined in Terraform, deploying it will require a user account with permissions to create/delete/update S3, IAM, EC2,
Lambda, API Gateway, Dynamodb resources. 

* Install AWS CLI by following the instructions on https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 
* Initialize your aws credentials by running: `$ aws configure`
* Install terraform by following the instructions on - https://learn.hashicorp.com/tutorials/terraform/install-cli
* Clone this git repository by running - `$ git clone https://github.com/purushotham-s/aws-sftp.git`
* Traverse into the aws-sftp directory - `$ cd aws-ftp`
* Initialize terraform by running - `$ terraform init`
* Create the setup by running - `$ terraform apply` # Make sure to properly examine the terraform plan before applying it.
* After the terraform state is applied successfully a SSH key to the EC2 instance will be created on the working directory. It can be used to login to the SFTP EC2 instance, before logging-in we will have to change the permission of the ssh key by running - `$ chmod 400 sftp-key.pem`
* Once logged into the SFTP instance, we can create sftp users and API Keys by running - `$ manage-sftp-users`, the script will prompt for username and password for the new sftp user, provides a API key and the API URL after the user is created.
* To upload files to the sftp server, run - `$ sftp sftp-user1@<instance-ip>` and once logged in, run `$ put <file_name> incoming/`.
* To query the API run - `$ curl -X GET https:<API_URL>?file_name=<uploaded_filename> -H "x-api-key: <API_KEY>"`

