resource "aws_eks_access_entry" "app_deployer_access_entry_staging" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.app_deployer_role_staging.arn
  type          = "STANDARD"

  access_policies = {
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy" = {
      access_scope = {
        type = "cluster"
      }
    }
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy" = {
      access_scope = {
        type       = "namespace"
        namespaces = ["staging"]
      }
    }
  }
}

resource "aws_eks_access_entry" "app_deployer_access_entry_prod" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.app_deployer_role_prod.arn
  type          = "STANDARD"

  access_policies = {
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy" = {
      access_scope = {
        type = "cluster"
      }
    }
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy" = {
      access_scope = {
        type       = "namespace"
        namespaces = ["prod"]
      }
    }
  }
}
