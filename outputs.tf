output "endpoints" {
  description = "API server endpoint for each cluster."
  value       = { for name, c in kind_cluster.this : name => c.endpoint }
}

output "kubeconfig_paths" {
  description = "Kubeconfig file written for each cluster."
  value       = { for name, c in kind_cluster.this : name => c.kubeconfig_path }
}

output "argocd_admin_password" {
  description = "Initial Argo CD admin password."
  value       = data.kubernetes_secret_v1.argocd_initial_admin.data["password"]
  sensitive   = true
}
