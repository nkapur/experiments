# Create a public hosted zone for your domain
resource "aws_route53_zone" "my_domain_zone" {
  name = "navneetkapur.com" 
}

# Output the nameservers created by AWS
output "route53_nameservers" {
  value = aws_route53_zone.my_domain_zone.name_servers
}