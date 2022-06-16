# terraform-module-concourse-lb
Terraform module to create the ALB for Concourse


Inputs - Required:

 - `resource_tags` - AWS tags to apply to resources
 - `vpc_id` - AWS VPC Id
 - `subnet_ids` - The AWS Subnet Id to place the lb into     
 - `concourse_domain` - url used for blacksmith domain
 - `route53_zone_id` - Route53 zone id
 - `security_groups` - Array of security groups to use on th elb
 - `concourse_acm_arn` - ACM arn for the concourse certificates

Inputs - Optional: 

 - `enable_route_53` - Disable if using CloudFlare or other DNS (default = 1, to disable, set = 0)

Outputs:

 - `dns_name` - The A Record for the created load balancer