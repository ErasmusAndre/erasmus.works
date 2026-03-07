# Talos Node Setup

Reference video: https://www.youtube.com/watch?v=VKfE5BuqlSc  
Official guide: https://docs.siderolabs.com/talos/v1.12/getting-started/getting-started

## Prerequisites

- Install Talos ISO on a USB drive.
- From your PC, install `talosctl` if needed: `curl -sL https://talos.dev/install | sh`

## Quick Start (TL;DR)

Set environment variables, for example:

```bash
export CONTROL_PLANE_IP=192.168.20.33
export CLUSTER_NAME=homelab
export DISK_NAME=/dev/nvme0n1
```

Run the setup commands:

- Generate cluster secrets: `talosctl gen secrets -o secrets.yaml`
- Generate config files: `talosctl gen config --with-secrets secrets.yaml $CLUSTER_NAME https://$CONTROL_PLANE_IP:6443 --install-disk "$DISK_NAME"`
- Check disk name: `talosctl get disks --nodes 192.168.20.xx --endpoints 192.168.20.xx --insecure`
- Apply config: `talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml`

The node should now restart. Remove the USB drive.  
After restart, state should transition from Maintenance mode to Booting.

- Bootstrap the node: `talosctl bootstrap -n $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP --talosconfig ./talosconfig`
- The stage should now be Running.

Open the dashboard:

`talosctl dashboard -n $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP --talosconfig ./talosconfig`

## Next Step (Generate kubeconfig + Verify Cluster)

```bash
cd ~/code/erasmus.works/talos/node-01

talosctl kubeconfig . \
  --nodes 192.168.20.33 \
  --endpoints 192.168.20.33 \
  --talosconfig ./talosconfig

export KUBECONFIG=./kubeconfig

kubectl get nodes -o wide
kubectl get pods -A
talosctl health \
  --nodes 192.168.20.33 \
  --endpoints 192.168.20.33 \
  --talosconfig ./talosconfig
```

## Argo CD GitOps Bootstrap

Export kubeconfig:

```bash
export KUBECONFIG=~/code/erasmus.works/talos/node-01/kubeconfig
```

Bootstrap Argo CD:

```bash
./kubernetes/bootstrap/argocd/bootstrap-argocd.sh
```

Watch Argo CD pods:

```bash
kubectl -n argocd get pods -w
```

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

Port-forward Argo CD API/UI:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Apply the root app:

```bash
kubectl apply -f kubernetes/clusters/homelab/root-app.yaml
```
