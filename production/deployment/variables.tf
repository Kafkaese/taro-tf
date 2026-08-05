variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region for all taro production resources."
}

variable "cloudflare_zone_id" {
  description = "Zone ID for arms-tracker.app, from the Cloudflare dashboard's Overview page (right sidebar, under API). No default - set via TF_VAR_cloudflare_zone_id or a gitignored terraform.tfvars."
}
