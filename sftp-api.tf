resource "aws_api_gateway_rest_api" "sftp_api" {
  name = "sftp_api"
  depends_on = [
    aws_lambda_function.query_sftp_db
  ]
}

resource "aws_iam_role" "sftp_query_lambda_role" {
  name = "sftp_query_lambda_role"
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

resource "aws_iam_policy" "sftp_query_lambda_policy" {
  name = "sftp_query_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:List*",
          "dynamodb:Describe*"
        ],
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:*:*:table/${var.sftp_table}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sftp_query_lambda_policy_attach" {
  role       = aws_iam_role.sftp_query_lambda_role.name
  policy_arn = aws_iam_policy.sftp_query_lambda_policy.arn
}

data "archive_file" "query_sftp_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/query-sftp-db.py"
  output_path = "${path.module}/query-sftp-db.zip"
}

resource "aws_lambda_function" "query_sftp_db" {
  function_name    = "query_sftp_db"
  role             = aws_iam_role.sftp_query_lambda_role.arn
  runtime          = "python3.9"
  handler          = "query-sftp-db.lambda_handler"
  filename         = "query-sftp-db.zip"
  timeout          = 15
  source_code_hash = data.archive_file.query_sftp_lambda_zip.output_base64sha256
}

resource "aws_api_gateway_resource" "sftp_api_gw" {
  path_part   = "sftp-data"
  parent_id   = aws_api_gateway_rest_api.sftp_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.sftp_api.id
}

resource "aws_api_gateway_stage" "dev_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.sftp_api.id
  deployment_id = aws_api_gateway_deployment.sftp_api_gw_get.id
}

resource "aws_api_gateway_usage_plan" "apigw_usage_plan" {
  name = "apigw_usage_plan"
  api_stages {
    api_id = aws_api_gateway_rest_api.sftp_api.id
    stage  = aws_api_gateway_stage.dev_stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "apigw_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.apigw_dev_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.apigw_usage_plan.id
}

resource "aws_api_gateway_api_key" "apigw_dev_key" {
  name = "dev_key"
}

resource "aws_api_gateway_method" "query_sftp_get" {
  rest_api_id      = aws_api_gateway_rest_api.sftp_api.id
  resource_id      = aws_api_gateway_resource.sftp_api_gw.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query_sftp_db.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sftp_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_integration" "lambda_integration_get" {
  depends_on = [
    aws_lambda_permission.apigw
  ]
  rest_api_id             = aws_api_gateway_rest_api.sftp_api.id
  resource_id             = aws_api_gateway_method.query_sftp_get.resource_id
  http_method             = aws_api_gateway_method.query_sftp_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.query_sftp_db.invoke_arn
}

resource "aws_api_gateway_deployment" "sftp_api_gw_get" {
  depends_on  = [aws_api_gateway_integration.lambda_integration_get, aws_api_gateway_method.query_sftp_get]
  rest_api_id = aws_api_gateway_rest_api.sftp_api.id
}
