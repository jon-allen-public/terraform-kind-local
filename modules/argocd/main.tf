resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  wait             = true
}

# Registers each workload cluster with Argo CD as a declarative cluster secret.
# Kind nodes share the "kind" Docker network, so Argo CD reaches each API
# server by its control-plane container name rather than the host port.
resource "kubernetes_secret_v1" "cluster" {
  for_each = var.workload_clusters

  metadata {
    name      = "cluster-${each.key}"
    namespace = helm_release.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name   = each.key
    server = "https://${each.key}-control-plane:6443"
    config = jsonencode({
      tlsClientConfig = {
        caData   = base64encode(each.value.cluster_ca_certificate)
        certData = base64encode(each.value.client_certificate)
        keyData  = base64encode(each.value.client_key)
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
