resource "aws_api_gateway_rest_api" "fortunes" {
  name = "fortunes-revolgy-homework"
}

resource "aws_api_gateway_resource" "fortunes" {
  rest_api_id = aws_api_gateway_rest_api.fortunes.id
  parent_id   = aws_api_gateway_rest_api.fortunes.root_resource_id
  path_part   = "fortune"
}

resource "aws_api_gateway_method" "fortunes" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes.id
  resource_id   = aws_api_gateway_resource.fortunes.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_fortune_lambda" {
  rest_api_id = aws_api_gateway_rest_api.fortunes.id
  resource_id = aws_api_gateway_resource.fortunes.id
  http_method = aws_api_gateway_method.fortunes.http_method
  # TODO tohle muzu dostat lookupem
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_fortune.invoke_arn
}

resource "aws_api_gateway_deployment" "fortunes_api_production" {
  rest_api_id = aws_api_gateway_rest_api.fortunes.id
  stage_name  = "prod"

  depends_on = [aws_api_gateway_integration.get_fortune_lambda]
}
