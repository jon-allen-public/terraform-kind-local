## Summary

<!-- What does this change and why? Link any related issue. -->

## Type of change

- [ ] Clusters (kind config, node image, workers)
- [ ] Argo CD (Helm release, cluster registration)
- [ ] CI / tooling
- [ ] Docs

## Testing

<!-- Paste relevant output. -->

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` passes
- [ ] `checkov --config-file .checkov.yaml` passes (or skips are justified below)
- [ ] `terraform apply` run locally; both clusters come up
- [ ] Argo CD UI reachable and `apps` cluster shows as connected (if Argo CD touched)

## Notes for reviewers

<!-- Breaking changes (renamed clusters/variables, provider bumps), Checkov skips, anything that needs `terraform destroy` first. -->
