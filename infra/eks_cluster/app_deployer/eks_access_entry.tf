resource "aws_eks_access_entry" "app_deployer_access_entry" {
  for_each = var.deployer_roles

  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.app_deployer_role[each.key].arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "app_deployer_view_policy" {
  for_each = var.deployer_roles

  cluster_name  = var.eks_cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = aws_iam_role.app_deployer_role[each.key].arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "app_deployer_admin_policy_for_namespace" {
  for_each = var.deployer_roles

  cluster_name  = var.eks_cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_iam_role.app_deployer_role[each.key].arn

  access_scope {
    type       = "namespace"
    namespaces = each.value.namespaces
  }
}

