include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//kind-cluster"
}

inputs = {
  name    = "apps"
  workers = 2
}
