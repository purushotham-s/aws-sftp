output "instance_public_ip" {
  description = "SFTP EC2 instance Public IP address"
  value       = aws_instance.sftp_ec2_instance.public_ip
}

output "api_url" {
  description = "API URL"
  value       = "https://${aws_api_gateway_rest_api.sftp_api.id}.execute-api.us-east-1.amazonaws.com/dev/sftp-data"
}

output "sftp_s3_bucket" {
  description = "SFTP S3 bucket name"
  value       = aws_s3_bucket.sftp_bucket.id
}
