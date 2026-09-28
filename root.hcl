# Shared config included by every unit under live/.

# Terragrunt runs tofu if it's installed; this repo pins Terraform via tfenv.
terraform_binary = "terraform"

# Local state per unit, kept out of .terragrunt-cache so it survives cache clears.
remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/.state/${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  node_image = "kindest/node:v1.33.1"
}
