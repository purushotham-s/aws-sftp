Sample SFTP Deployment on AWS 

This is a sample SFTP deployment with upload only configuration. An EC2 instance is used to serve SFTP with S3 as storage backend.
The setup also has a simple lambda automation where files uploaded through SFTP are proccessed, a lambda function extracts first 20
letters of the 2nd line from the file and stores it in a dynamodb table along with the file name and then discards the uploaded file. 
Another lambda function is defined to fetch stored records from the dynamodb table, this function is trigged through an API which
users can query using a API key.

This setup is defined in Terraform, deploying it will require a user account with permissions to create/delete/update S3, IAM, EC2,
Lambda, API Gateway, Dynamodb resources. 
