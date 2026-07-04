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

# AWS's own published pointer to the latest Amazon Linux 2023 arm64 AMI -
# more reliable than filtering aws_ami by name pattern, which has been prone
# to drift as AWS's own naming conventions changed over the years.
data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# Holds the Postgres password so it never has to be embedded in plaintext in
# the EC2 instance's user-data/metadata. SSM encrypts SecureString values at
# rest with a KMS key; only the instance's own IAM role (below) can read it.
resource "aws_ssm_parameter" "postgres_password" {
  name  = "/taro/production/postgres_password"
  type  = "SecureString"
  value = var.postgres_password

  tags = {
    Name = "taro-production-postgres-password"
  }
}

# Scoped to exactly this one parameter, not all of SSM. The KMS statement
# doesn't name a specific key (the default aws/ssm key's ID isn't something
# we want to hardcode) - instead it constrains *how* Decrypt can be used: only
# when SSM itself is doing the decrypting on the caller's behalf, not as a
# general-purpose decrypt grant against arbitrary KMS-encrypted data.
resource "aws_iam_role_policy" "postgres_instance_ssm_param" {
  name = "taro-ssm-param-read"
  role = aws_iam_role.postgres_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadPostgresPasswordParam"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = aws_ssm_parameter.postgres_password.arn
      },
      {
        Sid      = "DecryptViaSsmOnly"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })
}

# Separate from the EC2 instance's own lifecycle on purpose: prevent_destroy
# here means the Postgres data survives instance replacement (resizing,
# rebuilding after an AMI update, etc.) instead of being tied to whatever
# instance happens to exist at the time.
resource "aws_ebs_volume" "postgres_data" {
  availability_zone = aws_subnet.public.availability_zone
  size              = var.postgres_data_volume_gb
  type              = "gp3"

  tags = {
    Name = "taro-production-postgres-data"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "postgres_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.postgres_data.id
  instance_id = aws_instance.postgres.id
}

resource "aws_instance" "postgres" {
  ami                    = data.aws_ssm_parameter.al2023_arm64.value
  instance_type          = "t4g.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.postgres.id]
  iam_instance_profile   = aws_iam_instance_profile.postgres_instance.name

  user_data = templatefile("${path.module}/postgres_user_data.sh.tftpl", {
    postgres_user           = var.postgres_user
    postgres_password_param = aws_ssm_parameter.postgres_password.name
    postgres_db             = var.postgres_database
    aws_region              = var.aws_region
  })

  tags = {
    Name = "taro-production-postgres"
  }

  lifecycle {
    # Without this, every time AWS publishes a patched AL2023 AMI, the next
    # `plan` would want to replace this instance - disruptive and
    # unexpected for something that should just sit there running Postgres.
    # Upgrade deliberately (terraform apply -replace=aws_instance.postgres)
    # rather than as a side effect of an unrelated apply.
    ignore_changes = [ami]
  }
}
