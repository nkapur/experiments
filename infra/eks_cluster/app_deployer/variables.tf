variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "deployer_roles" {
  description = "A map of deployer roles to create. The key is a unique name for the role, and the value contains a list of namespaces for admin access."
  type = map(object({
    name       = string
    namespaces = list(string)
  }))
}
