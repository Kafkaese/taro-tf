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

# Read-only ECR access, scoped to exactly the one shared "taro" repository
# rather than the AWS-managed AmazonEC2ContainerRegistryReadOnly policy,
# which would grant read access to any ECR repo in the account.
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
        Resource = aws_ecr_repository.taro.arn
      },
    ]
  })
}

# Scoped to exactly the one SSM parameter holding the Postgres password, not
# all of SSM. The KMS statement doesn't name a specific key (the default
# aws/ssm key's ID isn't something we want to hardcode) - instead it
# constrains *how* Decrypt can be used: only when SSM itself is doing the
# decrypting on the caller's behalf, not as a general-purpose decrypt grant
# against arbitrary KMS-encrypted data.
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

resource "aws_iam_instance_profile" "postgres_instance" {
  name = "taro-production-postgres"
  role = aws_iam_role.postgres_instance.name
}
