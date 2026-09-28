include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "../../../modules//kind-cluster"
}

# kind cluster names are unique per Docker host, so prefix with the env.
inputs = {
  name    = "${local.env.env}-apps"
  workers = local.env.apps_workers
}
