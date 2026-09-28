variable "node_image" {
  description = "kindest/node image used for all cluster nodes."
  type        = string
  default     = "kindest/node:v1.33.1"
}

variable "argocd_workers" {
  description = "Number of worker nodes in the Argo CD management cluster."
  type        = number
  default     = 1
}

variable "apps_workers" {
  description = "Number of worker nodes in the apps cluster."
  type        = number
  default     = 2
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version. null installs the latest release."
  type        = string
  default     = null
}
