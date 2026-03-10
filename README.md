<p align="center">
  <img src="./Erasmus-Works-Logo.png" alt="erasmus.works logo" width="400">
</p>

<p align="center">My Homelab Kubernetes repo for a Talos cluster, with a simple GitOps workflow using Argo CD.</p>

## Overview

This repository manages a single-node homelab Kubernetes cluster built around Talos Linux and Argo CD. Homepage is the current example application and is exposed publicly at `https://home.erasmus.works`.

| Area | Choice |
| --- | --- |
| OS | Talos Linux |
| Orchestration | Kubernetes |
| GitOps | Argo CD |
| CNI | Flannel |
| Load balancing | MetalLB |
| In-cluster ingress | Envoy Gateway |
| Public access | Cloudflare Tunnel |

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



## Repository Structure

```text
.
├── 📁 kubernetes/
│   ├── 📁 bootstrap/argocd/   # Argo CD install bootstrap
│   ├── 📁 clusters/homelab/   # Cluster entrypoint
│   ├── 📁 infra/              # Infra manifests and infra-related Argo CD Applications
│   └── 📁 apps/               # App runtime manifests
├── 📁 talos/
│   └── 📁 node-01/            # Talos node-specific generated configs
├── 📁 linux/                  # Local workstation bootstrap helpers
└── 📁 docs/                   # Project docs and runbooks
```

## GitOps Flow

1. Install Argo CD with `kubernetes/bootstrap/argocd/bootstrap-argocd.sh`.
2. Apply `kubernetes/clusters/homelab/homelab-root.yaml`.
3. The `homelab-root` app syncs `kubernetes/clusters/homelab`, which registers cluster-level child Applications.
4. Child Applications sync:
   - `homelab-infra` -> `kubernetes/infra` for infra components.
   - `homepage` -> `kubernetes/apps/homepage`.

Homepage is the current example app managed through Argo CD and exposed at `homepage.homelab`.

## Documentation

- [Talos Bootstrap Runbook](docs/bootstrap/talos.md)
- [Argo CD Bootstrap Runbook](docs/bootstrap/argocd.md)
- [Linux Init Script](linux/init.md)
