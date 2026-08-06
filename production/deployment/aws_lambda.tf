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

# Same pattern as postgres_instance_ssm_param in persistent/aws_iam.tf:
# scoped to exactly this one parameter, and Decrypt is constrained to only
# work when invoked via SSM rather than as a general-purpose grant.
resource "aws_iam_role_policy" "api_ssm_param_read" {
  name = "taro-ssm-param-read"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadPostgresPasswordParam"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${data.terraform_remote_state.persistent.outputs.postgres_password_ssm_parameter_name}"
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
      POSTGRES_HOST           = data.terraform_remote_state.persistent.outputs.postgres_private_ip
      POSTGRES_PORT           = "5432"
      POSTGRES_DB             = data.terraform_remote_state.persistent.outputs.postgres_database
      POSTGRES_USER           = data.terraform_remote_state.persistent.outputs.postgres_user
      POSTGRES_PASSWORD_PARAM = data.terraform_remote_state.persistent.outputs.postgres_password_ssm_parameter_name
    }
  }

  # Deliberately no ignore_changes on image_uri, unlike the EC2 instance's
  # AMI: that field only ever changes because AWS republishes AMIs on its
  # own schedule, outside anyone's control, which is what justifies ignoring
  # it there. taro:api's digest only ever moves because of our own CI
  # pushes, so a plain `terraform apply` picking up a new digest and doing
  # an in-place UpdateFunctionCode is exactly the wanted behavior - not
  # surprising drift to guard against.
}
