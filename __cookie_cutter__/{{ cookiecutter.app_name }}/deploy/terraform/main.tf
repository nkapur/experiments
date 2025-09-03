# Configure the Terraform backend
terraform {
  backend "s3" {
    bucket = "{{ cookiecutter.terraform_backend_bucket }}"
    key    = "app/{{ cookiecutter.app_name }}/terraform.tfstate"
    region = "us-west-2"
  }
}

# Invoke the shared module from your central repository
module "fastapi_service" {
  # You can point to a local path, but a Git URL is best practice
  source = "git::https://github.com/nkapur/platform-modules.git//app_platform/terraform_modules/fastapi_service?ref=v0.0.5"

  # --- Provide app-specific configuration ---
  app_name         = "{{ cookiecutter.app_name }}"
  project_slug     = "{{ cookiecutter.project_slug }}"
  deployment_mode  = "staging"
  base_domain      = "{{ cookiecutter.base_domain }}"
  k8s_cluster_name = "{{ cookiecutter.k8s_cluster_name }}"
}

output "ecr_repository_url" {
  value = module.fastapi_service.ecr_repository_url
}

