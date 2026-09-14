# karpenter-interruption

The AWS side of Karpenter's interruption handling for one cluster: the queue
Karpenter polls, the policy that lets only the event services enqueue, and the
EventBridge rules that feed it.

Karpenter itself — its release, its `NodePool`, and its `EC2NodeClass` — is
GitOps desired state (MTS-IAC-105). This module creates only what Terraform
must own, and its `queue_name` output is the value Karpenter's
`--interruption-queue` setting takes.

| Resource | Purpose |
| --- | --- |
| `aws_sqs_queue` | The interruption queue, retaining a message only as long as it is actionable |
| `aws_sqs_queue_policy` | Lets `events.amazonaws.com` and `sqs.amazonaws.com` enqueue, and denies every request that is not encrypted in transit |
| `aws_cloudwatch_event_rule` (five) | The events Karpenter consumes |
| `aws_cloudwatch_event_target` (five) | Each rule, pointed at the queue |

## The five events

They are Karpenter's reference CloudFormation template
(`karpenter.sh/docs/reference/cloudformation`, Interruption Handling):

| Key | Source | Detail type |
| --- | --- | --- |
| `scheduled_change` | `aws.health` | `AWS Health Event` |
| `spot_interruption` | `aws.ec2` | `EC2 Spot Instance Interruption Warning` |
| `rebalance` | `aws.ec2` | `EC2 Instance Rebalance Recommendation` |
| `instance_state_change` | `aws.ec2` | `EC2 Instance State-change Notification` |
| `capacity_reservation` | `aws.ec2` | `EC2 Capacity Reservation Instance Interruption Warning` |

Without them Karpenter still reacts to unhealthy instances through
`DescribeInstanceStatus`, but it loses the two-minute Spot warning, which is
what makes a Spot fleet usable.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101) |
| `queue` | The queue's standard name, its message retention in seconds, and the customer KMS key ARN, or an empty string for SQS-owned encryption |
| `rule_names` | The standard name of each of the five rules |
| `additional_tags` | Tags besides `Name` and the provider's default tags |

Every name is built by the root (PC-IAC-025). Queue names are unique per
account and region, so the name must carry the cluster's environment.

## Outputs

`queue_name`, `queue_arn`, `queue_url`, and `rule_arns` keyed by event.

## Sample

`sample/` calls the module once with local state; see its README.
