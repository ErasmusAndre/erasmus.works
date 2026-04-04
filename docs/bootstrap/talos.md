# Talos Notes

## Current State

- Talos runs the homelab Kubernetes cluster.
- The current control-plane node is `192.168.20.33`.
- Cluster access uses `talos/node-01/talosconfig`.
- Kubernetes access uses `talos/kubeconfig`.
- Existing cluster secrets live in `talos/node-01/secrets.yaml`.
- `talosctl bootstrap` was already run when this cluster was created. Do not run it again when adding nodes.

## Repo Paths

- `talos/node-01/`: current cluster-generated Talos config and secrets
- `talos/patches/single-node-controlplane.yaml`: keeps workloads schedulable on the current single control-plane node
- `talos/patches/longhorn-host-path.yaml`: kubelet mount needed for Longhorn nodes
- `talos/image-factory/longhorn.yaml`: Talos system extensions for Longhorn nodes

## Add A Worker Node

Boot the new machine from the Talos installer USB and note its temporary Talos IP.

```bash
cd talos

export CLUSTER_NAME=homelab
export CONTROL_PLANE_IP=192.168.20.33
export NEW_NODE_IP=192.168.20.xx
export INSTALL_DISK=/dev/sdX
export NODE_DIR=node-02

talosctl get disks --nodes "$NEW_NODE_IP" --endpoints "$NEW_NODE_IP" --insecure

mkdir -p "$NODE_DIR"

talosctl gen config \
  --with-secrets ./node-01/secrets.yaml \
  "$CLUSTER_NAME" \
  "https://$CONTROL_PLANE_IP:6443" \
  --install-disk "$INSTALL_DISK" \
  --output-dir "./$NODE_DIR"

talosctl apply-config \
  --insecure \
  --nodes "$NEW_NODE_IP" \
  --file "./$NODE_DIR/worker.yaml"
```

After apply:

- remove the USB
- boot from the installed disk
- wait for the node to join the cluster

## Verify

```bash
export KUBECONFIG="$PWD/talos/kubeconfig"

kubectl get nodes -o wide
kubectl get pods -A
```

Optional Talos check:

```bash
talosctl health \
  --nodes 192.168.20.33 \
  --endpoints 192.168.20.33 \
  --talosconfig ./talos/node-01/talosconfig
```

## Notes

- New nodes must reuse `talos/node-01/secrets.yaml`.
- Do not run `talosctl gen secrets` for an existing cluster.
- Generated per-node directories such as `talos/node-02/` are operational artifacts, not the source of truth.
- For Longhorn-specific Talos changes, use `docs/bootstrap/longhorn.md`.
