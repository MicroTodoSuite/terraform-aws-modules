# A symmetric customer-managed KMS key that rotates yearly, and its alias. Unlike the state
# backend's key, it carries no prevent_destroy: environment keys are destroyed with their
# environment, and KMS still keeps a deleted key recoverable for the deletion window.
resource "aws_kms_key" "this" {
  provider = aws.project

  description              = var.description
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = var.enable_key_rotation
  deletion_window_in_days  = var.deletion_window_in_days
  multi_region             = false
  policy                   = var.policy == "" ? null : var.policy
  tags                     = local.tags
}

resource "aws_kms_alias" "this" {
  provider = aws.project

  name          = "alias/${var.key_name}"
  target_key_id = aws_kms_key.this.key_id
}
