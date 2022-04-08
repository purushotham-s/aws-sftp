
resource "aws_s3_bucket" "sftp_bucket" {
  bucket = var.sftp_bucket
}

resource "aws_s3_bucket_acl" "sftp_bucket" {
  bucket = aws_s3_bucket.sftp_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2_s3_access_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "sftp_bucket_access_policy" {
  name = "sftp_bucket_access_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets",
        ],
        Effect   = "Allow",
        Resource = "arn:aws:s3:::*"
      },
      {
        Action = [
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = "arn:aws:s3:::${var.sftp_bucket}"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ],
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.sftp_bucket}/*"
      },
      {
        Action = [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:PUT"
        ],
        Effect = "Allow"
        Resource = [ 
          "arn:aws:apigateway:*::/restapis",
          "arn:aws:apigateway:*::/usageplans",
          "arn:aws:apigateway:*::/usageplans/*",
          "arn:aws:apigateway:*::/apikeys"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.sftp_bucket_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

resource "tls_private_key" "priv_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "sftp-key"
  public_key = tls_private_key.priv_key.public_key_openssh
  provisioner "local-exec" {
    command = "echo '${tls_private_key.priv_key.private_key_pem}' > ./sftp-key.pem"
  }
}

resource "aws_security_group" "ssh-sg" {
  name = "ssh-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "sftp_ec2_instance" {
  ami                    = var.amz-linux-ami-id
  instance_type          = "t2.micro"
  key_name               = "sftp-key"
  vpc_security_group_ids = [aws_security_group.ssh-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_profile.name
  user_data              = file("init-script.sh")
}
