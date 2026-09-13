# network

One VPC for one environment: public and private subnets, an internet gateway,
NAT gateways as configured, and VPC flow logs to an encrypted CloudWatch log
group. It replaces the upstream `terraform-aws-modules/vpc` that
`microservice-app-ops` used. That module creates the flow-log IAM role
itself, which PC-IAC-023 forbids. Here the role and the key arrive as inputs
from the shared security root, which is applied before any environment's
network.

## Egress

Each private subnet has its own route table and one of three default routes:

| `egress` | Default route | Used by |
| --- | --- | --- |
| `nat` | `nat_gateways[nat_gateway_key]` | `eco` (zonal NAT gateways), or any environment with a single NAT |
| `transit` | `transit_gateway_id` | Full-profile spokes behind the shared egress hub |
| `none` | No default route | Isolated subnets |

Every NAT gateway sits in a public subnet with its own Elastic IP. Public
subnets share one route table whose default route is the internet gateway.
No subnet assigns public addresses on launch.

## Transit spokes

A VPC with `transit` subnets also takes `transit_attachment`, the spoke side
of a `transit-egress` hub. The spoke's own state then creates:

- the VPC's attachment, in private subnets (at most one per Availability Zone), outside the default tables;
- the attachment's association with the spoke's dedicated route table;
- that table's one default route, to the hub attachment;
- this VPC's return route in the hub route table.

The private routes to the transit gateway wait for the attachment. A plan with
`transit` subnets but no `transit_attachment` fails.

This module owns the VPC, subnet, route table, route, association, internet
gateway, and NAT gateway types that PC-IAC-023 forbids in service modules;
`iac-contracts.json` records it as their owner.

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `client`, `project`, `environment` | `string` | Governance codes, used for tags |
| `vpc` | `object` | `name`, `cidr_block` |
| `internet_gateway_name`, `public_route_table_name` | `string` | Standard names |
| `subnets` | `map(object)` | `name`, `availability_zone`, `cidr_block`, `tier`, and for private subnets `route_table_name`, `egress`, `nat_gateway_key`; `tags` for discovery |
| `nat_gateways` | `map(object)` | `name`, `eip_name`, `subnet_key`; default `{}` |
| `transit_gateway_id` | `string` | Transit gateway for `transit` egress, or `""` |
| `transit_attachment` | `object` | `name`, `subnet_keys`, `route_table_id`, `hub_attachment_id`, `hub_route_table_id`; `null` without transit egress |
| `flow_log` | `object` | `name`, `log_group_name` (under `/aws/vpc-flow-logs/`), `log_group_standard_name`, `retention_in_days`, `kms_key_arn`, `iam_role_arn`, `traffic_type` (`ALL`), `max_aggregation_interval` (`60`) |
| `additional_tags` | `map(string)` | Extra tags; `Name` is reserved |

## Outputs

- **VPC:** `vpc_id`, `vpc_arn`, `vpc_cidr`.
- **Gateways:** `internet_gateway_id`, `nat_gateway_ids`, `nat_eip_allocation_ids`, `transit_attachment_id`.
- **Subnets and routes:** `public_subnet_ids`, `private_subnet_ids`, `public_route_table_id`, `private_route_table_ids`.
- **Flow logs:** `flow_log_id`, `flow_log_group_arn`.

## Example

See `sample/`: two zones, one NAT gateway, and flow logs.
