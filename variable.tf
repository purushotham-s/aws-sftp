variable "sftp_bucket" {
  description = "SFTP Backend S3 Bucket"
  default = "sftp-srv-bucket-1"
}

variable "amz-linux-ami-id" {
  description = "Amazon Linux x86 AMI ID"
  default = "ami-0c02fb55956c7d316"
}

variable "sftp_table" {
  description = "Dynamo DB table for SFTP"
  default     = "sftp_table"
}
