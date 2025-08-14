# This data source retrieves information about your existing EKS cluster.
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

# This data source retrieves the OIDC provider associated with your EKS cluster.
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# 1. IAM Policy: Defines what the Cluster Autoscaler is allowed to do.
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "${var.eks_cluster_name}-cluster-autoscaler-policy"
  description = "Permissions for the EKS Cluster Autoscaler"

  # Policy document with required permissions
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            # This condition ensures the autoscaler can only modify ASGs
            # that are tagged for this specific cluster.
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"             = "true",
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}

# 2. IAM Role: Defines who can assume the role (the "Trust Policy").
resource "aws_iam_role" "cluster_autoscaler_role" {
  name = "${var.eks_cluster_name}-cluster-autoscaler-role"

  # This is the trust policy for IRSA (IAM Roles for Service Accounts).
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          # Trusts the EKS OIDC provider.
          Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            # This condition limits the role to a specific service account.
            # The format is "OIDC_PROVIDER_URL:sub": "system:serviceaccount:NAMESPACE:SERVICE_ACCOUNT_NAME"
            "${replace(data.aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
}

# 3. Policy Attachment: Connects the policy to the role.
resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attachment" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role       = aws_iam_role.cluster_autoscaler_role.name
}
