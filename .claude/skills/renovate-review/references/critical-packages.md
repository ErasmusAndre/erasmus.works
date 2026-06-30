# Critical Packages Reference

These packages are configured in `.renovate/overrides.json` to require manual review — Renovate will never auto-merge them. Treat any PR touching these as **High Risk** regardless of the update type (patch, minor, or major).

## Critical Infrastructure Packages

### Storage & Data

**longhorn**
- Distributed block storage for the cluster. An upgrade gone wrong can make PVCs unavailable.
- Always check the Longhorn upgrade path docs — some versions require upgrading through an intermediate version.
- Verify all volumes are healthy (`kubectl -n longhorn-system get volumes`) before and after.
- CRDs change frequently between minor versions.

**cloudnative-pg (CNPG)**
- PostgreSQL operator. Manages postgres clusters for apps like Nextcloud, Vaultwarden, etc.
- Check if the new operator version changes the CRD schema — requires `kubectl apply` of new CRDs before the operator upgrade.
- Monitor postgres cluster rolling restarts after upgrade.

**volsync**
- Handles PVC replication/backup. CRDs change between versions.
- Verify ReplicationSource objects are healthy after upgrade.
- Never upgrade during an active backup window.

**snapshot-controller**
- Manages VolumeSnapshots. CRD-driven — check if CRDs change.
- Affects Longhorn snapshots and CNPG backups.

### Networking & Ingress

**envoyproxy/gateway-helm**
- Envoy Gateway (the cluster's main ingress). Outage = all HTTP/HTTPS ingress goes down.
- Check for HTTPRoute API version changes between upgrades.
- Test after upgrade that a few key services are reachable.

**metallb**
- Provides LoadBalancer IPs. An outage breaks all external-facing services.
- Check for configuration CRD changes (IPAddressPool, L2Advertisement).

**cloudflare/cloudflared**
- Cloudflare tunnel daemon for external access. Upgrade carefully — a restart causes brief downtime.

### Identity & Secrets

**external-secrets**
- Bridges Bitwarden Secrets Manager to Kubernetes Secrets. If this breaks, apps can't pull their secrets.
- Check CRD changes between versions — ExternalSecret, ClusterSecretStore schema.

**external-dns**
- Auto-manages DNS records. Outage means new services won't get DNS entries, but existing entries persist.

### Cluster Management

**argocd / argo-cd**
- The GitOps controller itself. An ArgoCD outage means no changes can be applied from Git.
- Check the ArgoCD upgrade notes — some versions require migrating configuration.
- After upgrade, verify the UI is accessible and apps sync correctly.

### Node-Level (Talos)

**ghcr.io/siderolabs/installer** and **ghcr.io/siderolabs/kubelet**
- Talos OS and Kubernetes node upgrades. These require running `talosctl upgrade` — not a simple Helm merge.
- See `docs/talos-upgrade.md` (if it exists) for the upgrade procedure.
- Never merge these without a plan to apply the Talos config to nodes.

## Notes on CRD Updates

When a critical package changes its CRDs, the correct order is:
1. Apply new CRDs first (`kubectl apply -f <crd-file>`)
2. Then merge the Helm chart upgrade PR
3. Then verify the operator reconciles existing resources

Argo CD usually handles CRD updates automatically if the chart includes them, but double-check for packages like CNPG and Longhorn where CRD changes are common.

## Packages That Are Fine to Merge (Non-Critical)

These appear in the repo but are lower risk:
- **nextcloud** — App-level; data is backed up, Argo CD will roll back on failure
- **vaultwarden** — App-level; secrets are in Bitwarden, not in Kubernetes
- **gatus / kromgo** — Status page; non-critical
- **victoria-metrics / victoria-logs** — Observability; losing metrics is annoying, not critical
- **cert-manager** — Certificate management; existing certs continue to work during brief outages
- **bjw-s app-template** — Base chart template; changes are usually backward-compatible
