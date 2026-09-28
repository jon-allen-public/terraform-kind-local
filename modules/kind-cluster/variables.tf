variable "name" {
  description = "Name of the kind cluster."
  type        = string
}

variable "node_image" {
  description = "kindest/node image used for all cluster nodes."
  type        = string
  default     = "kindest/node:v1.33.1"
}

variable "workers" {
  description = "Number of worker nodes."
  type        = number
  default     = 1
}

variable "kubeconfig_path" {
  description = "Where to write the kubeconfig. null writes ~/.kube/config.d/kind-<name>.yaml."
  type        = string
  default     = null
}
