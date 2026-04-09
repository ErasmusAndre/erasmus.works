# AGENTS

This repository is a homelab Kubernetes GitOps workspace. Prefer small, literal changes that match the existing layout and keep operations low-maintenance.

## Defaults

- Inspect existing structure and nearby examples before editing.
- Keep changes minimal and obvious.
- Prefer Kustomize-style plain manifests over clever abstractions.
- Prefer using Helm Charts where possible.
- Reuse existing folders, naming, and patterns.
- Check `docs/` for short runbooks and prior decisions when touching an area.

## Repository Layout

- `kubernetes/` contains GitOps-managed manifests.
- `kubernetes/infra/` is for shared infrastructure components.
- `talos/` contains Talos machine configuration and node-specific files.
- `docs/` contains practical notes and runbooks.
- `linux/` contains local workstation and helper setup files.

## GitOps Rules

- Make cluster changes through this repo, not via imperative `kubectl` edits.
- The Argo CD root is `kubernetes/clusters/homelab/homelab-root.yaml`.
- Keep Helm values in dedicated `values.yaml` files instead of inline `helm.values`.
- Include `resources-finalizer.argocd.argoproj.io` on Argo CD `Application` manifests.
- For CNPG backups, keep `ACCESS_KEY_ID` in Git and store only `ACCESS_SECRET_KEY` in Bitwarden/External Secrets.
- For single-replica workloads using `ReadWriteOnce` PVCs, prefer `Recreate` over `RollingUpdate`.

## Documentation Rules

- Keep the root `README.md` short and high-level.
- Put command-heavy or operational instructions in `docs/`, not the README.
- Add documentation only when it materially helps operate or recover the system.
- Prefer short practical notes over long architecture writeups.

## When Unsure

Prefer the simpler option. Do not overengineer.
