
# 1. Request the certificate
# The 'validation_method' is set to DNS, which is the best way to automate this.
resource "aws_acm_certificate" "my_certificate" {
  domain_name               = aws_route53_zone.my_domain_zone.name
  subject_alternative_names = ["*.${aws_route53_zone.my_domain_zone.name}", "*.staging.${aws_route53_zone.my_domain_zone.name}"]
  validation_method         = "DNS"

  # Recommended lifecycle block to prevent issues when replacing a certificate in use
  lifecycle {
    create_before_destroy = true
  }
}

# Use a local variable to create a unique set of validation records
locals {
  validation_records = distinct([
    for dvo in aws_acm_certificate.my_certificate.domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ])
}

# 2. Create the DNS records needed for validation

# NOTE: We run into circular dependencies when updating SANs. The locals.validation_records
#       will need to be updated to reflect the new SANs. The solution may require us to
#       work around by getting 
#         1) terraform to forget the resources below
#         2) comment below
#         3) run the above
#         4) reset - terraform import, then uncomment below and terraform apply

# This resource now uses the unique list of records from the local variable.
resource "aws_route53_record" "acm_validation_records" {
  for_each = {
    for record in local.validation_records : record.name => record
  }
  
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  zone_id = aws_route53_zone.my_domain_zone.zone_id
  ttl     = 60
}

# 3. Wait for the certificate to be validated
# This resource explicitly depends on the DNS records being created and tells
# Terraform to wait for ACM to finish the validation process.
resource "aws_acm_certificate_validation" "acm_validation" {
  certificate_arn         = aws_acm_certificate.my_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation_records : record.fqdn]
}

# Output the certificate ARN for use in other resources (like your ALB)
output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.acm_validation.certificate_arn
}