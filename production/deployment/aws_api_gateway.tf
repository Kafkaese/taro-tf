# HTTP API rather than the older REST API product - cheaper, simpler, and
# everything needed here (a catch-all proxy to one Lambda) is exactly its
# use case. No custom domain/TLS configured here - Cloudflare proxies to
# the default execute-api endpoint, which already has valid AWS-managed TLS
# (see MIGRATION.md).
resource "aws_apigatewayv2_api" "api" {
  name          = "taro-production-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Catch-all: API Gateway doesn't need to know about FastAPI's individual
# routes, it just forwards everything to Lambda and lets FastAPI's own
# router (via Mangum) sort out the specifics, same as it already does
# behind Uvicorn today.
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Without this, API Gateway gets an authorization error trying to invoke
# the function - IAM role permissions alone don't cover cross-service
# invoke; the Lambda needs an explicit resource-based policy grant naming
# which API Gateway (by ARN) is allowed to call it.
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
