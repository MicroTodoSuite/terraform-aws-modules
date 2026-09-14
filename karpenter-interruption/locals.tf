# Local values: the governance tags, and the five interruption events Karpenter consumes.
# The sources and detail types are Karpenter's reference CloudFormation template
# (karpenter.sh/docs/reference/cloudformation, Interruption Handling).
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  tags = merge(local.governance_tags, { Name = var.queue.name }, var.additional_tags)

  events = {
    scheduled_change = {
      source      = "aws.health"
      detail_type = "AWS Health Event"
      description = "Sends AWS Health scheduled change events to the Karpenter interruption queue."
    }
    spot_interruption = {
      source      = "aws.ec2"
      detail_type = "EC2 Spot Instance Interruption Warning"
      description = "Sends the two-minute Spot interruption warning to the Karpenter interruption queue."
    }
    rebalance = {
      source      = "aws.ec2"
      detail_type = "EC2 Instance Rebalance Recommendation"
      description = "Sends the Spot rebalance recommendation to the Karpenter interruption queue."
    }
    instance_state_change = {
      source      = "aws.ec2"
      detail_type = "EC2 Instance State-change Notification"
      description = "Sends EC2 instance state changes to the Karpenter interruption queue."
    }
    capacity_reservation = {
      source      = "aws.ec2"
      detail_type = "EC2 Capacity Reservation Instance Interruption Warning"
      description = "Sends capacity reservation interruption warnings to the Karpenter interruption queue."
    }
  }

  # Version is explicit on purpose: without it AWS hangs while attaching a queue
  # policy, as the provider documentation warns.
  queue_policy = jsonencode({
    Version = "2012-10-17"
    Id      = "EC2InterruptionPolicy"
    Statement = [
      {
        Sid       = "AllowInterruptionEvents"
        Effect    = "Allow"
        Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.this.arn
      },
      {
        Sid       = "DenyRequestsWithoutTls"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.this.arn
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })

  rules = {
    for key, event in local.events : key => {
      name        = var.rule_names[key]
      description = event.description
      pattern     = { source = [event.source], "detail-type" = [event.detail_type] }
    }
  }
}
