data "template_file" "openapi" {
  template = "${file("./api_spec.yaml")}"

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