terraform {
  required_version = ">= 1.5"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
  }
}

# Both providers target the Argo CD management cluster.
provider "helm" {
  kubernetes = {
    host                   = var.management.endpoint
    client_certificate     = var.management.client_certificate
    client_key             = var.management.client_key
    cluster_ca_certificate = var.management.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = var.management.endpoint
  client_certificate     = var.management.client_certificate
  client_key             = var.management.client_key
  cluster_ca_certificate = var.management.cluster_ca_certificate
}
