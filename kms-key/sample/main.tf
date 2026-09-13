# The kms-key sample: one call of the module, fed from locals.
module "kms_key" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment
  key_name    = local.key_name
  description = "Sample key with the default key policy."
}
