# erasmus.works

Homelab Kubernetes repo for a single-node Talos cluster, with a simple GitOps workflow using Argo CD.

## Repository Structure

```text
.
├── kubernetes/
│   ├── bootstrap/argocd/      # Argo CD install bootstrap
│   ├── clusters/homelab/      # Cluster-level Argo CD apps
│   ├── infra/                 # Infrastructure manifests managed by Argo CD
│   └── apps/                  # Application manifests (planned)
├── talos/
│   └── node-01/               # Talos node-specific generated configs
├── linux/                     # Local workstation bootstrap helpers
└── docs/                      # Project docs and runbooks
```

## Documentation

- [Talos Bootstrap Runbook](docs/bootstrap/talos.md)
- [Argo CD Bootstrap Runbook](docs/bootstrap/argocd.md)
- [Linux Init Script](linux/init.md)

