data "aws_route53_zone" "my_domain" {
  name = "navneetkapur.com"
}

data "aws_lb" "fastapi_test_alb_staging" {
  tags = {
    "elbv2.k8s.aws/cluster" = "experiments-kube-cluster"
    "ingress.k8s.aws/stack" = "staging/fastapi-test-ingress"
  }
}

# Create a CNAME record for a new subdomain
resource "aws_route53_record" "fastapi_test_cname" {
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "fastapi-test.staging.navneetkapur.com"
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.fastapi_test_alb_staging.dns_name]
}

# data "aws_lb" "fastapi_test_alb" {
#   tags = {
#     "elbv2.k8s.aws/cluster" = "experiments-kube-cluster"
#     "elbv2.k8s.aws/ingress" = "prod/fastapi-test-ingress"
#   }
# }

# # Create a CNAME record for a new subdomain
# resource "aws_route53_record" "fastapi_test_cname" {
#   zone_id = data.aws_route53_zone.my_domain.zone_id
#   name    = "fastapi-test.navneetkapur.com"
#   type    = "CNAME"
#   ttl     = 300
#   records = [data.aws_lb.fastapi_test_alb.dns_name]
# }