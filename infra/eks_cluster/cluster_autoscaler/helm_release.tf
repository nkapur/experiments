resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.36.0"

  # Values to configure the chart for AWS
  set = [
    {
      name  = "cloudProvider"
      value = "aws"
    },

    {
      name  = "autoDiscovery.clusterName"
      value = var.eks_cluster_name
    },

    {
      name  = "awsRegion"
      value = var.aws_region
    },

    {
      name  = "rbac.serviceAccount.create"
      value = "true"
    },

    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },

    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.cluster_autoscaler_role.arn
    },

    # --- Add this block to set the priority ---
    {
      name  = "priorityClassName"
      value = "system-cluster-critical"
    }
  ]

  # ✅ If the install fails, automatically clean up the release
  atomic  = true

  # Wait for the pods to become ready before marking the install as successful
  wait    = true

  # Give it enough time to start up
  timeout = 600
}
