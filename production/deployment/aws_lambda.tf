# IAM role for the API Lambda. Trust policy only allows the Lambda service
# itself to assume it.
resource "aws_iam_role" "api" {
  name = "taro-production-api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Bundles both basic CloudWatch Logs permissions and the EC2 ENI
# create/describe/delete actions a VPC-attached Lambda needs to get network
# access at all - without this, the function can't even attach to the
# subnet, regardless of anything else.
resource "aws_iam_role_policy_attachment" "api_vpc_access" {
  role       = aws_iam_role.api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "api" {
  function_name = "taro-production-api"
  role          = aws_iam_role.api.arn

  package_type  = "Image"
  image_uri     = "${data.terraform_remote_state.persistent.outputs.ecr_repository_url}:api"
  architectures = ["arm64"]

  timeout     = 15
  memory_size = 512

  vpc_config {
    subnet_ids         = [data.terraform_remote_state.persistent.outputs.public_subnet_id]
    security_group_ids = [data.terraform_remote_state.persistent.outputs.lambda_security_group_id]
  }

  environment {
    variables = {
      ENV                     = "production"
      POSTGRES_HOST     = data.terraform_remote_state.persistent.outputs.postgres_private_ip
      POSTGRES_PORT     = "5432"
      POSTGRES_DB       = data.terraform_remote_state.persistent.outputs.postgres_database
      POSTGRES_USER     = data.terraform_remote_state.persistent.outputs.postgres_user
      # Plain env var rather than an SSM fetch - the Lambda has no network
      # path to SSM (VPC-attached, no NAT Gateway, no VPC endpoint), which
      # was hanging the function until its init-phase timeout. Accepted
      # tradeoff, see MIGRATION.md.
      POSTGRES_PASSWORD = data.terraform_remote_state.persistent.outputs.postgres_password
    }
  }

  # image_uri = "<repo>:api" is a tag name, a literal string that never
  # changes even as the tag's underlying digest moves - so a plain
  # `terraform apply` can structurally never detect "a new image was
  # pushed" no matter what this lifecycle block says. Learned this the hard
  # way: removing ignore_changes here didn't make new pushes get picked up,
  # it just meant nothing updated this field at all. build-api-image.yaml
  # now updates the running code directly via `aws lambda
  # update-function-code --image-uri <repo>@<digest>` using the digest
  # resolved at build time; ignore_changes here means Terraform never treats
  # that as drift to "fix" back to the stale tag-based value. See
  # MIGRATION.md.
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# --- dev ---
# Genuinely separate function (not a shared one gated by env var or alias)
# so new API code can be exercised - including via the dev frontend at
# dev.arms-tracker.app - before manual promotion to prod. Shares the same
# Postgres instance as prod (there's only one), so this isolates code, not
# data.

resource "aws_iam_role" "api_dev" {
  name = "taro-dev-api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_dev_vpc_access" {
  role       = aws_iam_role.api_dev.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "api_dev" {
  function_name = "taro-dev-api"
  role          = aws_iam_role.api_dev.arn

  package_type  = "Image"
  image_uri     = "${data.terraform_remote_state.persistent.outputs.ecr_repository_url}:api"
  architectures = ["arm64"]

  timeout     = 15
  memory_size = 512

  vpc_config {
    subnet_ids         = [data.terraform_remote_state.persistent.outputs.public_subnet_id]
    security_group_ids = [data.terraform_remote_state.persistent.outputs.lambda_security_group_id]
  }

  environment {
    variables = {
      # "production" here means "use the real CORS allowlist" (which
      # already includes dev.arms-tracker.app), not "this is prod" - ENV's
      # only consumer is the CORS branch in country_data_api.py, and the
      # "else" branch is specifically the localhost-only allowlist for
      # local docker-compose dev. This function is cloud-deployed just like
      # prod, so it belongs on the same branch.
      ENV               = "production"
      POSTGRES_HOST     = data.terraform_remote_state.persistent.outputs.postgres_private_ip
      POSTGRES_PORT     = "5432"
      POSTGRES_DB       = data.terraform_remote_state.persistent.outputs.postgres_database
      POSTGRES_USER     = data.terraform_remote_state.persistent.outputs.postgres_user
      POSTGRES_PASSWORD = data.terraform_remote_state.persistent.outputs.postgres_password
    }
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}
