output "admin_password" {
  description = "Initial Argo CD admin password."
  value       = data.kubernetes_secret_v1.argocd_initial_admin.data["password"]
  sensitive   = true
}
