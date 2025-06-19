output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "staging_namespace" {
  value = kubernetes_namespace.staging.metadata[0].name
}

output "prod_namespace" {
  value = kubernetes_namespace.prod.metadata[0].name
}