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
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.0"

  cluster_name    = "experiments-kube-cluster"
  cluster_version = "1.31"

  vpc_id     = data.terraform_remote_state.experiments_apps_network.outputs.vpc_id
  subnet_ids = [
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_a,
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_b
  ]

  enable_cluster_creator_admin_permissions = true

  # By default, the EKS module will create and manage the necessary IAM roles
  # for the node groups. This is the recommended approach.
  # The module automatically attaches the required policies:
  # - AmazonEKSWorkerNodePolicy
  # - AmazonEKS_CNI_Policy
  # - AmazonEC2ContainerRegistryReadOnly
  eks_managed_node_groups = {
    worker_compute = {
      # This node group will now use the IAM role created by the module above
      desired_size = 1
      max_size     = 4
      min_size     = 1

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"] # Corrected: Only one declaration
      key_name       = "eks_experiments_cluster_key"
      capacity_type  = "SPOT"

      # Optional: Tags for node groups
      tags = {
        Name = "experiments-eks-node"
      }
    }
  }

  # --- Optional: Add tags for better resource management ---
  tags = {
    Project     = "Apps in Experiments Repo"
    Environment = "Staging and Production Isolated by Namespace"
    ManagedBy   = "Terraform"
  }

  # --- Optional: Enable cluster logging (recommended for production) ---
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
