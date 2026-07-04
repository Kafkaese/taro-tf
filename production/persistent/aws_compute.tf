# AWS's own published pointer to the latest Amazon Linux 2023 arm64 AMI -
# more reliable than filtering aws_ami by name pattern, which has been prone
# to drift as AWS's own naming conventions changed over the years.
data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# Holds the Postgres password so it never has to be embedded in plaintext in
# the EC2 instance's user-data/metadata. SSM encrypts SecureString values at
# rest with a KMS key; only the instance's own IAM role (see aws_iam.tf) can
# read it.
resource "aws_ssm_parameter" "postgres_password" {
  name  = "/taro/production/postgres_password"
  type  = "SecureString"
  value = var.postgres_password

  tags = {
    Name = "taro-production-postgres-password"
  }
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
