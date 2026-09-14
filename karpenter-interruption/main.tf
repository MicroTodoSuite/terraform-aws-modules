# The Karpenter interruption path of one cluster: the queue Karpenter polls, the policy that
# lets only the event services enqueue over TLS, and the EventBridge rules that feed it.
# Karpenter itself, its NodePool, and its EC2NodeClass are GitOps desired state (MTS-IAC-105).
resource "aws_sqs_queue" "this" {
  provider = aws.project

  name                      = var.queue.name
  message_retention_seconds = var.queue.message_retention_seconds

  # SQS-owned encryption unless the root passes a customer key; the two are exclusive.
  sqs_managed_sse_enabled = var.queue.kms_key_arn == "" ? true : null
  kms_master_key_id       = var.queue.kms_key_arn == "" ? null : var.queue.kms_key_arn

  tags = local.tags
}

resource "aws_sqs_queue_policy" "this" {
  provider = aws.project

  queue_url = aws_sqs_queue.this.url

  policy = local.queue_policy
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.rules
  provider = aws.project

  name          = each.value.name
  description   = each.value.description
  event_pattern = jsonencode(each.value.pattern)
  tags          = merge(local.governance_tags, { Name = each.value.name }, var.additional_tags)
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.rules
  provider = aws.project

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = "karpenter-interruption-queue"
  arn       = aws_sqs_queue.this.arn
}
