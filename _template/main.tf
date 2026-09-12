# The module's resources. Replace the example queue with the one service this module owns (PC-IAC-023).
resource "aws_sqs_queue" "this" {
  provider = aws.project

  name = var.queue.name

  message_retention_seconds = var.queue.message_retention_seconds
  sqs_managed_sse_enabled   = true
  tags                      = local.tags
}
