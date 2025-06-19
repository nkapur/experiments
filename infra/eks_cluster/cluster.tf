# Reference the remote state of the VPC and subnet module
data "terraform_remote_state" "experiments_apps_network" {
  backend = "s3"

  config = {
    bucket = "experiments-infra-state"
    key    = "infra/network_setup/terraform.tfstate"
    region = "us-west-2"
  }
}

module "eks" {
  # ALWAYS specify a module version to ensure consistent deployments.
  # Check the Terraform Registry for the latest stable versions:
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.37.0"
  cluster_name    = "experiments-kube-cluster"
  cluster_version = "1.31"

  # 'subnets' argument is replaced by 'vpc_private_subnets' and 'vpc_public_subnets'
  # It's typical for EKS worker nodes to be in private subnets.
  subnet_ids          = [
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_a,
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_b
  ]
  vpc_id              = data.terraform_remote_state.experiments_apps_network.outputs.vpc_id

  enable_cluster_creator_admin_permissions = true

  # 'node_groups' argument is replaced by 'managed_node_groups' for AWS Managed Node Groups
  # or 'self_managed_node_groups' for self-managed EC2 instances.
  # Managed Node Groups are generally recommended.
 eks_managed_node_groups = {
    worker_compute = {
      desired_size = 1
      max_size     = 4
      min_size     = 1

      ami_type          = "AL2023_x86_64_STANDARD"
      instance_types    = ["t3.medium"]
      key_name          = "eks_experiments_cluster_key"

      # Optional: Tags for node groups
      tags = {
        Name = "experiments-eks-node"
      }

      capacity_type      = "SPOT"
      enable_monitoring  = true
      instance_types     = ["t3.small"]  # Ensure this is an acceptable instance type for your region
    }
  }

  # --- Optional: If you need public subnets for public-facing resources (e.g., ALB) ---
  # Uncomment and provide the appropriate output from your network module if available
  # vpc_public_subnets = data.terraform_remote_state.experiments_apps_network.outputs.vpc_public_subnets

  # --- Optional: Add tags for better resource management ---
  tags = {
    Project     = "Apps in Experiments Repo"
    Environment = "Staging and Production Isolated by Namespace"
    ManagedBy   = "Terraform"
  }

  # --- Optional: Enable cluster logging (recommended for production) ---
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}