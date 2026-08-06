# Lets the pipeline be triggered with one CLI call from anywhere with
# ssm:SendCommand permission, no interactive SSM session needed - the
# script content is delivered fresh by SSM on each invocation rather than
# baked into the instance's boot process, so updating it is just a
# Terraform apply, not an instance replacement.
resource "aws_ssm_document" "run_pipeline" {
  name          = "taro-run-pipeline"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Pulls the latest taro:pipeline image and runs it against the production Postgres instance."
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "runPipeline"
        inputs = {
          runCommand = split("\n", templatefile("${path.module}/run_pipeline.sh.tftpl", {
            aws_region              = var.aws_region
            ecr_repository_url      = aws_ecr_repository.taro.repository_url
            postgres_password_param = aws_ssm_parameter.postgres_password.name
            postgres_user           = var.postgres_user
            postgres_database       = var.postgres_database
            pipeline_data_bucket    = aws_s3_bucket.pipeline_data.bucket
          }))
        }
      }
    ]
  })
}
