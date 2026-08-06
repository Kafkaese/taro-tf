# HTTP API rather than the older REST API product - cheaper, simpler, and
# everything needed here (a catch-all proxy to one Lambda) is exactly its
# use case.
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

# --- Custom domain ---
# The default execute-api endpoint validates the incoming Host header
# against its own hostname and rejects mismatches with a 403 - confirmed
# directly: the raw invoke URL returns 200, api.arms-tracker.app through
# Cloudflare returned 403, with nothing else differing between the two
# requests. It isn't designed to sit behind an arbitrary custom domain
# without this - a Custom Domain Name object backed by an ACM cert, which
# (unlike the raw endpoint) is built to accept the real hostname directly.

resource "aws_acm_certificate" "api" {
  domain_name       = "api.arms-tracker.app"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Unproxied (grey-cloud) deliberately - ACM's validation check does a plain
# DNS lookup expecting the literal CNAME target it issued; a proxied record
# would resolve to Cloudflare's own IPs instead and validation would never
# complete.
resource "cloudflare_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name  = trimsuffix(trimsuffix(dvo.resource_record_name, "."), ".arms-tracker.app")
      type  = dvo.resource_record_type
      value = trimsuffix(dvo.resource_record_value, ".")
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.value
  proxied = false
  ttl     = 60
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in cloudflare_record.api_cert_validation : record.hostname]
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = "api.arms-tracker.app"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.id
}
