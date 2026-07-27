data "google_project" "current" {
  project_id = var.gcp_project_id
}

# GCP's equivalent of the GitHub OIDC provider set up for AWS in
# aws_iam_cicd.tf - lets a GitHub Actions run prove its identity directly to
# GCP without a downloaded service account key.
resource "google_iam_workload_identity_pool" "github_actions" {
  workload_identity_pool_id = "taro-github-actions"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  workload_identity_pool_id         = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Hard gate enforced before a token is even accepted into the pool - only
  # taro-map's main branch, mirroring the sub-claim condition on the AWS
  # role's trust policy.
  attribute_condition = "assertion.repository == \"Kafkaese/taro-map\" && assertion.ref == \"refs/heads/main\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# The actual identity the CI job impersonates - GCP's IAM model works
# through service accounts as principals, unlike AWS where the OIDC-trusted
# role is itself the principal being assumed.
resource "google_service_account" "frontend_deploy" {
  account_id   = "taro-frontend-deploy"
  display_name = "GitHub Actions - taro-map frontend deploy"
}

# Lets the pool's identities (already filtered to taro-map's main branch by
# the provider's attribute_condition above) impersonate this service
# account - scoped by repository as a second, independent check.
resource "google_service_account_iam_member" "frontend_deploy_workload_identity" {
  service_account_id = google_service_account.frontend_deploy.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/Kafkaese/taro-map"
}

# Write access scoped to exactly the frontend bucket, nothing else in the
# project.
resource "google_storage_bucket_iam_member" "frontend_deploy_write" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.frontend_deploy.email}"
}
