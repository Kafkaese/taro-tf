# Root and www both point at the GCS bucket's website endpoint. A CNAME at
# the zone apex isn't valid plain DNS (the apex must carry SOA/NS records),
# but Cloudflare "flattens" it transparently for proxied records, so this
# works despite the underlying restriction.
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  type    = "CNAME"
  content = "${data.terraform_remote_state.persistent.outputs.frontend_bucket_name}.storage.googleapis.com"
  proxied = true
}

resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  type    = "CNAME"
  content = "${data.terraform_remote_state.persistent.outputs.frontend_bucket_name}.storage.googleapis.com"
  proxied = true
}

# api_endpoint includes the https:// scheme; a CNAME's content is just the
# bare hostname.
resource "cloudflare_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  type    = "CNAME"
  content = trimprefix(aws_apigatewayv2_api.api.api_endpoint, "https://")
  proxied = true
}

# Full (strict) works for both origins here - the GCS bucket's website
# endpoint (*.storage.googleapis.com) carries a real Google Trust Services
# wildcard cert, and API Gateway's default endpoint carries a real
# AWS-managed cert, so there's no need to fall back to a weaker mode for
# either leg (verified the GCS cert directly via openssl rather than
# assuming it).
resource "cloudflare_zone_settings_override" "this" {
  zone_id = var.cloudflare_zone_id

  settings {
    ssl               = "strict"
    always_use_https  = "on"
  }
}
