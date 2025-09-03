# Configure the Terraform backend
terraform {
  backend "s3" {
    bucket = "experiments-infra-state"
    key    = "app/soothe/terraform.tfstate"
    region = "us-west-2"
  }
}

# Invoke the shared module from your central repository
module "fastapi_service" {
  # You can point to a local path, but a Git URL is best practice
  source = "git::https://github.com/nkapur/platform-modules.git//app_platform/terraform_modules/fastapi_service?ref=v0.0.5"

  # --- Provide app-specific configuration ---
  app_name         = "soothe"
  project_slug     = "soothe"
  deployment_mode  = "staging"
  base_domain      = "navneetkapur.com"
  k8s_cluster_name = "experiments-kube-cluster"
}

output "ecr_repository_url" {
  value = module.fastapi_service.ecr_repository_url
}

