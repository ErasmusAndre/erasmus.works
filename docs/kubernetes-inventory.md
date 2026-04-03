# Kubernetes Inventory

Short reference for what is deployed in this repo.

## Apps

| App | Type | Database | Volume Backup | Database Backup | Metrics | SSO | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `docmost` | Plain manifests | CNPG | VolSync | CNPG |  |  |  |
| `homepage` | Plain manifests | N/A | N/A | N/A |  |  |  |
| `immich` | Helm based | CNPG | None | CNPG | Yes | Yes | Media stored on NAS |
| `nextcloud` | Helm based | CNPG | VolSync | CNPG |  | Yes |  |

## Infra

| Component | Type | Metrics | SSO | Notes |
| --- | --- | --- | --- | --- |
| `argocd` | Helm based | Yes | Yes |  |
| `authentik` | Helm based | Yes |  | Database Backups (CNPG) |
| `cloudnative-pg` | Helm based | Yes |  |  |
| `envoy-gateway` | Helm based | Yes |  |  |
| `external-dns` | Helm based |  |  |  |
| `external-secrets` | Helm based |  |  |  |
| `fluent-bit` | Helm based | Yes |  |  |
| `garage` | Helm based | Yes |  |  |
| `garage-ui` | Helm based |  |  |  |
| `kube-prometheus-stack` | Helm based | Yes | Yes |  |
| `longhorn` | Helm based | Yes |  |  |
| `victorialogs` | Helm based |  |  |  |
| `volsync` | Helm based | Yes |  |  |
| `volume-snapshots` | Helm based |  |  |  |
| `metallb` | Plain manifests |  |  |  |
| `status` | Plain manifests | Yes |  |  |
