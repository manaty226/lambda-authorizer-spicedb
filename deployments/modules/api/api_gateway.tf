data "template_file" "openapi" {
  template = "${file("./modules/api/api_spec.yaml")}"

  vars = {
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name = "sample_api"
  body = data.template_file.openapi.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  lifecycle {
    ignore_changes = [
      policy
    ]
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_rest_api.api]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"

  triggers = {
    redeployment = "v0.1"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_api_gateway_authorizer" "demo" {
  name                   = "spicedb-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "../lambda/authorizer-spicedb/src"
  output_path = "./modules/lambda/authorizer.zip"
}

resource "aws_lambda_function" "authorizer" {
  filename      = "${data.archive_file.function_zip.output_path}"
  function_name = "api_gateway_authorizer"
  role          = aws_iam_role.lambda.arn
  handler       = "index.lambda_handler"

  source_code_hash = "${data.archive_file.function_zip.output_base64sha256}"
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = aws_iam_role.invocation_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.authorizer.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda" {
  name = "demo-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
