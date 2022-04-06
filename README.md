**Sample SFTP Deployment on AWS**

This is a sample SFTP deployment with upload only configuration. An EC2 instance is used to serve SFTP with S3 as storage backend.
The setup also has a simple lambda automation where files uploaded through SFTP are processed, a lambda function extracts first 20
letters of the 2nd line from the file and stores it in a dynamodb table along with the file name and then discards the uploaded file. 
Another lambda function is defined to fetch stored records from the dynamodb table, this function is triggered through an API which
users can query using a API key.

This setup is defined in Terraform, deploying it will require a user account with permissions to create/delete/update S3, IAM, EC2,
Lambda, API Gateway, Dynamodb resources. 

**Steps to deploy this setup:**

* Install AWS CLI by following the instructions on https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 
* Initialize your aws credentials by running: `$ aws configure`
* Install terraform by following the instructions on - https://learn.hashicorp.com/tutorials/terraform/install-cli
* Clone this git repository by running - `$ git clone https://github.com/purushotham-s/aws-sftp.git`
* Traverse into the aws-sftp directory - `$ cd aws-ftp`
* Initialize terraform by running - `$ terraform init`
* Create the setup by running - `$ terraform apply` # Make sure to properly examine the terraform plan before applying it.
