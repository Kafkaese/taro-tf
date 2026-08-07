output "api_invoke_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "api_dev_invoke_url" {
  value = aws_apigatewayv2_stage.api_dev_default.invoke_url
}
