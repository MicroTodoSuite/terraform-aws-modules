# Plan-time tests of the Karpenter interruption module against a mocked AWS provider
# (PC-IAC-018). The events are Karpenter's reference CloudFormation template.
mock_provider "aws" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fdev"
  queue = {
    name                      = "lex-mts-fdev-sqs-karpenter"
    message_retention_seconds = 300
    kms_key_arn               = ""
  }
  rule_names = {
    scheduled_change      = "lex-mts-fdev-evr-karpscheduled"
    spot_interruption     = "lex-mts-fdev-evr-karpspot"
    rebalance             = "lex-mts-fdev-evr-karprebalance"
    instance_state_change = "lex-mts-fdev-evr-karpstate"
    capacity_reservation  = "lex-mts-fdev-evr-karpcapacity"
  }
}

run "creates_the_named_queue_encrypted_by_sqs" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_sqs_queue.this.name == "lex-mts-fdev-sqs-karpenter" && aws_sqs_queue.this.message_retention_seconds == 300
    error_message = "The queue must carry the name the root built and keep an interruption only as long as it is useful."
  }

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled == true && aws_sqs_queue.this.kms_master_key_id == null
    error_message = "Without a customer key the queue must use SQS-owned encryption; the two are exclusive."
  }

  assert {
    condition     = aws_sqs_queue.this.tags["Name"] == "lex-mts-fdev-sqs-karpenter" && aws_sqs_queue.this.tags["Environment"] == "fdev"
    error_message = "The queue must carry the governance tags."
  }
}

run "encrypts_with_the_customer_key_when_the_root_passes_one" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    queue = {
      name                      = "lex-mts-fdev-sqs-karpenter"
      message_retention_seconds = 300
      kms_key_arn               = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    }
  }

  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000" && aws_sqs_queue.this.sqs_managed_sse_enabled == null
    error_message = "A customer key must encrypt the queue instead of the SQS-owned key."
  }
}

run "lets_only_the_event_services_enqueue_and_only_over_tls" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = jsondecode(aws_sqs_queue_policy.this.policy).Version == "2012-10-17"
    error_message = "The policy must set Version explicitly; without it AWS hangs while attaching a queue policy."
  }

  assert {
    condition     = toset(jsondecode(aws_sqs_queue_policy.this.policy).Statement[0].Principal.Service) == toset(["events.amazonaws.com", "sqs.amazonaws.com"]) && jsondecode(aws_sqs_queue_policy.this.policy).Statement[0].Action == "sqs:SendMessage"
    error_message = "Only EventBridge and Amazon SQS may enqueue interruptions."
  }

  assert {
    condition     = jsondecode(aws_sqs_queue_policy.this.policy).Statement[1].Effect == "Deny" && jsondecode(aws_sqs_queue_policy.this.policy).Statement[1].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "Every request that is not encrypted in transit must be denied."
  }
}

run "forwards_every_interruption_event_to_the_queue" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = toset(keys(aws_cloudwatch_event_rule.this)) == toset(["scheduled_change", "spot_interruption", "rebalance", "instance_state_change", "capacity_reservation"])
    error_message = "Karpenter needs all five interruption rules its reference template defines."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.this["spot_interruption"].event_pattern) == { source = ["aws.ec2"], "detail-type" = ["EC2 Spot Instance Interruption Warning"] } && jsondecode(aws_cloudwatch_event_rule.this["scheduled_change"].event_pattern) == { source = ["aws.health"], "detail-type" = ["AWS Health Event"] }
    error_message = "Each rule must match exactly the source and detail type Karpenter consumes."
  }

  assert {
    condition     = alltrue([for key in keys(aws_cloudwatch_event_rule.this) : aws_cloudwatch_event_rule.this[key].name == var.rule_names[key]])
    error_message = "Every rule must carry the standard name the root built."
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.this) == 5 && alltrue([for target in aws_cloudwatch_event_target.this : target.arn == aws_sqs_queue.this.arn])
    error_message = "Every rule must target the interruption queue."
  }
}

run "rejects_a_queue_name_amazon_sqs_would_refuse" {
  command = plan

  variables {
    queue = {
      name                      = "lex mts fdev karpenter"
      message_retention_seconds = 300
      kms_key_arn               = ""
    }
  }

  expect_failures = [var.queue]
}

run "rejects_two_rules_sharing_a_name" {
  command = plan

  variables {
    rule_names = {
      scheduled_change      = "lex-mts-fdev-evr-karpscheduled"
      spot_interruption     = "lex-mts-fdev-evr-karpscheduled"
      rebalance             = "lex-mts-fdev-evr-karprebalance"
      instance_state_change = "lex-mts-fdev-evr-karpstate"
      capacity_reservation  = "lex-mts-fdev-evr-karpcapacity"
    }
  }

  expect_failures = [var.rule_names]
}
