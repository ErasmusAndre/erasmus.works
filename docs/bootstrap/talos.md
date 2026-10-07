# Talos Notes

## Current State

- Talos runs the homelab Kubernetes cluster.
- The current control-plane node is `192.168.20.33`.
- Cluster access uses `talos/node-01/talosconfig`.
- Kubernetes access uses `talos/kubeconfig`.
- Existing cluster secrets live in `talos/node-01/secrets.yaml`.
- `talosctl bootstrap` was already run when this cluster was created. Do not run it again when adding nodes.

## Repo Paths

- `talos/node-01/`: current cluster-generated Talos config and secrets. `worker.yaml` here is the generic template, not node 2's config; never apply it to an existing worker.
- `talos/node-02/worker.yaml`: node 2's live config (hostname, install disk), saved with `talosctl get mc v1alpha1 -o jsonpath='{.spec}'`
- `talos/patches/single-node-controlplane.yaml`: keeps workloads schedulable on the current single control-plane node
- `talos/patches/longhorn-host-path.yaml`: kubelet mount needed for Longhorn nodes
- `talos/patches/filesystem-trim.yaml`: weekly SSD trim (Talos 1.14+), applied to all nodes
- `talos/patches/flannel-network-policies.yaml`: NetworkPolicy enforcement in Flannel (Talos 1.14+), control plane only; moves `cluster.network` to `KubeNetworkConfig`. Takes effect after `upgrade-k8s` re-applies the bootstrap manifests
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

## Backup

`node-01/secrets.yaml`, `node-01/talosconfig` and `node-02/worker.yaml` are gitignored and exist only locally. A copy of each is in Bitwarden Secrets Manager, in the `talos-admin` project:

| Bitwarden key | File |
| --- | --- |
| `talos-secrets-yaml` | `talos/node-01/secrets.yaml` |
| `talos-talosconfig` | `talos/node-01/talosconfig` |
| `talos-node-02-worker-yaml` | `talos/node-02/worker.yaml` |

`talos-admin` is shared only with the workstation machine account. Never give the External Secrets machine account access: these are the cluster's root keys.

Restore (with the `bws` setup from [bitwarden-external-secrets.md](bitwarden-external-secrets.md#creating-secrets-from-the-cli)):

```bash
PROJECT=$(bws project list --output json | jq -r '.[] | select(.name == "talos-admin").id')
bws secret list "$PROJECT" --output json | jq -r '.[] | select(.key == "talos-secrets-yaml").value' > talos/node-01/secrets.yaml
bws secret list "$PROJECT" --output json | jq -r '.[] | select(.key == "talos-talosconfig").value' > talos/node-01/talosconfig
mkdir -p talos/node-02
bws secret list "$PROJECT" --output json | jq -r '.[] | select(.key == "talos-node-02-worker-yaml").value' > talos/node-02/worker.yaml
chmod 600 talos/node-01/secrets.yaml talos/node-01/talosconfig talos/node-02/worker.yaml
```

Update these secrets whenever the files change.
