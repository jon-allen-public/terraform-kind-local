# terraform-kind-local
Run a local kind k8s cluster through terraform

## Usage

Requires Docker, Terraform >= 1.5.

```sh
terraform init
terraform apply
```

This creates two clusters:

| Cluster  | Purpose                                   | Workers (default) |
|----------|-------------------------------------------|-------------------|
| `argocd` | Argo CD management cluster (Helm install) | 1                 |
| `apps`   | Workload cluster, registered in Argo CD as `apps` | 2         |

Kubeconfigs are written to `~/.kube/kind-<name>.yaml`:

```sh
kubectl --kubeconfig ~/.kube/kind-apps.yaml get nodes
```

### Argo CD

```sh
terraform output -raw argocd_admin_password
kubectl --kubeconfig ~/.kube/kind-argocd.yaml -n argocd port-forward svc/argocd-server 8080:443
```

Open https://localhost:8080 and log in as `admin`. The `apps` cluster appears
under Settings → Clusters (server `https://apps-control-plane:6443`); target it
from an Application with `destination.name: apps`.

### Variables

| Name                   | Default                | Description                       |
|------------------------|------------------------|-----------------------------------|
| `node_image`           | `kindest/node:v1.33.1` | Node image for all clusters       |
| `argocd_workers`       | `1`                    | Workers in the argocd cluster     |
| `apps_workers`         | `2`                    | Workers in the apps cluster       |
| `argocd_chart_version` | `null` (latest)        | argo-cd Helm chart version to pin |

Tear down with `terraform destroy`.
