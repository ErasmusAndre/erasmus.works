<p align="center">
  <img src="./Erasmus-Works-Logo.png" alt="erasmus.works logo" width="400">
</p>

<div align="center">

[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&color=grey&label=%20)](https://kubernetes.io/)&nbsp;&nbsp;
[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Ftalos_version&style=for-the-badge&logo=talos&color=grey&label=%20)](https://www.talos.dev/)&nbsp;&nbsp;
[![ArgoCD](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fargocd_version&style=for-the-badge&logo=argo&color=grey&label=%20)](https://argocd.erasmus.works/)

</div>

<div align="center">

[![Grafana](https://img.shields.io/endpoint?url=https%3A%2F%2Fstatus.erasmus.works%2Fapi%2Fv1%2Fendpoints%2Finternal_grafana%2Fhealth%2Fbadge.shields&style=for-the-badge&logo=grafana&logoColor=white&label=Grafana)](https://grafana.erasmus.works/)&nbsp;&nbsp;
[![Prometheus](https://img.shields.io/endpoint?url=https%3A%2F%2Fstatus.erasmus.works%2Fapi%2Fv1%2Fendpoints%2Finternal_prometheus%2Fhealth%2Fbadge.shields&style=for-the-badge&logo=prometheus&logoColor=white&label=Prometheus)](https://prometheus.erasmus.works/)&nbsp;&nbsp;
[![Alertmanager](https://img.shields.io/endpoint?url=https%3A%2F%2Fstatus.erasmus.works%2Fapi%2Fv1%2Fendpoints%2Finternal_alertmanager%2Fhealth%2Fbadge.shields&style=for-the-badge&logo=prometheus&logoColor=white&label=Alertmanager)](https://alertmanager.erasmus.works/)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fcluster_age_days&style=flat-square&label=Age)](https://kromgo.erasmus.works/cluster_age_days)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://kromgo.erasmus.works/cluster_uptime_days)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fcluster_node_count&style=flat-square&label=Nodes)](https://kromgo.erasmus.works/cluster_node_count)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fcluster_pod_count&style=flat-square&label=Pods)](https://kromgo.erasmus.works/cluster_pod_count)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://kromgo.erasmus.works/cluster_cpu_usage)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://kromgo.erasmus.works/cluster_memory_usage)&nbsp;&nbsp;
[![Alerts](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.erasmus.works%2Fcluster_alert_count&style=flat-square&label=Alerts)](https://kromgo.erasmus.works/cluster_alert_count)

<p align="center">My Homelab Kubernetes repo for a Talos cluster, with a simple GitOps workflow using Argo CD.</p>

</div>

## Core Components

**Platform:** [Talos Linux](https://www.talos.dev/) runs the node and
[Kubernetes](https://kubernetes.io/) provides the cluster runtime.

**GitOps:** [Argo CD](https://argo-cd.readthedocs.io/) manages the repo with an
app-of-apps layout rooted at `kubernetes/clusters/homelab`.

**Networking:** [MetalLB](https://metallb.io/) provides `LoadBalancer` IPs,
[Envoy Gateway](https://gateway.envoyproxy.io/) handles in-cluster ingress, and
[ExternalDNS](https://kubernetes-sigs.github.io/external-dns/latest/) syncs DNS
records to Cloudflare.

**Edge Access:** [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
publishes selected services externally.

**Secrets:** [External Secrets Operator](https://external-secrets.io/) reads
from Bitwarden Secrets Manager and creates in-cluster Kubernetes secrets.

**Data Services:** [Longhorn](https://longhorn.io/) provides persistent storage,
[Garage](https://garagehq.deuxfleurs.fr/) provides S3-compatible object
storage for backup workflows, [VolSync](https://volsync.readthedocs.io/) handles
scheduled PVC backups, and [CloudNativePG](https://cloudnative-pg.io/) manages
PostgreSQL workloads.

**Observability:** [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
provides Prometheus, Grafana, and Alertmanager. [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/)
stores in-cluster logs, and [Fluent Bit](https://fluentbit.io/) collects and
forwards them for search through Grafana.


## Overview

This repository manages my single-node homelab Kubernetes cluster with a small
GitOps setup built around Talos Linux, Kubernetes, and Argo CD.

| Area | Choice |
| --- | --- |
| OS | Talos Linux |
| Orchestration | Kubernetes |
| GitOps | Argo CD |
| Load balancing | MetalLB |
| In-cluster ingress | Envoy Gateway |
| DNS automation | ExternalDNS |
| Public access | Cloudflare Tunnel |
| Storage | Longhorn |
| Object Storage | Garage |
| Backup | VolSync |
| Volume snapshots | CSI external snapshotter |
| Database operator | CloudNativePG |
| Secret sync | External Secrets Operator + Bitwarden Secrets Manager |
| Metrics | kube-prometheus-stack |
| Logs | VictoriaLogs + Fluent Bit |

## Storage

Longhorn is installed for persistent storage. This is currently a single-node
setup, so the default replica count is `1` by design. Longhorn data currently
lives at `/var/lib/longhorn` on the node SSD. VolSync is installed for
scheduled filesystem backups of app PVCs. CSI volume snapshot support is
installed for snapshot-capable workloads. CloudNativePG is installed as the
PostgreSQL operator for in-cluster database workloads. Garage runs in-cluster
and stores its backup objects on a dedicated TrueNAS NFS export.

## Cloud Dependencies

This setup is mostly self-hosted, but it still depends on a few cloud services.

| Service | Use | Cost |
| --- | --- | --- |
| [Cloudflare](https://www.cloudflare.com/) | Domain, DNS, Zero Trust Tunnel | ~€22/yr |
| [Bitwarden Secrets Manager](https://bitwarden.com/products/secrets-manager/) | External secret source for Kubernetes | ~€18/yr |
| [SMTP2GO](https://www.smtp2go.com/) | Outbound email delivery for cluster apps | Free |
| [GitHub](https://github.com/) | Git hosting and Argo CD source of truth | Free |
|  |  | Total: ~€3.35/mo |

## Repository Structure

```text
.
├── 📁 kubernetes/
│   ├── 📁 bootstrap/argocd/   # Argo CD bootstrap
│   ├── 📁 clusters/homelab/   # Cluster entrypoint and child apps
│   ├── 📁 infra/              # Infra manifests and infra-level Argo apps
│   └── 📁 apps/               # App manifests
├── 📁 talos/                  # Talos configs
├── 📁 linux/                  # Local workstation helpers
└── 📁 docs/                   # Runbooks and notes
```

## Hardware

| Component | Details |
| --- | --- |
| Kubernetes node | MINIS FORUM UN1245 Mini-PC |
| CPU | Intel Core i5-12450H |
| iGPU | Intel UHD Graphics |
| Memory | 16 GB RAM |
| Storage | 512 GB SSD |
| Router | UniFi Express 7 (UX7) |
| Switch | 2.5 Gbps switch |

## Documentation

- Renovate manages dependency update PRs for this repository.
- [Renovate Config](renovate.json)
- [Talos Bootstrap Runbook](docs/bootstrap/talos.md)
- [Argo CD Bootstrap Runbook](docs/bootstrap/argocd.md)
- [Bitwarden External Secrets Bootstrap](docs/bootstrap/bitwarden-external-secrets.md)
- [Longhorn Bootstrap Notes](docs/bootstrap/longhorn.md)
- [VolSync Restic Notes](docs/volsync-restic.md)
- [Garage Notes](docs/garage.md)
- [Linux Init Script](linux/init.md)
