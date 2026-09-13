# transit-egress

The shared centralized-egress hub: one transit gateway through which the
full-profile environments reach the internet. They all share one NAT gateway
and one Elastic IP, and never reach each other. It replaces the
`centralized-egress` module in `microservice-app-ops`, which built its own VPC
with the upstream `vpc` module and created its flow-log role and key. Here
the egress VPC is a `network` call in the same root, whose flow-log role and
key come from the shared security root.

## What the hub owns

| Resource | Purpose |
| --- | --- |
| Transit gateway | Default association, default propagation, and auto-accept all disabled, so no attachment joins a shared table or advertises its CIDR by itself |
| Hub attachment | The egress VPC, attached in its private subnets and kept out of the default tables |
| Hub route table | Associated with the hub attachment; each spoke installs its return route here |
| One route table per spoke | Empty. A spoke associates its own attachment with it and adds one default route to the hub attachment |
| Return routes | In the egress VPC's public route table, one per spoke CIDR, pointing at the transit gateway so NAT replies reach the spoke |

No spoke table ever holds a route toward another spoke, so spoke-to-spoke
traffic has nowhere to go.

The spoke side is owned by the spoke's own state, so an environment can never
create or destroy the hub:
- the spoke VPC's attachment;
- the association with its table;
- its default route to the hub;
- its return route in the hub table;
- its private routes to the transit gateway.

This module owns `aws_route` for the return routes, which PC-IAC-023 otherwise
forbids in service modules; `iac-contracts.json` records it as an owner.

## Egress VPC

Build it with `network` in the same `shd` root:
- one public subnet with a NAT gateway;
- one private subnet with `egress = "nat"` for the attachment's network interfaces.

Pass its outputs in `hub_vpc`.

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `client`, `project`, `environment` | `string` | Governance codes, used for tags |
| `transit_gateway_name`, `hub_attachment_name`, `hub_route_table_name` | `string` | Standard names |
| `hub_vpc` | `object` | `id`, `cidr_block`, `attachment_subnet_ids`, `public_route_table_id` |
| `spokes` | `map(object)` | Keyed by spoke key: `vpc_cidr`, `route_table_name`; spokes must not overlap each other or the egress VPC |
| `additional_tags` | `map(string)` | Extra tags; `Name` is reserved |

## Outputs

`transit_gateway_id`, `transit_gateway_arn`, `hub_attachment_id`,
`hub_route_table_id`, `spoke_route_table_ids`.

## Example

```hcl
module "transit_egress" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//transit-egress?ref=transit-egress-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client               = var.client
  project              = var.project
  environment          = var.environment
  transit_gateway_name = "${local.governance_prefix}-tgw-egress"
  hub_attachment_name  = "${local.governance_prefix}-tgwa-egress"
  hub_route_table_name = "${local.governance_prefix}-rtb-tgwhub"

  hub_vpc = {
    id                    = module.egress_network.vpc_id
    cidr_block            = module.egress_network.vpc_cidr
    attachment_subnet_ids = values(module.egress_network.private_subnet_ids)
    public_route_table_id = module.egress_network.public_route_table_id
  }

  spokes = local.egress_spokes
}
```
