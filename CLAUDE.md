# CLAUDE.md

This repository is a homelab Kubernetes GitOps workspace. Prefer small, literal changes that match the existing layout and keep operations low-maintenance.

## GitOps First

**All cluster changes must go through Git.** Argo CD is the source of truth — it applies whatever is in this repo to the cluster. Imperative commands (`kubectl apply`, `kubectl edit`, `helm install`) are for read-only inspection or emergencies only, and any emergency change must be followed by a matching commit to bring the repo back in sync.

- Never suggest imperative cluster changes as the solution. Always express the answer as a manifest edit in this repo.
- Use `kubectl` and `talosctl` only for reading state (`get`, `describe`, `logs`) or validating changes before committing.
- Talos node configuration changes go through `talos/` — apply with `talosctl apply-config` only when the Git change is already committed or the situation requires it.

## General Approach

- Inspect existing structure and nearby examples before editing.
- Keep changes minimal and obvious. Do not overengineer.
- Prefer Kustomize-style plain manifests over clever abstractions.
- Prefer using Helm Charts where possible.
- Reuse existing folders, naming, and patterns.
- Check `docs/` for short runbooks and prior decisions when touching an area.

## Repository Layout

```
.
├── kubernetes/
│   ├── clusters/homelab/   # Cluster root and top-level Argo CD Application manifests
│   ├── infra/              # Shared platform services (identity, ingress, storage, DNS, monitoring, backups)
│   └── apps/               # User-facing workloads
├── talos/                  # Talos machine config, patches, and node files
├── docs/                   # Practical runbooks and notes
└── linux/                  # Local workstation/helper files
```

## GitOps Rules

- The Argo CD root is `kubernetes/clusters/homelab/homelab-root.yaml`.
- Top-level Argo CD `Application` manifests live in `kubernetes/clusters/homelab/argocd-apps/`.
- Keep Helm values in dedicated `values.yaml` files instead of inline `helm.values`.
- Include `resources-finalizer.argocd.argoproj.io` on Argo CD `Application` manifests.
- For single-replica workloads using `ReadWriteOnce` PVCs, prefer `Recreate` over `RollingUpdate`.

## infra vs apps Classification

- Put a component in `infra/` when it provides a shared capability: identity, ingress, storage, DNS, monitoring, or backups.
- Put a component in `apps/` when you primarily run it for its own end-user function.
- User-visible does not automatically mean `apps/`. Shared services like Authentik still belong in `infra/`.

## Kustomization Grouping

Use section comments in `kustomization.yaml` only when they make a larger file easier to scan. Do not add comments to small files.

When used, maintain this group order:

1. `# Core` — normal required resources (namespace, deployment, externalsecret, postgres, redis)
2. `# Storage` — persistent storage (pv, pvc)
3. `# Networking` — routing and network policy (httproute, ingress, gateway, networkpolicy, backendtrafficpolicy)
4. `# Metrics` — observability (servicemonitor, dashboards, alerts)
5. `# SSO` — optional auth resources (OIDC config, auth provider secrets)

Keep comment names exact: `# Core`, not `# Core resources`.

## Secrets and External Secrets

- Secrets are sourced from Bitwarden Secrets Manager via External Secrets Operator.
- For CNPG backups: keep `ACCESS_KEY_ID` in Git and store only `ACCESS_SECRET_KEY` in Bitwarden.
- The shared Restic password for VolSync comes from the Bitwarden secret `volsync-restic-password`.

## VolSync Backup Pattern

New app PVC backups should follow this pattern:

- One shared Bitwarden secret: `volsync-restic-password`
- One app-specific `ExternalSecret`
- One `ReplicationSource`
- One namespace-local `volsync-repository` PVC (500Gi)
- Same retention (`daily: 7`, `weekly: 4`, `monthly: 3`) unless there is a reason to differ
- Stagger backup windows across apps; do not pile everything onto `03:00`
- VolSync is for app PVC backups only — PostgreSQL backups are handled separately by CNPG

## Validation

Use these read-only commands to check work before committing — do not apply changes imperatively:

- `kustomize build <dir>` — verify resources resolve without errors
- `kubectl apply --dry-run=server -f <file>` — validate against the live API without making changes
- `kubectl diff -f <file>` — show what would change against the current cluster state

## Renovate

Renovate automatically tracks and opens PRs for:

- Helm chart versions in `values.yaml` and `application.yaml`
- Docker image tags matched as `image.repository` / `image.tag` pairs in `values.yaml`
- GitHub Actions digest pins (minor/patch auto-merge enabled)
- Talos image references in `talos/`

When adding a new Helm chart or container image, structure it to match the patterns Renovate already tracks so updates stay automated. Check `renovate.json` and `.renovate/` if unsure whether a new pattern will be picked up.

## Talos

- Node machine configs live in `talos/node-*/`; shared patches live in `talos/patches/`
- Changes to node config should be committed to Git first, then applied with `talosctl apply-config --nodes <ip> --file <file>`
- Do not edit node configs without understanding the rollout impact — a bad config can take a node offline

## Documentation Rules

- Keep the root `README.md` short and high-level.
- Put command-heavy or operational instructions in `docs/`, not the README.
- Add documentation only when it materially helps operate or recover the system.
- Prefer short practical notes over long architecture writeups.
