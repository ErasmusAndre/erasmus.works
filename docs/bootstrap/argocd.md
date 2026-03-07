# Argo CD Bootstrap Runbook

## Scope

This runbook installs Argo CD on the existing Talos cluster and registers the root application for GitOps sync from this repository.

## Prerequisites

- Kubernetes cluster is healthy.
- Kubeconfig exists at `talos/node-01/kubeconfig`.
- You are in the repository root: `~/code/erasmus.works`.

Export kubeconfig:

```bash
export KUBECONFIG=~/code/erasmus.works/talos/node-01/kubeconfig
```

## Install Argo CD (Official Method)

```bash
./kubernetes/bootstrap/argocd/bootstrap-argocd.sh
```

Equivalent commands:

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Verify Argo CD

Watch Argo CD pods:

```bash
kubectl -n argocd get pods -w
```

Get initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

Port-forward Argo CD API/UI:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

## Apply Root Application

```bash
kubectl apply -f kubernetes/clusters/homelab/root-app.yaml
```

The root app currently targets:

- Repo: `https://github.com/NoBadDays/erasmus.works`
- Branch: `main`
- Path: `kubernetes/infra`
