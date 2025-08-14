variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the EKS cluster is located."
  type        = string
  default     = "us-west-2"
}
