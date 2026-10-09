# Kubernetes Inventory

Short reference for what is deployed in this repo.

## Apps

| App | Type | Database | Volume Backup | Database Backup | Prometheus | SSO | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `diabeteshub` | Plain manifests | N/A | N/A | N/A | No | No | Static page synced from `lynette-erasmus1975/diabeteshub` by git-sync; stats in Umami |
| `docmost` | Plain manifests | CNPG | VolSync | CNPG | Yes | No |  |
| `euro-office` | Plain manifests | Bundled | None | None | No | No | Nextcloud Office backend; state is disposable |
| `homepage` | Plain manifests | N/A | N/A | N/A | N/A | N/A |  |
| `immich` | Helm based | CNPG | None | CNPG | Yes | Yes | Media stored on NAS |
| `kudos` | Plain manifests | CNPG | None | CNPG | No | No | Private GHCR image; uploads go to Garage via `s3.erasmus.works/kudos` |
| `kudos-dev` | Plain manifests | CNPG | None | None | No | Yes | Disposable test copy of kudos (`TEST_CLOCK`, `/dev`); email caught by Mailpit at `/mail` |
| `nextcloud` | Helm based | CNPG | VolSync | CNPG | Yes | Yes |  |
| `ntfy` | Plain manifests | SQLite | VolSync | N/A | No | No | Push notifications; built-in auth, deny-all by default |

## Infra

| Component | Type | Prometheus | SSO | Notes |
| --- | --- | --- | --- | --- |
| `argocd` | Helm based | Yes | Yes |  |
| `authentik` | Helm based | Yes | N/A | SSO provider; Database Backups (CNPG) |
| `blocky` | Plain manifests | Yes | N/A | LAN DNS and ad-blocker; MetalLB IP `192.168.20.242` port 53 |
| `cloudnative-pg` | Helm based | Yes | N/A |  |
| `envoy-gateway` | Helm based | Yes | N/A |  |
| `external-dns` | Helm based | No | N/A |  |
| `external-secrets` | Helm based | No | N/A |  |
| `fluent-bit` | Helm based | Yes | N/A |  |
| `garage` | Helm based | Yes | N/A |  |
| `garage-ui` | Helm based | N/A | Yes |  |
| `kube-prometheus-stack` | Helm based | Yes | Yes |  |
| `longhorn` | Helm based | Yes | Yes |  |
| `metallb` | Plain manifests | No | N/A |  |
| `status` | Plain manifests | N/A | No | Intentionally not behind SSO |
| `umami` | Plain manifests | No | Yes | Web analytics for the landing page; Database Backups (CNPG); SSO via the `umami-sso` bridge |
| `victorialogs` | Helm based | N/A | N/A |  |
| `volsync` | Helm based | Yes | N/A |  |
| `volume-snapshots` | Helm based | N/A | N/A |  |
