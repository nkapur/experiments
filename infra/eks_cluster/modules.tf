module "load_balancer_controller" {
  source = "./load_balancer_controller" # This tells Terraform to look in the sub-folder

  # Pass the necessary values from your main configuration to the module
  eks_cluster_name          = module.eks.cluster_name
  eks_cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  # Pass subnet IDs from your main VPC configuration
  public_subnet_ids = [
    data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_a,
    data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_b
  ]
  private_subnet_ids = [
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_a,
    data.terraform_remote_state.experiments_apps_network.outputs.private_subnet_id_b
  ]

  depends_on = [module.eks]
}