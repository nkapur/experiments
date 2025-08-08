# TODO (navneetkapur): Centralize provider configuration to remove
# duplication across modules and files.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"  # Specify your AWS region
}

data "aws_caller_identity" "current" {}

# variable "infra_identifier" {
#   type        = string
#   description = "Identifier for the infrastructure, e.g., 'personal_domain'"
#   default     = "personal_domain"
# }

# TODO (navneetkapur): Leverage Helm/Kustomize for s3 path management
terraform {
  backend "s3" {
    bucket         = "experiments-infra-state"
    key            = "infra/personal_domain/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"   # Optional for state locking
    encrypt        = true
  }
}