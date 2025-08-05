################################################################################
# IAM Role and Service Account for Controller (IRSA)
################################################################################

# Get OIDC provider for EKS cluster
data "tls_certificate" "eks_oidc_issuer" {
  url = var.eks_cluster_oidc_issuer_url
}

data "aws_iam_openid_connect_provider" "eks" {
  url = var.eks_cluster_oidc_issuer_url
}


resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "AmazonEKSLoadBalancerControllerRole-${var.eks_cluster_name}"
  description = "IAM role for AWS Load Balancer Controller to manage ALBs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.eks_cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn"               = aws_iam_role.aws_load_balancer_controller.arn
      "eks.amazonaws.com/audience"               = "sts.amazonaws.com"
      "eks.amazonaws.com/token-expiration-minutes" = "86400"
    }
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }

  # Ensure the OIDC provider is created before the service account tries to assume the role
  depends_on = [data.aws_iam_openid_connect_provider.eks]
}