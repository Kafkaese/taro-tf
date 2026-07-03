# Bootstrap

Creates the S3 bucket and DynamoDB table that the `persistent` and
`deployment` configs (currently at `production/persistent` and
`production/deployment`, until those move under `envs/` too) use as their
Terraform state backend.

Uses local state itself (see `providers.tf` for why) and is meant to be run
once, then rarely touched again.

## Usage

```
cd envs/bootstrap
terraform init
terraform apply
```

Then take the outputs and hardcode them into the `backend "s3" {}` block of
`production/persistent/providers.tf` and `production/deployment/providers.tf`
(paths as of this writing — see note above):

```hcl
backend "s3" {
  bucket         = "<state_bucket_name output>"
  key            = "persistent.tfstate"  # or "deployment.tfstate"
  region         = "<aws_region output>"
  dynamodb_table = "<lock_table_name output>"
  encrypt        = true
}
```
