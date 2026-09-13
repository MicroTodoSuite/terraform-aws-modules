# An IAM role with its trust policy, inline policies, and managed policy attachments.
# This module owns the IAM types PC-IAC-023 forbids in service modules (iac-contracts.json).
resource "aws_iam_role" "this" {
  provider = aws.project

  name                 = var.role_name
  description          = var.description
  assume_role_policy   = var.assume_role_policy
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn == "" ? null : var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy" "this" {
  for_each = var.inline_policies
  provider = aws.project

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.managed_policy_arns
  provider = aws.project

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
