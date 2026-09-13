# The iam-oidc-provider sample: one call of the module, fed from locals.
module "iam_oidc_provider" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client        = var.client
  project       = var.project
  environment   = var.environment
  url           = "https://token.actions.githubusercontent.com"
  client_ids    = ["sts.amazonaws.com"]
  standard_name = local.standard_name
}
