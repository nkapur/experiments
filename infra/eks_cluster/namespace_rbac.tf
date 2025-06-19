# Prod Namespace RBAC for prod_service_user and a@b.com
resource "kubernetes_role" "prod_role" {
  metadata {
    name      = "prod-role"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "deployments", "replicasets", "namespaces"]
    verbs      = ["get", "list", "create", "update", "delete"]
  }
}

resource "kubernetes_role_binding" "prod_role_binding" {
  metadata {
    name      = "prod-role-binding"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "prod-service-user"  # IAM user name for prod service
    api_group = ""
  }

  role_ref {
    kind     = "Role"
    name     = kubernetes_role.prod_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# Staging Namespace RBAC for staging_user and b@c.com
resource "kubernetes_role" "staging_role" {
  metadata {
    name      = "staging-role"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "deployments", "replicasets", "namespaces"]
    verbs      = ["get", "list", "create", "update", "delete"]
  }
}

resource "kubernetes_role_binding" "staging_role_binding" {
  metadata {
    name      = "staging-role-binding"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "staging-user"  # IAM user name for staging user
    api_group = ""
  }

  role_ref {
    kind     = "Role"
    name     = kubernetes_role.staging_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
