# AGENTS.md

## Purpose

This repository manages my personal homelab Kubernetes cluster.

The goal is to keep the setup simple, reproducible, and low-maintenance.
Prefer incremental improvements over large rewrites.

## Current state

Currently in place:

- Talos Linux
- Single-node Kubernetes cluster
- Argo CD
- MetalLB
- Envoy Gateway
- Cloudflare Tunnel
- External Secrets Operator
- Longhorn
- CloudNativePG
- kube-prometheus-stack
- GitOps structure under `kubernetes/`


## Principles

- Keep it KISS
- Prefer low-maintenance solutions
- Do not add tools unless clearly needed
- Prefer GitOps-managed changes where appropriate
- Avoid unnecessary abstraction
- Avoid premature HA or production-style complexity
- Preserve working setup unless a change is clearly required

## Repo structure

- `talos/` contains Talos machine configs and node-specific files
- `kubernetes/` contains GitOps-managed Kubernetes manifests
- `docs/` contains practical runbooks and setup notes
- `linux/` contains local workstation/helper setup files

## Change rules

When making changes:

1. Inspect the existing structure first
2. Reuse existing folders and patterns where possible
3. Keep changes minimal and obvious
4. Do not rename or move files unless there is a clear benefit
5. Do not add new tooling like Terraform, Flux, Helmfile, Ansible, or scripts unless explicitly requested
6. Do not introduce unnecessary docs
7. Do not claim something is installed unless it is already in the repo or explicitly being added now

## Kubernetes / GitOps rules

- Argo CD is the GitOps controller
- `kubernetes/clusters/homelab/homelab-root.yaml` is the root application entrypoint
- All cluster changes must be made through this repo and deployed via GitOps, not by running imperative `kubectl`, `helm`, or similar commands against the cluster
- Infra components should live under `kubernetes/infra/`
- Keep manifests plain and readable
- Prefer simple manifests and Kustomize where possible
- When a separate YAML file can be used instead of inline manifest content in a ConfigMap, prefer the separate file and Kustomize `configMapGenerator`
- When creating or editing a `kustomization.yaml`, first check `docs/kustomization-grouping.md` and follow that convention
- When adding a new app to Authentik, first check `docs/authentik-new-app.md` and follow that pattern
- Helm is already used through Argo CD Applications where explicitly added
- Prefer using upstream Helm charts for supported infra components over maintaining equivalent custom manifests when that keeps the setup simpler
- For Helm-based Argo CD Applications, prefer a separate `values.yaml` file over large inline `helm.values` blocks when custom values are needed
- Argo CD `Application` manifests should include the `resources-finalizer.argocd.argoproj.io` finalizer so app removal prunes managed resources cleanly
- For CNPG backup S3 secrets, follow the existing app pattern used by `nextcloud` and `docmost`: keep the non-secret `ACCESS_KEY_ID` in Git and store only `ACCESS_SECRET_KEY` in Bitwarden/External Secrets unless explicitly asked to do otherwise

## Documentation rules

- Root `README.md` should stay short and act as a project overview
- Command-heavy instructions belong in docs, not in the root README
- Keep documents succinct and practical
- Add short practical notes rather than large architecture essays
- Avoid creating new docs unless there is a real need

## Naming guidance

- Use clear, literal names
- Match filenames to actual contents
- Avoid vague names like `stuff.yaml`, `test2.yaml`, `misc.md`
- Prefer consistency over cleverness

## If unsure

Prefer the simpler option.
Do not overengineer.
