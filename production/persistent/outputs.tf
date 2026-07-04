output "vpc_id" {
  value = aws_vpc.taro.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.taro.repository_url
}
