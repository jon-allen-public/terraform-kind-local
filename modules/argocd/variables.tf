variable "management" {
  description = "Connection details (PEM) for the cluster Argo CD is installed into."
  type = object({
    endpoint               = string
    client_certificate     = string
    client_key             = string
    cluster_ca_certificate = string
  })
  sensitive = true
}

variable "workload_clusters" {
  description = "Kind clusters to register with Argo CD, keyed by cluster name. Values are PEM."
  type = map(object({
    client_certificate     = string
    client_key             = string
    cluster_ca_certificate = string
  }))
  # Not marked sensitive: its keys drive for_each, which rejects sensitive values.
  default = {}
}

variable "chart_version" {
  description = "argo-cd Helm chart version. null installs the latest release."
  type        = string
  default     = null
}
