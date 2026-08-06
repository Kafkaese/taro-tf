output "vpc_id" {
  value = aws_vpc.taro.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.taro.repository_url
}

output "pipeline_data_bucket" {
  value = aws_s3_bucket.pipeline_data.bucket
}

output "github_actions_pipeline_build_role_arn" {
  value = aws_iam_role.github_actions_pipeline_build.arn
}

output "github_actions_api_build_role_arn" {
  value = aws_iam_role.github_actions_api_build.arn
}

output "frontend_bucket_name" {
  value = google_storage_bucket.frontend.name
}

# The bucket is named to exactly match its domain (www.arms-tracker.app),
# so it uses GCS's classic same-name-bucket hosting: every such bucket
# shares this one fixed CNAME target, and GCS tells them apart by matching
# the (Cloudflare-preserved) Host header against the bucket name - not by
# which storage.googleapis.com subdomain was hit, the way a virtual-hosted-
# style URL would work. Purely informational; nothing else in this config
# consumes it.
output "frontend_website_endpoint" {
  value = "http://c.storage.googleapis.com"
}

# Consumed by deployment/ (via terraform_remote_state) to wire the Lambda
# into the same VPC/subnet and let it reach Postgres privately.
output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "postgres_private_ip" {
  value = aws_instance.postgres.private_ip
}

# Just the parameter's path, not its value - deployment/'s Lambda fetches
# the actual password itself at runtime via its own IAM-scoped read, the
# same pattern as the EC2 instance's boot script. Nothing sensitive here.
output "postgres_password_ssm_parameter_name" {
  value = aws_ssm_parameter.postgres_password.name
}

output "postgres_user" {
  value     = var.postgres_user
  sensitive = true
}

# The Lambda passes this directly as a plain environment variable rather
# than fetching it from SSM at runtime - it's VPC-attached with no NAT
# Gateway and no VPC endpoint for SSM, so an in-VPC SSM call has no route
# out and just hangs until Lambda's init-phase timeout kills it. Accepted
# tradeoff for now: broader exposure (visible via lambda:GetFunctionConfiguration,
# not just this function's own role) in exchange for not paying for a VPC
# endpoint (~$7-8/mo) or a NAT Gateway (~$32+/mo). See MIGRATION.md.
output "postgres_password" {
  value     = random_password.postgres.result
  sensitive = true
}

output "postgres_database" {
  value = var.postgres_database
}

output "frontend_deploy_workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github_actions.name
}

output "frontend_deploy_service_account_email" {
  value = google_service_account.frontend_deploy.email
}
