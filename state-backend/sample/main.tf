# The state-backend sample: one call of the module, fed from locals.
module "state_backend" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client       = var.client
  project      = var.project
  environment  = var.environment
  bucket_name  = local.bucket_name
  kms_key_name = local.kms_key_name
}
