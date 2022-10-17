variable subnet_id {}
variable security_group_id {}
variable alb_host {}
variable acm_certificate_arn {}

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
  source_dir  = "../lambda/authorizer-spicedb"
  output_path = "./modules/lambda/authorizer.zip"
}

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "../lambda/layer"
  output_path = "./modules/lambda/layer.zip"
}

resource "aws_lambda_layer_version" "authzed" {
  filename   = "${data.archive_file.layer_zip.output_path}"
  layer_name = "authzed"
  source_code_hash = "${data.archive_file.layer_zip.output_base64sha256}"
  compatible_runtimes = ["python3.7"]
}

resource "aws_lambda_function" "authorizer" {
  filename      = "${data.archive_file.function_zip.output_path}"
  function_name = "api_gateway_authorizer"
  role          = aws_iam_role.lambda.arn
  handler       = "src.index.lambda_handler"
  runtime       = "python3.7"
  timeout       = 20
  source_code_hash = "${data.archive_file.function_zip.output_base64sha256}"

  environment {
    variables = {
      SPICE_DB_HOST = var.alb_host
      SPICE_DB_PORT = 443
      ACM_CERT_ARN  = var.acm_certificate_arn
    }
  }

  layers = ["${aws_lambda_layer_version.authzed.arn}"]

  
  vpc_config {
    subnet_ids = [var.subnet_id]
    security_group_ids = [var.security_group_id]
  }
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
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
  
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action":
        "sts:AssumeRole",
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

resource "aws_iam_role_policy" "acm_policy" {
  name = "default"
  role = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "acm:GetCertificate",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


