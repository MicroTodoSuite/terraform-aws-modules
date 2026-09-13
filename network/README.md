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
| `flow_log` | `object` | `name`, `log_group_name` (under `/aws/vpc-flow-logs/`), `log_group_standard_name`, `retention_in_days`, `kms_key_arn`, `iam_role_arn`, `traffic_type` (`ALL`), `max_aggregation_interval` (`60`) |
| `additional_tags` | `map(string)` | Extra tags; `Name` is reserved |

## Outputs

- **VPC:** `vpc_id`, `vpc_arn`, `vpc_cidr`.
- **Gateways:** `internet_gateway_id`, `nat_gateway_ids`, `nat_eip_allocation_ids`.
- **Subnets and routes:** `public_subnet_ids`, `private_subnet_ids`, `public_route_table_id`, `private_route_table_ids`.
- **Flow logs:** `flow_log_id`, `flow_log_group_arn`.

## Example

See `sample/`: two zones, one NAT gateway, and flow logs.
