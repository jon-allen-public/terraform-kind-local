include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules//argocd"
}

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
  config_path                             = "../clusters/argocd"
  mock_outputs                            = local.mock_cluster
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "apps" {
  config_path                             = "../clusters/apps"
  mock_outputs                            = local.mock_cluster
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  management = {
    endpoint               = dependency.mgmt.outputs.endpoint
    client_certificate     = dependency.mgmt.outputs.client_certificate
    client_key             = dependency.mgmt.outputs.client_key
    cluster_ca_certificate = dependency.mgmt.outputs.cluster_ca_certificate
  }

  # Add a dependency block and an entry here for each workload cluster.
  workload_clusters = {
    (dependency.apps.outputs.name) = {
      client_certificate     = dependency.apps.outputs.client_certificate
      client_key             = dependency.apps.outputs.client_key
      cluster_ca_certificate = dependency.apps.outputs.cluster_ca_certificate
    }
  }
}
