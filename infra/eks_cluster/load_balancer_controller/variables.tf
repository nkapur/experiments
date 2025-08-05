variable "eks_cluster_name" {
  description = "The name of your EKS cluster."
  type        = string
}
variable "eks_cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for your EKS cluster."
  type        = string
}

# Add other variables like public/private subnet IDs here
variable "public_subnet_ids" {
  type = list(string)
}
variable "private_subnet_ids" {
  type = list(string)
}