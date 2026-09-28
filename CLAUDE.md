# CLAUDE.md

Terraform modules orchestrated by Terragrunt that run local kind clusters: one
shared `argocd` management cluster, plus one workload cluster per environment
(`<env>-apps`, currently only `dev`) managed by that single Argo CD.

## Layout

- `root.hcl`: included by every unit. Forces `terraform_binary = "terraform"`
  (Terragrunt would use `tofu` if installed), generates a local backend with
  state at `.state/<unit path>/terraform.tfstate`, sets shared `node_image`.
- `modules/kind-cluster`: one `kind_cluster`. Outputs endpoint and PEM certs
  (sensitive) for other units.
- `modules/argocd`: `argo-cd` Helm release, one declarative Argo CD cluster
  secret per entry in `workload_clusters`, and a data source for the initial
  admin password. `helm`/`kubernetes` providers are configured from
  `var.management`.
- `live/mgmt/`: not an environment; there is only ever one. `cluster/` is the
  `argocd` kind cluster, `argocd/` is the Argo CD install. `argocd/` has a
  `dependency` block per env workload cluster (with `mock_outputs` for
  validate/plan; mock names must be unique) feeding `management` and
  `workload_clusters`.
- `live/<env>/env.hcl`: per-env locals (`env`, `apps_workers`), read by that
  env's units via `read_terragrunt_config`. `live/<env>/apps/` builds
  `<env>-apps` (env-prefixed: kind names are unique per Docker host).
- A new env needs a copy of `live/dev` plus a dependency and map entry in
  `live/mgmt/argocd`. Remove an env from there before destroying it.

## Conventions and gotchas

- Versions: Terraform pinned in `.terraform-version` (tfenv), Terragrunt in
  `.terragrunt-version` (tgenv). Providers: `tehcyx/kind` (~> 0.9),
  `hashicorp/helm` (~> 3.0; uses the `kubernetes = { ... }` attribute syntax,
  not the v2 block), `hashicorp/kubernetes` (~> 2.36).
- The kind provider embeds its own kind library; the installed `kind` CLI
  version does not matter, but `node_image` must be compatible with the
  provider's bundled kind.
- Changing `kubeconfig_path` or anything in `kind_config` forces cluster
  replacement.
- Argo CD reaches workload clusters over the shared `kind` Docker network at
  `https://<name>-control-plane:6443`, not the host-mapped endpoint. The TLS
  data is PEM from the cluster unit outputs, base64-encoded for the secret.
- `workload_clusters` must not be marked sensitive: its keys drive `for_each`.
- Clusters exist before the `mgmt/argocd` unit plans, so `kubernetes_manifest` is
  usable there, but mocked plans (`run --all plan` on a fresh setup) can't
  reach a real API. Prefer typed resources like `kubernetes_secret_v1` or Helm.
- Kubeconfigs are written to `~/.kube/config.d/kind-<name>.yaml`.
- `.state/`, `.terragrunt-cache/`, lock files and `*.tfvars` are gitignored;
  don't commit them.

## Commands

```sh
terraform fmt -recursive
terragrunt hcl fmt
cd live && terragrunt run --all validate
cd live && terragrunt run --all apply
cd live && terragrunt run --all destroy
cd live/mgmt/argocd && terragrunt output -raw admin_password
checkov --config-file .checkov.yaml   # same scan CI runs (modules/)
```

## CI

`.github/workflows/ci.yml` runs Checkov on pushes to `main` and on PRs; any
failed check fails the job. Suppress a check that doesn't apply by adding it
to `skip-check` in `.checkov.yaml` with a reason, or inline with
`#checkov:skip=CKV_XXX:reason` on the resource.

## Pull requests

PR descriptions follow `.github/pull_request_template.md`: fill in every
section and tick only the checks actually run. Reviewers come from
`.github/CODEOWNERS`.
