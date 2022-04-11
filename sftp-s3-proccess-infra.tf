resource "aws_dynamodb_table" "sftp_table" {
  name           = var.sftp_table
  billing_mode   = "PROVISIONED"
  write_capacity = 5
  read_capacity  = 5
  hash_key       = "FileName"
  attribute {
    name = "FileName"
    type = "S"
  }
}

resource "aws_iam_role" "s3_process_lambda_iam" {
  name = "s3_process_lambda_iam"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "s3_process_lambda_access_policy" {
  name = "s3_proccess_lambda_access_policy"
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
        Resource = "arn:aws:s3:::${aws_s3_bucket.sftp_bucket.id}"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ],
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.sftp_bucket.id}/*"
      },
      {
        Action = [
          "dynamodb:Update*",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
        ],
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:*:*:table/${var.sftp_table}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.s3_process_lambda_iam.name
  policy_arn = aws_iam_policy.s3_process_lambda_access_policy.arn
}

resource "aws_lambda_permission" "allow_bucket_exec" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proccess_s3_uploads.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.sftp_bucket.arn
}

data "archive_file" "process_s3_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/process-s3-uploads.py"
  output_path = "${path.module}/process-s3-uploads.zip"
}

resource "aws_lambda_function" "proccess_s3_uploads" {
  function_name    = "process_s3_uploads"
  role             = aws_iam_role.s3_process_lambda_iam.arn
  runtime          = "python3.9"
  handler          = "process-s3-uploads.lambda_handler"
  filename         = "${path.module}/process-s3-uploads.zip"
  timeout          = 15
  source_code_hash = data.archive_file.process_s3_lambda_zip.output_base64sha256
}

resource "aws_s3_bucket_notification" "s3_process_lambda_trigger" {
  bucket = aws_s3_bucket.sftp_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.proccess_s3_uploads.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_bucket_exec]
}
