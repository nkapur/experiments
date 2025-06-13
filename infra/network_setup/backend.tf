terraform {
  backend "s3" {
    bucket         = "experiments-infra-state"
    key            = "infra/network_setup/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"   # Optional for state locking
    encrypt        = true
  }
}
