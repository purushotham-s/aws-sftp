variable "amz-linux-ami-id" {
  description = "Amazon Linux x86 AMI ID"
  default     = "ami-0c02fb55956c7d316"
}

variable "sftp_table" {
  description = "Dynamo DB table for SFTP"
  default     = "sftp_table"
}
