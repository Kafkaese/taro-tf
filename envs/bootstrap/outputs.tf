output "state_bucket_name" {
  value       = aws_s3_bucket.tfstate.bucket
  description = "Copy this into the backend \"s3\" block of persistent/providers.tf and deployment/providers.tf."
}

output "lock_table_name" {
  value       = aws_dynamodb_table.tf_lock.name
  description = "Copy this into the backend \"s3\" block of persistent/providers.tf and deployment/providers.tf (dynamodb_table field)."
}

output "aws_region" {
  value       = var.aws_region
  description = "Copy this into the backend \"s3\" block of persistent/providers.tf and deployment/providers.tf (region field)."
}
