locals {
  kubeconfig_path = coalesce(var.kubeconfig_path, pathexpand("~/.kube/config.d/kind-${var.name}.yaml"))
}

resource "kind_cluster" "this" {
  name            = var.name
  node_image      = var.node_image
  wait_for_ready  = true
  kubeconfig_path = local.kubeconfig_path

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    dynamic "node" {
      for_each = range(var.workers)
      content {
        role = "worker"
      }
    }
  }
}
