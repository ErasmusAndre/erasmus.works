# Kubernetes Inventory

Short reference for what is deployed in this repo.

## Apps

- `docmost`
  - Plain manifests
  - CNPG
  - Volume Backups (VolSync)
  - Database Backups (CNPG)

- `homepage`
  - Plain manifests
  - No Database
  - No Volumes

- `immich`
  - Helm based
  - CNPG
  - Database Backups (CNPG)
  - No volume backups 
  // TODO backup volumes

- `nextcloud`
  - Helm based
  - CNPG
  - Volume Backups (VolSync)
  - Database Backups (CNPG)

## Infra

- `argocd`
  - Helm based
  - Metrics
  - SSO

- `authentik`
  - Helm based
  - Database Backups (CNPG)

- `cloudnative-pg`
  - Helm based

- `envoy-gateway`
  - Helm based

- `external-dns`
  - Helm based

- `external-secrets`
  - Helm based

- `fluent-bit`
  - Helm based

- `garage`
  - Helm based

- `garage-ui`
  - Helm based

- `kube-prometheus-stack`
  - Helm based

- `longhorn`
  - Helm based

- `metallb`
  - Upstream manifests

- `status`
  - Plain manifests

- `victorialogs`
  - Helm based

- `volsync`
  - Helm based

- `volume-snapshots`
  - Helm based
