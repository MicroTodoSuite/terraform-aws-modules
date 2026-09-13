# A Secrets Manager secret, protected from destruction, and optionally its value written
# through a write-only argument so the value never reaches the state (PC-IAC-016).
resource "aws_secretsmanager_secret" "this" {
  provider = aws.project

  name                    = var.secret_name
  description             = var.description
  kms_key_id              = var.kms_key_arn == "" ? null : var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count    = var.secret_value_version > 0 ? 1 : 0
  provider = aws.project

  secret_id                = aws_secretsmanager_secret.this.id
  secret_string_wo         = var.secret_value
  secret_string_wo_version = var.secret_value_version
}
