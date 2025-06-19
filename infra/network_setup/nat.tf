# Allocate an Elastic IP for our NAT Gateway
resource "aws_eip" "experiments_apps_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "Experiments Apps NAT EIP"
  }
}

# Create the NAT Gateway and place it in a public subnet
resource "aws_nat_gateway" "experiments_apps_nat_gw" {
  allocation_id = aws_eip.experiments_apps_nat_eip.id
  subnet_id     = aws_subnet.experiments_apps_subnet_public_a.id # Must be in a public subnet

  tags = {
    Name = "Experiments Apps NAT GW"
  }

  # Ensure the Internet Gateway is created before the NAT Gateway
  depends_on = [aws_internet_gateway.experiments_apps_igw]
}

# Create a new route table for the private subnets
resource "aws_route_table" "experiments_apps_private_route_table" {
  vpc_id = aws_vpc.experiments_apps_vpc.id

  # Add a route from the private subnets to the NAT Gateway for outbound internet access
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.experiments_apps_nat_gw.id
  }

  tags = {
    Name = "Experiments Apps Private Route Table"
  }
}

# Associate the private subnets with the new private route table
resource "aws_route_table_association" "experiments_apps_private_route_table_association_a" {
  subnet_id      = aws_subnet.experiments_apps_subnet_private_a.id
  route_table_id = aws_route_table.experiments_apps_private_route_table.id
}

resource "aws_route_table_association" "experiments_apps_private_route_table_association_b" {
  subnet_id      = aws_subnet.experiments_apps_subnet_private_b.id
  route_table_id = aws_route_table.experiments_apps_private_route_table.id
}