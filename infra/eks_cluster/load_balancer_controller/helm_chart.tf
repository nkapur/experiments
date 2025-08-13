################################################################################
# 4. Deploy AWS Load Balancer Controller Helm Chart
################################################################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "experiments-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.4" # Check the latest stable version: https://github.com/aws/eks-charts/releases

  set = [
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false" # We manage the service account with Terraform
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    }
  ]

  # ✅ If the install fails, automatically clean up the release
  atomic  = true

  # Wait for the pods to become ready before marking the install as successful
  wait    = true

  # Give it enough time to start up
  timeout = 600

  # Ensure that the IAM role and service account are fully created before Helm tries to deploy
  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller,
    kubernetes_service_account.aws_load_balancer_controller,
    data.aws_iam_openid_connect_provider.eks
  ]
}