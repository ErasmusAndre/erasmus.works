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
cd ~/code/erasmus.works/talos

talosctl kubeconfig . \
  --nodes 192.168.20.33 \
  --endpoints 192.168.20.33 \
  --talosconfig ./node-01/talosconfig

export KUBECONFIG=~/code/erasmus.works/talos/kubeconfig

kubectl get nodes -o wide
kubectl get pods -A
talosctl health \
  --nodes 192.168.20.33 \
  --endpoints 192.168.20.33 \
  --talosconfig ./node-01/talosconfig
```

## Single-Node Talos + MetalLB Note

For single-node clusters using MetalLB in L2 mode, do not set the node label `node.kubernetes.io/exclude-from-external-load-balancers` in Talos machine config.  
If Talos owns that label via `machine.nodeLabels`, it will be reapplied and MetalLB traffic to `LoadBalancer` services can stop working.

## Single-Node Control-Plane Scheduling Note

For this cluster shape, keep `cluster.allowSchedulingOnControlPlanes: true` in the Talos machine config.

If that setting is omitted, Talos leaves the `node-role.kubernetes.io/control-plane:NoSchedule` taint in place. On a single-node cluster that means normal workloads such as Argo CD, Envoy, cloudflared, and app pods can stay `Pending` after a reboot even though the node itself is `Ready`.
