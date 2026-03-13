<p align="center">
  <img src="./Erasmus-Works-Logo.png" alt="erasmus.works logo" width="400">
</p>

<p align="center">My Homelab Kubernetes repo for a Talos cluster, with a simple GitOps workflow using Argo CD.</p>

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
| Public access | Cloudflare Tunnel |
| Secret sync | External Secrets Operator + Bitwarden Secrets Manager |

## Core Components

**Platform:** [Talos Linux](https://www.talos.dev/) runs the node and
[Kubernetes](https://kubernetes.io/) provides the cluster runtime.

**GitOps:** [Argo CD](https://argo-cd.readthedocs.io/) manages the repo with an
app-of-apps layout rooted at `kubernetes/clusters/homelab`.

**Networking:** [MetalLB](https://metallb.io/) provides `LoadBalancer` IPs, and
[Envoy Gateway](https://gateway.envoyproxy.io/) handles in-cluster ingress.

**Edge Access:** [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
publishes selected services externally.

**Secrets:** [External Secrets Operator](https://external-secrets.io/) reads
from Bitwarden Secrets Manager and creates in-cluster Kubernetes secrets.

## Storage

Longhorn is installed for persistent storage. This is currently a single-node
setup, so the default replica count is `1` by design. Longhorn data currently
lives at `/var/lib/longhorn` on the node SSD, and backups are still a required
next step.

## Cloud Dependencies

This setup is mostly self-hosted, but it still depends on a few cloud services.

| Service | Use |
| --- | --- |
| [Cloudflare](https://www.cloudflare.com/) | DNS, public edge access, Cloudflare Tunnel |
| [Bitwarden Secrets Manager](https://bitwarden.com/products/secrets-manager/) | External secret source for Kubernetes |
| [GitHub](https://github.com/) | Git hosting and Argo CD source of truth |

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

- [Talos Bootstrap Runbook](docs/bootstrap/talos.md)
- [Argo CD Bootstrap Runbook](docs/bootstrap/argocd.md)
- [Bitwarden External Secrets Bootstrap](docs/bootstrap/bitwarden-external-secrets.md)
- [Linux Init Script](linux/init.md)
