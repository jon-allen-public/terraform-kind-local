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
| [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) | Manages clusters outside Terraform, e.g. `kind delete cluster --name dev-apps` |
| [Checkov](https://www.checkov.io/) (optional)        | Runs the same scan as CI: `checkov --config-file .checkov.yaml` |

Terraform doesn't use the `kind` CLI (the provider bundles its own kind), so its
version doesn't need to match.

## Layout

```
root.hcl                    # shared Terragrunt config (local state, node_image)
modules/kind-cluster/       # one kind cluster
modules/argocd/             # Argo CD Helm release + workload cluster registration
live/mgmt/cluster/          # unit: Argo CD management cluster (only one, ever)
live/mgmt/argocd/           # unit: Argo CD, registers every env's workload cluster
live/dev/env.hcl            # per-env settings (env name, workers)
live/dev/apps/              # unit: dev workload cluster
```

Each unit has its own state under `.state/`. `mgmt` is shared, not an
environment: there's a single Argo CD that manages every env's workload cluster.

## Usage

```sh
tfenv install
tgenv install
cd live
terragrunt run --all apply
```

This creates the management cluster plus one workload cluster per environment:

| Cluster  | Purpose                                   | Workers (default) |
|----------|-------------------------------------------|-------------------|
| `argocd` | Argo CD management cluster (Helm install) | 1                 |
| `dev-apps` | dev workload cluster, registered in Argo CD as `dev-apps` | 2 |

Kubeconfigs are written to `~/.kube/config.d/kind-<name>.yaml`:

```sh
kubectl --kubeconfig ~/.kube/config.d/kind-dev-apps.yaml get nodes
```

To pick them up automatically, add this to your shell profile (e.g. `~/.zshrc`):

```sh
# Kubeconfig
export KUBECONFIG="$HOME/.kube/config"
for i in $(ls ~/.kube/config.d/); do
    export KUBECONFIG="$KUBECONFIG:$HOME/.kube/config.d/$i"
done
```

Then switch clusters with `kubectl config use-context kind-dev-apps` (or `kind-argocd`).

### Argo CD

```sh
(cd live/mgmt/argocd && terragrunt output -raw admin_password)
kubectl --kubeconfig ~/.kube/config.d/kind-argocd.yaml -n argocd port-forward svc/argocd-server 8080:443
```

Open https://localhost:8080 and log in as `admin`. Each env's workload cluster appears
under Settings → Clusters (e.g. `dev-apps` at `https://dev-apps-control-plane:6443`);
target it from an Application with `destination.name: dev-apps`.

### Configuration

Settings are Terragrunt `inputs`:

| Input           | Set in                             | Default                | Description                       |
|-----------------|------------------------------------|------------------------|-----------------------------------|
| `node_image`    | `root.hcl`                         | `kindest/node:v1.33.1` | Node image for all clusters       |
| `workers`       | `live/mgmt/cluster/terragrunt.hcl`, `live/<env>/env.hcl` (`apps_workers`) | `1` (argocd), `2` (dev-apps) | Worker nodes per cluster |
| `chart_version` | `live/mgmt/argocd/terragrunt.hcl` (not set) | `null` (latest) | argo-cd Helm chart version to pin |

### Adding an environment

1. Copy `live/dev` to `live/<env>` and set `env` in its `env.hcl`. The cluster is
   named `<env>-apps` (kind names must be unique per Docker host).
2. In `live/mgmt/argocd/terragrunt.hcl`, add a `dependency` block for
   `../../<env>/apps` and an entry in `workload_clusters`.
3. `cd live && terragrunt run --all apply`

To apply a single env, run `terragrunt run --all apply` from `live/<env>`, then
apply `live/mgmt/argocd` so Argo CD picks up the (re)created cluster's certs.
Before destroying an env, remove it from `live/mgmt/argocd` first.

Tear down with `cd live && terragrunt run --all destroy`.
