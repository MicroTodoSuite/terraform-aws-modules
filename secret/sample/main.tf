# The secret sample: one call of the module, fed from locals. It creates the container only.
module "secret" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment
  secret_name = local.secret_name
  description = "Sample secret container; its value is set outside Terraform."
  kms_key_arn = ""
}
