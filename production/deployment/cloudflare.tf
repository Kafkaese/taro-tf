# Placeholder only - the page rule below redirects every apex request to
# www before Cloudflare ever tries to actually reach this. 192.0.2.1 is a
# reserved documentation-only address (RFC 5737), never a real destination;
# it just needs to exist so there's a valid record to proxy. A real CNAME
# to GCS doesn't work for the apex anyway once the bucket is named to match
# www specifically (see cloudflare_record.www below) - GCS's classic
# same-name-bucket hosting needs an exact bucket-name-to-Host-header match,
# and a bucket can only be named one thing.
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  type    = "A"
  content = "192.0.2.1"
  proxied = true
}

resource "cloudflare_page_rule" "root_redirect" {
  zone_id  = var.cloudflare_zone_id
  target   = "arms-tracker.app/*"
  priority = 1

  actions {
    forwarding_url {
      url         = "https://www.arms-tracker.app/$1"
      status_code = 301
    }
  }
}

# The frontend bucket is named exactly "www.arms-tracker.app" specifically
# so GCS's classic same-name-bucket hosting applies: every such bucket
# shares this one fixed CNAME target, and GCS identifies which bucket to
# serve by matching the incoming Host header (which Cloudflare preserves
# from the original request, not the CNAME target) against the bucket
# name - rather than the virtual-hosted-style <bucket>.storage.googleapis.com
# addressing, which breaks once a proxy sits in front and doesn't forward
# a matching Host header. See MIGRATION.md for the full story on why.
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  type    = "CNAME"
  content = "c.storage.googleapis.com"
  proxied = true
}

# Same classic same-name-bucket pattern - dev.arms-tracker.app is its own
# bucket, named to match, sharing the same fixed CNAME target as www.
resource "cloudflare_record" "dev" {
  zone_id = var.cloudflare_zone_id
  name    = "dev"
  type    = "CNAME"
  content = "c.storage.googleapis.com"
  proxied = true
}

# Points at the custom domain's regional target, not the raw execute-api
# endpoint - the raw endpoint validates the Host header against its own
# hostname and 403s on a mismatch, which is exactly what broke this before
# Cloudflare (preserving the original Host header) sat in front of it. The
# custom domain object (aws_apigatewayv2_domain_name, in aws_api_gateway.tf)
# is what actually accepts api.arms-tracker.app correctly.
resource "cloudflare_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  type    = "CNAME"
  content = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
  proxied = true
}

# Full (strict) works for both origins here - the GCS bucket's website
# endpoint (*.storage.googleapis.com) carries a real Google Trust Services
# wildcard cert (verified directly via openssl rather than assumed), and
# API Gateway's regional custom-domain target presents the ACM cert we
# associated with it - that SNI-based cert serving is the actual point of
# API Gateway custom domains, unlike the raw execute-api endpoint's
# Host-header behavior, which wasn't designed to sit behind a proxy at all.
resource "cloudflare_zone_settings_override" "this" {
  zone_id = var.cloudflare_zone_id

  settings {
    ssl               = "strict"
    always_use_https  = "on"
  }
}
