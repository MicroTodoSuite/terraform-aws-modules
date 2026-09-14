# The trail sample: one call of the module, fed from locals.
module "cloudtrail_trail" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client                 = var.client
  project                = var.project
  environment            = var.environment
  trail_name             = local.trail_name
  bucket_name            = local.bucket_name
  kms_key_arn            = var.kms_key_arn
  s3_object_arn_prefixes = local.s3_object_arn_prefixes
  log_retention          = local.log_retention
}
