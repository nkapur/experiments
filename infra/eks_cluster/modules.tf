

module "cluster_autoscaler" {
  source = "./cluster_autoscaler"

  # Pass the necessary values from your main configuration to the module
  eks_cluster_name          = module.eks.cluster_name

  depends_on = [module.eks]
}

module "load_balancer_controller" {
  source = "./load_balancer_controller" # This tells Terraform to look in the sub-folder

  # Pass the necessary values from your main configuration to the module
  eks_cluster_name            = module.eks.cluster_name
  eks_cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  # Pass subnet IDs from your main VPC configuration
  public_subnet_ids           = [
    data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_a,
    data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_b
  ]
  private_subnet_ids          = [
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_a,
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_b
  ]

  depends_on                  = [module.eks, module.cluster_autoscaler]
}


variable "application_deployer_roles" {
  description = "A map of deployer roles to create. The key is a unique name for the role, and the value contains a list of namespaces for admin access."
  type = map(object({
    name       = string
    namespaces = list(string)
  }))
}

module "app_deployer" {
  source                      = "./app_deployer"
  eks_cluster_name            = module.eks.cluster_name
  deployer_roles              = var.application_deployer_roles
  depends_on                  = [module.eks]
}

output "created_deployer_role_arns" {
  description = "ARNs of the IAM roles created by the module."
  value       = module.app_deployer.deployer_role_arns
}