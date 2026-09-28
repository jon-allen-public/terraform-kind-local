locals {
  clusters = {
    argocd = { workers = var.argocd_workers }
    apps   = { workers = var.apps_workers }
  }
}

resource "kind_cluster" "this" {
  for_each = local.clusters

  name            = each.key
  node_image      = var.node_image
  wait_for_ready  = true
  kubeconfig_path = pathexpand("~/.kube/kind-${each.key}.yaml")

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    dynamic "node" {
      for_each = range(each.value.workers)
      content {
        role = "worker"
      }
    }
  }
}
