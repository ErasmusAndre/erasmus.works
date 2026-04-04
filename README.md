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

---

## Overview

This repository is the source of truth for my personal homelab Kubernetes cluster. I
try to keep things simple and reproducible by following Infrastructure as Code
(IaC) and GitOps practices with tools like Talos, Kubernetes, Argo CD, and
Renovate.

---

## Kubernetes

My Kubernetes cluster is deployed with [Talos Linux](https://www.talos.dev/).
It is a single-node setup built to stay simple, low-maintenance, and reliable
for the services I actually run, and will be expanded on with more nodes soon.

### Core Components

- [MetalLB](https://metallb.io/): Provides `LoadBalancer` IPs on the local network.
- [Envoy Gateway](https://gateway.envoyproxy.io/): Handles in-cluster ingress and HTTP routing.
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/): Publishes selected services externally without opening inbound ports.
- [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/latest/): Syncs DNS records to Cloudflare.
- [External Secrets Operator](https://external-secrets.io/): Syncs Kubernetes secrets from Bitwarden Secrets Manager.
- [Longhorn](https://longhorn.io/): Provides persistent volumes for stateful workloads.
- [CloudNativePG](https://cloudnative-pg.io/): Runs PostgreSQL workloads in-cluster.
- [VolSync](https://volsync.readthedocs.io/): Handles scheduled PVC backups.
- [Garage](https://garagehq.deuxfleurs.fr/): Provides S3-compatible object storage for backup workflows.
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack): Provides Prometheus, Grafana, and Alertmanager.
- [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/): Stores cluster logs.
- [Fluent Bit](https://fluentbit.io/): Collects and forwards logs into VictoriaLogs.

For a compact overview of what is currently deployed, see the
[Kubernetes Inventory](docs/kubernetes-inventory.md).

### GitOps

Argo CD watches the manifests in my [`kubernetes`](kubernetes/)
folder and makes changes to my cluster based on the state of my Git repository.

Renovate watches my repository for dependency updates, and when they are found
a pull request is automatically created. When pull requests are merged Argo CD
applies the changes to my cluster.

```mermaid
flowchart LR
    github["🐙 GitHub Repo"] --> argo["🚀 Argo CD"]
    internet["🌍 Internet"] --> cf["☁️ Cloudflare Tunnel"]

    subgraph cluster["🧱 Talos Kubernetes Cluster"]
        argo
        apps["📦 Apps"]
        infra["🧩 Infrastructure"]
    end

    argo --> infra
    argo --> apps
    cf --> infra
    infra --> apps
```

### Directories

This Git repository contains the following directories.

```text
.
├── 📁 kubernetes/
│   ├── 📁 clusters/homelab/   # Cluster root and top-level Argo CD applications
│   ├── 📁 infra/              # Shared platform services
│   └── 📁 apps/               # User-facing workloads
├── 📁 talos/                  # Talos machine config and patches
├── 📁 docs/                   # Practical runbooks and notes
└── 📁 linux/                  # Local workstation/helper files
```

---

## Cloud Dependencies

While most of my infrastructure and workloads are self-hosted, I do rely upon
the cloud for a few key parts of my setup. This keeps the setup simpler and
avoids making the cluster responsible for every critical dependency.

| Service | Use | Cost |
| --- | --- | --- |
| [Cloudflare](https://www.cloudflare.com/) | Domain, DNS, Zero Trust Tunnel | ~€22/yr |
| [Bitwarden Secrets Manager](https://bitwarden.com/products/secrets-manager/) | External secret source for Kubernetes | ~€18/yr |
| [SMTP2GO](https://www.smtp2go.com/) | Outbound email delivery for cluster apps | Free |
| [GitHub](https://github.com/) | Git hosting and Argo CD source of truth | Free |
|  |  | Total: ~€3.35/mo |

---

## Hardware

This cluster currently runs on two small-form-factor nodes.

| Hardware | Model | CPU | GPU | Memory | Storage |
| --- | --- | --- | --- | --- | --- |
| K8s Node 1 | MINIS FORUM UN1245 Mini-PC | Intel Core i5-12450H | Intel UHD Graphics | 16 GB DDR4 RAM | 512 GB SSD |
| K8s Node 2 | Blackview MP-80 | Intel Processor N97 | Intel UHD Graphics | 16 GB DDR5 RAM | 512 GB M.2 SSD |
| Router | UniFi Express 7 (UX7) | - | - | - | - |
| Switch | 2.5 Gbps switch | - | - | - | - |

---

## Documentation

- [Talos Runbook](docs/bootstrap/talos.md)
- [Bitwarden External Secrets Bootstrap](docs/bootstrap/bitwarden-external-secrets.md)
- [Longhorn Notes](docs/bootstrap/longhorn.md)
- [Kubernetes Inventory](docs/kubernetes-inventory.md)
- [Kubernetes Layout Notes](docs/kubernetes-layout.md)
- [VolSync Restic Notes](docs/volsync-restic.md)
- [Garage Notes](docs/garage.md)
- [Linux Init Notes](linux/init.md)
- [Renovate Config](renovate.json)
