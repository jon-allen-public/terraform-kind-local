output "name" {
  description = "Cluster name."
  value       = kind_cluster.this.name
}

output "endpoint" {
  description = "Host-mapped API server endpoint."
  value       = kind_cluster.this.endpoint
}

output "kubeconfig_path" {
  description = "Kubeconfig file written for the cluster."
  value       = kind_cluster.this.kubeconfig_path
}

output "client_certificate" {
  description = "Client certificate (PEM)."
  value       = kind_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key (PEM)."
  value       = kind_cluster.this.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (PEM)."
  value       = kind_cluster.this.cluster_ca_certificate
  sensitive   = true
}
