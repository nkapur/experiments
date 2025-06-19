# Outputs for VPC and Subnet
output "vpc_id" {
  value = aws_vpc.experiments_apps_vpc.id
}
output "subnet_id_a" {
  value = aws_subnet.experiments_apps_subnet_public_a.id
}
output "subnet_id_b" {
  value = aws_subnet.experiments_apps_subnet_public_b.id
}
output "private_subnet_id_a" {
  value = aws_subnet.experiments_apps_subnet_private_a.id
}
output "private_subnet_id_b" {
  value = aws_subnet.experiments_apps_subnet_private_b.id
}
output "nat_gateway_id" {
  value = aws_nat_gateway.experiments_apps_nat_gw.id
}
