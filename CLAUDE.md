# CLAUDE.md

Terraform that runs two local kind clusters: `argocd` (Argo CD management
cluster) and `apps` (workload cluster managed by Argo CD).

## Layout

- `versions.tf`: Terraform/provider pins and provider config. `helm` and
  `kubernetes` providers are wired to `kind_cluster.this["argocd"]` only.
- `main.tf`: `kind_cluster.this`, `for_each` over `local.clusters`. The keys
  `argocd` and `apps` are referenced elsewhere; renaming them breaks provider
  config and `argocd.tf`.
- `argocd.tf`: `argo-cd` Helm release, plus a declarative Argo CD cluster
  secret that registers `apps`, and a data source for the initial admin password.
- `variables.tf`, `outputs.tf`: inputs and outputs (see README tables).

## Conventions and gotchas

- Providers: `tehcyx/kind` (~> 0.9), `hashicorp/helm` (~> 3.0; uses the
  `kubernetes = { ... }` attribute syntax, not the v2 block),
  `hashicorp/kubernetes` (~> 2.36).
- The kind provider embeds its own kind library; the installed `kind` CLI
  version does not matter, but `node_image` must be compatible with the
  provider's bundled kind.
- Argo CD reaches the apps cluster over the shared `kind` Docker network at
  `https://<name>-control-plane:6443`, not the host-mapped endpoint. The TLS
  data comes from `kind_cluster` attributes (PEM), which are base64-encoded
  for the secret.
- Providers are configured from resources created in the same apply, so avoid
  `kubernetes_manifest` (it needs API access at plan time). Use typed
  resources like `kubernetes_secret_v1` or Helm instead.
- Kubeconfigs are written to `~/.kube/kind-<name>.yaml`.
- State and `*.tfvars` are gitignored; don't commit them.

## Commands

```sh
terraform fmt -recursive
terraform init
terraform validate
terraform apply
terraform destroy
checkov --config-file .checkov.yaml   # same scan CI runs
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
