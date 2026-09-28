terraform {
  required_version = ">= 1.5"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.9"
    }
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

provider "kind" {}

# Both providers target the Argo CD management cluster.
provider "helm" {
  kubernetes = {
    host                   = kind_cluster.this["argocd"].endpoint
    client_certificate     = kind_cluster.this["argocd"].client_certificate
    client_key             = kind_cluster.this["argocd"].client_key
    cluster_ca_certificate = kind_cluster.this["argocd"].cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = kind_cluster.this["argocd"].endpoint
  client_certificate     = kind_cluster.this["argocd"].client_certificate
  client_key             = kind_cluster.this["argocd"].client_key
  cluster_ca_certificate = kind_cluster.this["argocd"].cluster_ca_certificate
}
