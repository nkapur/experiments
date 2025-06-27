terraform {
  backend "s3" {
    bucket         = "experiments-infra-state"
    key            = "infra/fastapi_test/kube/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"   # Optional for state locking
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

