# Kubernetes Inventory

Short reference for what is deployed in this repo.

## Apps

| App | Type | Database | Volume Backup | Database Backup | Prometheus | SSO | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `docmost` | Plain manifests | CNPG | VolSync | CNPG | Yes | No | CNPG PodMonitor |
| `homepage` | Plain manifests | N/A | N/A | N/A | N/A | N/A |  |
| `immich` | Helm based | CNPG | None | CNPG | Yes | Yes | Media stored on NAS |
| `nextcloud` | Helm based | CNPG | VolSync | CNPG | Yes | Yes | CNPG PodMonitor |

## Infra

| Component | Type | Prometheus | SSO | Notes |
| --- | --- | --- | --- | --- |
| `argocd` | Helm based | Yes | Yes |  |
| `authentik` | Helm based | Yes | N/A | SSO provider; Database Backups (CNPG) |
| `cloudnative-pg` | Helm based | Yes | N/A |  |
| `envoy-gateway` | Helm based | Yes | N/A |  |
| `external-dns` | Helm based | No | N/A |  |
| `external-secrets` | Helm based | No | N/A |  |
| `fluent-bit` | Helm based | Yes | N/A |  |
| `garage` | Helm based | Yes | N/A |  |
| `garage-ui` | Helm based | N/A | Yes |  |
| `kube-prometheus-stack` | Helm based | Yes | Yes |  |
| `longhorn` | Helm based | Yes | Yes |  |
| `victorialogs` | Helm based | N/A | N/A |  |
| `volsync` | Helm based | Yes | N/A |  |
| `volume-snapshots` | Helm based | N/A | N/A |  |
| `metallb` | Plain manifests | No | N/A |  |
| `status` | Plain manifests | N/A | No | Intentionally not behind SSO |
