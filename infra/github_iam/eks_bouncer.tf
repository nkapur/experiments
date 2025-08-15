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
  name = "EKSCreationPolicy"
  role = aws_iam_role.github_eks_bouncer.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          # Permissions for creating networking resources (VPC, Subnets, SG)
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateTags",
          # Permissions for creating EKS Node Groups and their instances
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          # EKS uses CloudFormation to create node groups
          "cloudformation:CreateStack",
          "cloudformation:DescribeStacks",
          # Permissions for creating IAM roles for the cluster/nodes
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:PassRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ],
        Resource = "*"
      }
    ]
  })
}


# Output the ARN to easily add it to GitHub Secrets
output "github_actions_role_arn" {
  value       = aws_iam_role.github_eks_bouncer.arn
  description = "The ARN of the IAM role for GitHub Actions"
}
