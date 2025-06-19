resource "kubernetes_network_policy" "prod_policy" {
  metadata {
    name      = "prod-policy"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "name" = "prod"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 80
      }
    }
  }
}

resource "kubernetes_network_policy" "staging_policy" {
  metadata {
    name      = "staging-policy"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "name" = "staging"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 80
      }
    }
  }
}