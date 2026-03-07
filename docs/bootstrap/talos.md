# Talos Bootstrap Runbook

Reference video: https://www.youtube.com/watch?v=VKfE5BuqlSc  
Official guide: https://docs.siderolabs.com/talos/v1.12/getting-started/getting-started

## Scope

This runbook covers initial Talos single-node bootstrap and post-bootstrap verification for `talos/node-01`.

## Prerequisites

- Talos ISO written to a USB drive.
- `talosctl` installed locally:

```bash
curl -sL https://talos.dev/install | sh
```

- Optional local tooling bootstrap:

```bash
./linux/init.sh
```

## Cluster Bootstrap

Set environment variables:

```bash
export CONTROL_PLANE_IP=192.168.20.33
export CLUSTER_NAME=homelab
export DISK_NAME=/dev/nvme0n1
```

Generate and apply Talos configuration:

```bash
talosctl gen secrets -o secrets.yaml
talosctl gen config --with-secrets secrets.yaml "$CLUSTER_NAME" "https://$CONTROL_PLANE_IP:6443" --install-disk "$DISK_NAME"
talosctl get disks --nodes 192.168.20.xx --endpoints 192.168.20.xx --insecure
talosctl apply-config --insecure --nodes "$CONTROL_PLANE_IP" --file controlplane.yaml
```

After apply, the node restarts. Remove the USB drive. The machine should move from Maintenance to Booting and then Running.

Bootstrap the Talos control plane:

```bash
talosctl bootstrap -n "$CONTROL_PLANE_IP" -e "$CONTROL_PLANE_IP" --talosconfig ./talosconfig
```

Open Talos dashboard:

```bash
talosctl dashboard -n "$CONTROL_PLANE_IP" -e "$CONTROL_PLANE_IP" --talosconfig ./talosconfig
```

## Generate Kubeconfig and Verify

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
