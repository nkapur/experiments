resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
}
