# Tag your public subnets for use by the ALB Controller for external ALBs.
# Replace with your actual public subnet IDs. You need at least two across different AZs.
resource "aws_ec2_tag" "public_subnet_alb_tag_1" {
  resource_id = var.public_subnet_ids[0]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_alb_tag_2" {
  resource_id = var.public_subnet_ids[1]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# (Optional, but recommended) Tag your public subnets for cluster association
# This tag is for EKS, but you will only want your Control Plane to see these.
# EKS worker nodes themselves should NOT be in these subnets.
resource "aws_ec2_tag" "public_subnet_cluster_tag_1" {
  resource_id = var.public_subnet_ids[0]
  key         = "kubernetes.io/cluster/${var.eks_cluster_name}"
  value       = "owned"
}

resource "aws_ec2_tag" "public_subnet_cluster_tag_2" {
  resource_id = var.public_subnet_ids[1]
  key         = "kubernetes.io/cluster/${var.eks_cluster_name}"
  value       = "owned"
}


# Tag your private subnets for use by EKS worker nodes.
# Replace with your actual private subnet IDs. You need at least two across different AZs.
resource "aws_ec2_tag" "private_subnet_cluster_tag_1" {
  resource_id = var.private_subnet_ids[0]
  key         = "kubernetes.io/cluster/${var.eks_cluster_name}"
  value       = "owned"
}

resource "aws_ec2_tag" "private_subnet_cluster_tag_2" {
  resource_id = var.private_subnet_ids[1]
  key         = "kubernetes.io/cluster/${var.eks_cluster_name}"
  value       = "owned"
}