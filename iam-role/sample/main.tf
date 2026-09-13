# The iam-role sample: one call of the module, fed from locals.
module "iam_role" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client                   = var.client
  project                  = var.project
  environment              = var.environment
  role_name                = local.role_name
  description              = "Sample role that EC2 may assume."
  assume_role_policy       = local.assume_role_policy
  managed_policy_arns      = []
  permissions_boundary_arn = ""
}
