# The Karpenter interruption sample: one call of the module, fed from locals.
module "karpenter_interruption" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment
  queue       = local.queue
  rule_names  = local.rule_names
}
