variable subnet_ids            {}  # The AWS Subnet Id to place the lb into
variable resource_tags         {}  # AWS tags to apply to resources
variable vpc_id                {}  # The VPC Id
variable concourse_domain      {}  # url used for concourse domain
variable route53_zone_id       {}  # Route53 zone id
variable security_groups       {}  # Array of security groups to use
variable concourse_acm_arn     {}  # ACM arn for the concourse certificates
variable internal_lb           { default = true } # Determine whether the load balancer is internal-only facing

variable enable_route_53       { default = 1 }  # Disable if using CloudFlare or other DNS


################################################################################
# Concourse ALB
################################################################################
resource "aws_lb" "concourse_lb" {
  name               = "concourse-lb"
  internal           = var.internal_lb
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.security_groups
  tags               = merge({Name = "concourse-lb"}, var.resource_tags)
}

################################################################################
# Concourse ALB Target Group
################################################################################
resource "aws_lb_target_group" "concourse_lb_tg" {
  name     = "concourse-lb-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id
  tags     = merge({Name = "concourse-lb-tg"}, var.resource_tags)
  health_check {
    path = "/"
    protocol = "HTTPS"
  }
}

################################################################################
# Concourse ALB Target Group Attachment
################################################################################
# Define concourse instances using instance group, can use instance_tags or filter

# This should be done with a vm_extension instead 

#data "aws_instances" "concourse_instances" {
#  instance_tags = {
#    instance_group = "concourse"
#  }
#}
#resource "aws_lb_target_group_attachment" "concourse_lb_tga" {
#  count            = length(data.aws_instances.concourse_instances.ids)
#  target_id        = data.aws_instances.concourse_instances.ids[count.index]
#  target_group_arn = aws_lb_target_group.concourse_lb_tg.arn
#  port             = 443
#}

################################################################################
# Concourse ALB Listeners - concourse API - HTTPS
################################################################################
resource "aws_alb_listener" "concourse_lb_listener_443" {
  load_balancer_arn = aws_lb.concourse_lb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = var.concourse_acm_arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.concourse_lb_tg.arn
  }
  tags = merge({Name = "concourse-lb-listener-443"}, var.resource_tags)
}


################################################################################
# concourse ALB Route53 DNS
################################################################################
resource "aws_route53_record" "concourse_lb_record" {

  count   = var.enable_route_53
  zone_id = var.route53_zone_id
  name    = var.concourse_domain
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_lb.concourse_lb.dns_name}"]
}


output "dns_name" {value = aws_lb.concourse_lb.dns_name}
output "lb_name"  {value = aws_lb.concourse_lb.name }
output "lb_target_group_name" { value = aws_lb_target_group.concourse_lb_tg.name }
