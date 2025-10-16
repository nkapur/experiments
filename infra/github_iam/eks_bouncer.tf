
# 1. Get a list of all IAM user names in the account.
data "aws_iam_users" "all_users" {}

# 2. For each user name, fetch its detailed information, including tags.
#    The `for_each` meta-argument iterates over the set of user names.
data "aws_iam_user" "user_details" {
  for_each  = data.aws_iam_users.all_users.names
  user_name = each.key
}

locals {
  tag_key = "agent_user"
  tag_value = "developer"

  # 3. Filter the users and output the ARNs of those who have the target tag.
  #    This `for` expression iterates through the user details we fetched.
  #    The `if` clause checks if the user's tags map contains the target key-value pair.
  developer_arns = [
    for user in data.aws_iam_user.user_details : user.arn
    if lookup(user.tags, local.tag_key, "") == local.tag_value
  ]
  service_arns = [
              "arn:aws:iam::396724649279:user/staging-service-user",
              "arn:aws:iam::396724649279:user/prod-service-user"
  ]
  developer_and_service_arns = concat(local.developer_arns, local.service_arns)
}


######################################################################
# IAM Role for EKS startup and tear-down
######################################################################
resource "aws_iam_role" "github_eks_bouncer" {
    name               = "github-eks-bouncer"
    assume_role_policy = local.github_oidc_assume_role_policy
    description        = "IAM role for GitHub Actions to deploy/destroy the EKS cluster"
}

######################################################################
# Attach Required Permissions
######################################################################

# These two policies are well-scoped and necessary for the EKS service itself.
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.github_eks_bouncer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.github_eks_bouncer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# It contains only the specific permissions needed by the Terraform EKS module.
resource "aws_iam_role_policy" "eks_creation_policy" {
  name = "EKSCreationAndStatePolicy"
  role = aws_iam_role.github_eks_bouncer.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
          Effect = "Allow",
          Action = [
            "iam:GetUser",
            "iam:ListGroupsForUser",
            "iam:ListAttachedUserPolicies",
            "iam:ListPoliciesForUser",
            "iam:ListUserTags",
            "iam:TagUser",
            "iam:UntagUser",
            "iam:AttachUserPolicy",
            "iam:DetachUserPolicy",
            "iam:PutUserPolicy",
          ],
          Resource = local.developer_and_service_arns
      },
      {
        Effect = "Allow",
        Action = [
          # Permissions for creating networking resources (VPC, Subnets, SG)
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateTags",
          "ec2:DescribeTags",
          "ec2:DeleteTags",
          # Permissions for creating EKS Node Groups and their instances
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroupRules",
          "ec2:CreateLaunchTemplate",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DeleteLaunchTemplate",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          # EKS
          "eks:CreateCluster",
          "eks:TagResource",
          "eks:DescribeCluster",
          "eks:DeleteCluster",
          "eks:CreateAccessEntry",
          "eks:DeleteAccessEntry",
          "eks:DescribeAccessEntry",
          "eks:CreateNodegroup",
          "eks:DeleteNodegroup",
          "eks:DescribeNodegroup",
          "eks:AssociateAccessPolicy",
          "eks:DisassociateAccessPolicy",
          "eks:ListAssociatedAccessPolicies",
          "eks:CreateAddon",
          "eks:DescribeAddon",
          "eks:ListAddons",
          "eks:UpdateAddon",
          "eks:DeleteAddon",
          # EKS uses CloudFormation to create node groups
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          # Permissions for creating IAM roles for the cluster/nodes
          "iam:GetRole",
          "iam:CreateRole",
          "iam:CreateUser",
          "iam:DeleteRole",
          "iam:DeleteUser",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:ListRolePolicies",
          "iam:ListPolicyVersions",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:ListInstanceProfilesForRole",
          # Permissions for CloudWatch Log Group
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "logs:TagResource",
          "logs:PutRetentionPolicy",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          # KMS
          "kms:TagResource",
          "kms:CreateKey",
          "kms:CreateAlias",
          "kms:ListAliases",
          "kms:DeleteAlias",
          "kms:DeleteKey"
        ],
        Resource = "*"
      },
      # Read-only access to all state files in the infra/ directory
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::experiments-infra-state/infra/*"
      },
      # Write access limited to ONLY the EKS state file
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::experiments-infra-state/infra/eks_cluster/terraform.tfstate"
      },
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "arn:aws:s3:::experiments-infra-state"
      },
      # Permissions for Terraform State Lock DynamoDB Table
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "arn:aws:dynamodb:*:*:table/terraform-locks"
      }
    ]
  })
}


# Output the ARN to easily add it to GitHub Secrets
output "github_actions_role_arn" {
  value       = aws_iam_role.github_eks_bouncer.arn
  description = "The ARN of the IAM role for GitHub Actions"
}

output "developer_and_service_arns" {
  value = local.developer_and_service_arns
}
