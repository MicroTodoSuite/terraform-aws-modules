# The route53-zone sample: one call of the module, fed from locals.
module "route53_zone" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client        = var.client
  project       = var.project
  environment   = var.environment
  zone_name     = local.zone_name
  standard_name = local.standard_name
}
