# Replace these with your own values
variable "github_org" { default = "nkapur" }
variable "github_repo" { default = "experiments" }
variable "aws_region" { default = "us-west-2" }

terraform {
  backend "s3" {
    bucket         = "experiments-infra-state"
    key            = "infra/github-iam/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"   # Optional for state locking
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}


######################################################################
# OIDC Provider for GitHub Actions
######################################################################
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # This thumbprint may change, verify from GitHub documentation
  ]
}

locals {
  github_oidc_assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}


######################################################################
# Role for AMI creation/build workflows
######################################################################
resource "aws_iam_role" "github_ami_builder" {
  name = "github-ami-builder"
  assume_role_policy = local.github_oidc_assume_role_policy
}

resource "aws_iam_policy" "ami_builder_policy" {
  name = "ami-builder-policy"
  policy = file("./policies/ami_builder_policy.json")
}

resource "aws_iam_role_policy_attachment" "ami_builder_attach" {
  role       = aws_iam_role.github_ami_builder.name
  policy_arn = aws_iam_policy.ami_builder_policy.arn
}

######################################################################
# Role for AMI promotion workflows (e.g., tagging or SSM updates only)
######################################################################
resource "aws_iam_role" "github_ami_promoter" {
  name = "github-ami-promoter"
  assume_role_policy = local.github_oidc_assume_role_policy
}

resource "aws_iam_policy" "ami_promoter_policy" {
  name = "ami-promoter-policy"
  policy = file("./policies/ami_promoter_policy.json")
}

resource "aws_iam_role_policy_attachment" "ami_promoter_attach" {
  role       = aws_iam_role.github_ami_promoter.name
  policy_arn = aws_iam_policy.ami_promoter_policy.arn
}
