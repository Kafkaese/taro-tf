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

# Security group for the EC2 instance running Postgres. Deliberately created
# with no inline ingress/egress blocks — rules are managed as separate
# aws_vpc_security_group_*_rule resources below, which avoids the classic
# gotcha where an inline `egress {}` block (or its absence) fights with the
# "allow all outbound" rule AWS creates by default on every new group.
resource "aws_security_group" "postgres" {
  name        = "taro-production-postgres"
  description = "Postgres EC2 instance"
  vpc_id      = aws_vpc.taro.id

  tags = {
    Name = "taro-production-postgres"
  }
}

# Security group for the Lambda function's VPC attachment.
resource "aws_security_group" "lambda" {
  name        = "taro-production-lambda"
  description = "Lambda VPC attachment"
  vpc_id      = aws_vpc.taro.id

  tags = {
    Name = "taro-production-lambda"
  }
}

# Only Lambda can reach Postgres, and only on 5432.
resource "aws_vpc_security_group_ingress_rule" "postgres_from_lambda" {
  security_group_id            = aws_security_group.postgres.id
  referenced_security_group_id = aws_security_group.lambda.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Postgres from Lambda"
}

# Everything this box needs outbound for (Docker Hub, ECR, Amazon Linux
# package repos, SSM agent) is plain HTTPS, so egress is scoped to 443
# rather than left wide open — limits what a compromised process on the box
# could do (arbitrary reverse shells, UDP/ICMP exfiltration channels, etc.)
# without costing any real functionality.
resource "aws_vpc_security_group_egress_rule" "postgres_outbound_https" {
  security_group_id = aws_security_group.postgres.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 443
  to_port             = 443
  ip_protocol        = "tcp"
  description        = "HTTPS outbound (Docker Hub, ECR, package repos, SSM)"
}

# Lambda's VPC attachment has no NAT Gateway in front of it, so it can't
# reach the internet regardless of this rule — scoping its egress to just
# Postgres costs nothing and matches least privilege.
resource "aws_vpc_security_group_egress_rule" "lambda_to_postgres" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.postgres.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Postgres"
}

data "aws_caller_identity" "current" {}

# IAM role for the Postgres EC2 instance. Trust policy only allows the EC2
# service itself to assume it (this is what lets an EC2 instance use the
# role at all, via its instance profile).
resource "aws_iam_role" "postgres_instance" {
  name = "taro-production-postgres"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Lets you get a shell on the instance via SSM Session Manager instead of
# SSH — no open port 22, no key pair to manage, no public-IP allowlisting.
resource "aws_iam_role_policy_attachment" "postgres_instance_ssm" {
  role       = aws_iam_role.postgres_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Read-only ECR access, scoped to repos following our "taro-*" naming
# convention rather than the AWS-managed AmazonEC2ContainerRegistryReadOnly
# policy, which would grant read access to any ECR repo in the account.
# GetAuthorizationToken is an account-level action that doesn't support
# resource-level restriction, so it's the one exception with Resource "*".
resource "aws_iam_role_policy" "postgres_instance_ecr_read" {
  name = "taro-ecr-read"
  role = aws_iam_role.postgres_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPullTaroRepos"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/taro-*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "postgres_instance" {
  name = "taro-production-postgres"
  role = aws_iam_role.postgres_instance.name
}
