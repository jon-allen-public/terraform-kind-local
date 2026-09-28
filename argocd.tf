resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  wait             = true
}

# Registers the apps cluster with Argo CD as a declarative cluster secret.
# Kind nodes share the "kind" Docker network, so Argo CD reaches the apps
# API server by its control-plane container name rather than the host port.
resource "kubernetes_secret_v1" "apps_cluster" {
  metadata {
    name      = "cluster-apps"
    namespace = helm_release.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name   = "apps"
    server = "https://${kind_cluster.this["apps"].name}-control-plane:6443"
    config = jsonencode({
      tlsClientConfig = {
        caData   = base64encode(kind_cluster.this["apps"].cluster_ca_certificate)
        certData = base64encode(kind_cluster.this["apps"].client_certificate)
        keyData  = base64encode(kind_cluster.this["apps"].client_key)
      }
    })
  }
}

data "kubernetes_secret_v1" "argocd_initial_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = helm_release.argocd.namespace
  }
}
