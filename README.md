# terraform-kind-local
Run local kind k8s clusters through Terraform and Terragrunt

## Dependencies

| Tool                                                 | Purpose                                              |
|------------------------------------------------------|------------------------------------------------------|
| [Docker](https://docs.docker.com/get-docker/)        | Runs the kind cluster nodes                          |
| [tfenv](https://github.com/tfutils/tfenv)            | Installs and switches Terraform versions             |
| [Terraform](https://developer.hashicorp.com/terraform) >= 1.5 | Provisions the clusters; `tfenv install` picks up the pinned version from `.terraform-version` |
| [tgenv](https://github.com/tgenv/tgenv)              | Installs and switches Terragrunt versions            |
| [Terragrunt](https://terragrunt.gruntwork.io/)       | Orchestrates the units; `tgenv install` picks up the pinned version from `.terragrunt-version` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/)   | Talks to the clusters                                |
| [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) | Manages clusters outside Terraform, e.g. `kind delete cluster --name apps` |
| [Checkov](https://www.checkov.io/) (optional)        | Runs the same scan as CI: `checkov --config-file .checkov.yaml` |

Terraform doesn't use the `kind` CLI (the provider bundles its own kind), so its
version doesn't need to match.

## Layout

```
root.hcl                    # shared Terragrunt config (local state, node_image)
modules/kind-cluster/       # one kind cluster
modules/argocd/             # Argo CD Helm release + workload cluster registration
live/clusters/argocd/       # unit: Argo CD management cluster
live/clusters/apps/         # unit: apps workload cluster
live/argocd/                # unit: Argo CD, depends on both clusters
```

Each unit has its own state under `.state/`.

## Usage

```sh
tfenv install
tgenv install
cd live
terragrunt run --all apply
```

This creates two clusters:

| Cluster  | Purpose                                   | Workers (default) |
|----------|-------------------------------------------|-------------------|
| `argocd` | Argo CD management cluster (Helm install) | 1                 |
| `apps`   | Workload cluster, registered in Argo CD as `apps` | 2         |

Kubeconfigs are written to `~/.kube/config.d/kind-<name>.yaml`:

```sh
kubectl --kubeconfig ~/.kube/config.d/kind-apps.yaml get nodes
```

To pick them up automatically, add this to your shell profile (e.g. `~/.zshrc`):

```sh
# Kubeconfig
export KUBECONFIG="$HOME/.kube/config"
for i in $(ls ~/.kube/config.d/); do
    export KUBECONFIG="$KUBECONFIG:$HOME/.kube/config.d/$i"
done
```

Then switch clusters with `kubectl config use-context kind-apps` (or `kind-argocd`).

### Argo CD

```sh
(cd live/argocd && terragrunt output -raw admin_password)
kubectl --kubeconfig ~/.kube/config.d/kind-argocd.yaml -n argocd port-forward svc/argocd-server 8080:443
```

Open https://localhost:8080 and log in as `admin`. The `apps` cluster appears
under Settings → Clusters (server `https://apps-control-plane:6443`); target it
from an Application with `destination.name: apps`.

### Configuration

Settings are Terragrunt `inputs`:

| Input           | Set in                             | Default                | Description                       |
|-----------------|------------------------------------|------------------------|-----------------------------------|
| `node_image`    | `root.hcl`                         | `kindest/node:v1.33.1` | Node image for all clusters       |
| `workers`       | `live/clusters/<name>/terragrunt.hcl` | `1` (argocd), `2` (apps) | Worker nodes per cluster     |
| `chart_version` | `live/argocd/terragrunt.hcl` (not set) | `null` (latest)    | argo-cd Helm chart version to pin |

### Adding a workload cluster

1. Copy `live/clusters/apps` to `live/clusters/<name>` and set `name` in its inputs.
2. In `live/argocd/terragrunt.hcl`, add a `dependency` block for it and an entry
   in `workload_clusters`.
3. `cd live && terragrunt run --all apply`

Tear down with `cd live && terragrunt run --all destroy`.
