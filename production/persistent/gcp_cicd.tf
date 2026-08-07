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

# Same identity deploys to both buckets - dev and prod are gated by a
# GitHub Environment approval rule within one workflow run, not by
# separate branches/identities, so there's no reason to split this into a
# second service account.
resource "google_storage_bucket_iam_member" "frontend_deploy_write_dev" {
  bucket = google_storage_bucket.frontend_dev.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.frontend_deploy.email}"
}

# `gcloud storage rsync` needs storage.buckets.list to resolve/validate the
# gs://bucket-name reference before it'll sync anything - and that specific
# permission is inherently project-scoped (bucket enumeration, not access
# to a bucket's contents), unlike object read/write, so it can't be granted
# via the bucket-level binding above no matter how the role is chosen. This
# custom role grants only that one permission at the project level, rather
# than widening to a broader predefined project role - actual data access
# stays confined to the frontend bucket via frontend_deploy_write.
resource "google_project_iam_custom_role" "frontend_deploy_bucket_list" {
  role_id     = "taroFrontendDeployBucketList"
  title       = "Taro frontend deploy - bucket list"
  description = "Minimal project-level grant so gcloud storage rsync can resolve the frontend bucket reference; grants no access to bucket contents."
  permissions = ["storage.buckets.list"]
}

resource "google_project_iam_member" "frontend_deploy_bucket_list" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.frontend_deploy_bucket_list.id
  member  = "serviceAccount:${google_service_account.frontend_deploy.email}"
}
