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
