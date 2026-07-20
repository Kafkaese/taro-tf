# VPC for all taro production AWS resources.
resource "aws_vpc" "taro" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "taro-production"
  }
}

# Public subnet holding the Postgres EC2 instance and the Lambda VPC
# attachment. "Public" so the EC2 instance can reach the internet (Docker
# image pulls, OS updates, ECR pulls) without paying for a NAT Gateway;
# inbound access is locked down with security groups instead of relying on
# a private subnet.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.taro.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "taro-production-public"
  }
}

resource "aws_internet_gateway" "taro" {
  vpc_id = aws_vpc.taro.id

  tags = {
    Name = "taro-production"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.taro.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.taro.id
  }

  tags = {
    Name = "taro-production-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
