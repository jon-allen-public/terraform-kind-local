include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//kind-cluster"
}

inputs = {
  name    = "argocd"
  workers = 1
}
