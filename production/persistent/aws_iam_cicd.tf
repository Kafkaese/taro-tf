# GitHub's OIDC provider - lets AWS trust GitHub Actions' own identity
# tokens directly instead of needing long-lived access keys stored as
# GitHub secrets. One provider per AWS account, shared by any number of
# GitHub repos/roles that trust it.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's own leaf certificate rotates periodically (currently issued by
  # Let's Encrypt); this is the thumbprint of ISRG Root X1, the root CA the
  # chain traces up to, verified directly against the live chain presented
  # by token.actions.githubusercontent.com (openssl s_client -connect
  # token.actions.githubusercontent.com:443 -showcerts). Pinning to the
  # root instead of the leaf means routine cert renewals don't break this -
  # only an actual change of certificate authority would.
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
}

# Scoped to exactly one repo, one branch: only taro-data's main branch can
# assume this role - a PR from a fork, a different repo, or a feature
# branch can't push to ECR under this identity.
resource "aws_iam_role" "github_actions_pipeline_build" {
  name = "taro-github-actions-pipeline-build"

  # Ceiling on how long any assumed session can last, enforced by AWS
  # itself - not just "what the workflow happens to request today". The
  # build+push job only takes a couple of minutes; 900s (the AWS minimum)
  # is already generous for it.
  max_session_duration = 900

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:Kafkaese/taro-data:ref:refs/heads/main"
        }
      }
    }]
  })
}

# Push access to exactly the shared "taro" ECR repo, nothing else.
# GetAuthorizationToken is an account-level action that doesn't support
# resource-level restriction, same exception as elsewhere in this config.
resource "aws_iam_role_policy" "github_actions_pipeline_build_ecr_push" {
  name = "taro-ecr-push"
  role = aws_iam_role.github_actions_pipeline_build.id

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
        Sid    = "EcrPushTaroRepo"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
        ]
        Resource = aws_ecr_repository.taro.arn
      },
    ]
  })
}
