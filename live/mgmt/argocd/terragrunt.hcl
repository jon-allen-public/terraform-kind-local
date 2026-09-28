include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//argocd"
}

# The single Argo CD install. It lives on the management cluster and registers
# every environment's workload cluster.

# Mocks let validate/plan run before the clusters exist.
locals {
  mock_cluster = {
    name                   = "mock"
    endpoint               = "https://127.0.0.1:6443"
    client_certificate     = "mock"
    client_key             = "mock"
    cluster_ca_certificate = "mock"
  }
}

dependency "mgmt" {
  config_path                             = "../cluster"
  mock_outputs                            = local.mock_cluster
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# One dependency per environment's workload cluster. Mock names must be
# unique, since they become workload_clusters keys during plan.
dependency "dev_apps" {
  config_path                             = "../../dev/apps"
  mock_outputs                            = merge(local.mock_cluster, { name = "dev-apps" })
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  management = {
    endpoint               = dependency.mgmt.outputs.endpoint
    client_certificate     = dependency.mgmt.outputs.client_certificate
    client_key             = dependency.mgmt.outputs.client_key
    cluster_ca_certificate = dependency.mgmt.outputs.cluster_ca_certificate
  }

  # Add a dependency block and an entry here for each environment.
  workload_clusters = {
    (dependency.dev_apps.outputs.name) = {
      client_certificate     = dependency.dev_apps.outputs.client_certificate
      client_key             = dependency.dev_apps.outputs.client_key
      cluster_ca_certificate = dependency.dev_apps.outputs.cluster_ca_certificate
    }
  }
}
