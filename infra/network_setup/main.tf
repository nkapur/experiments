provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "experiments_apps_vpc" {
  cidr_block = "10.0.0.0/16"  # Define the IP address range for the VPC (subnet mask 16 means 65,536 addresses)

  enable_dns_support   = true  # Allow DNS resolution
  enable_dns_hostnames = true  # Allow DNS hostnames to be assigned to instances

  tags = {
    Name = "Experiments Apps VPC"
  }
}

# Create 2 public subnets for availability and redundancy
resource "aws_subnet" "experiments_apps_subnet_public_a" {
  vpc_id                  = aws_vpc.experiments_apps_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true  # Automatically assign public IP addresses to instances launched in this subnet

  tags = {
    Name = "Experiments Apps Public Subnet A"
  }
}

resource "aws_subnet" "experiments_apps_subnet_public_b" {
  vpc_id                  = aws_vpc.experiments_apps_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true  # Automatically assign public IP addresses to instances launched in this subnet

  tags = {
    Name = "Experiments Apps Public Subnet B"
  }
}

# Create a private subnet
resource "aws_subnet" "experiments_apps_subnet_private_a" {
  vpc_id                  = aws_vpc.experiments_apps_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false  # Do not automatically assign public IPs

  tags = {
    Name = "Experiments Apps Private Subnet A"
  }
}

resource "aws_subnet" "experiments_apps_subnet_private_b" {
  vpc_id                  = aws_vpc.experiments_apps_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false  # Do not automatically assign public IPs

  tags = {
    Name = "Experiments Apps Private Subnet B"
  }
}


# Create an Internet Gateway to enable internet access for public subnet
resource "aws_internet_gateway" "experiments_apps_igw" {
  vpc_id = aws_vpc.experiments_apps_vpc.id

  tags = {
    Name = "Experiments Apps IGW"
  }
}

# Create a route table and associate it with the public subnet
resource "aws_route_table" "experiments_apps_public_route_table" {
  vpc_id = aws_vpc.experiments_apps_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # Route all outbound traffic to the internet
    gateway_id = aws_internet_gateway.experiments_apps_igw.id
  }

  tags = {
    Name = "Experiments Apps Public Route Table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "experiments_apps_public_route_table_association_a" {
  subnet_id      = aws_subnet.experiments_apps_subnet_public_a.id
  route_table_id = aws_route_table.experiments_apps_public_route_table.id
}
resource "aws_route_table_association" "experiments_apps_public_route_table_association_b" {
  subnet_id      = aws_subnet.experiments_apps_subnet_public_b.id
  route_table_id = aws_route_table.experiments_apps_public_route_table.id
}
