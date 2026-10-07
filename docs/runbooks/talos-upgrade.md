# Talos Upgrade

Upgrade Talos one minor version at a time, worker first, control plane last.
Renovate opens a PR on [talos/versions.yaml](../../talos/versions.yaml) when a new version is out.

Run this from the home network (or over VPN). The Talos API (`:50000`) and Kubernetes API (`:6443`) are LAN-only.

## Path From 1.12.4

| Step | Talos | Kubernetes after |
| --- | --- | --- |
| 1 | `v1.12.12` | `v1.35.x` (optional patch) |
| 2 | `v1.13.11` | `v1.36.x` |
| 3 | `v1.14.2` | `v1.37.x` |

Merge the matching Renovate PR after each step, not before.

## Setup

```bash
cd talos

export CP=192.168.20.33
export WORKER=192.168.20.xx   # node 2
export SCHEMATIC=613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245
export TALOSCONFIG="$PWD/node-01/talosconfig"
export KUBECONFIG="$PWD/kubeconfig"
```

Use a `talosctl` that matches the target version of the step:

```bash
export TARGET=v1.12.12
curl -L -o ~/.local/bin/talosctl \
  "https://github.com/siderolabs/talos/releases/download/$TARGET/talosctl-linux-amd64"
chmod +x ~/.local/bin/talosctl
talosctl version --client --short
```

## Before Each Step

```bash
talosctl version -n "$CP","$WORKER" -e "$CP"
talosctl health -n "$CP" -e "$CP"
kubectl get nodes -o wide
kubectl get pods -A | grep -vE 'Running|Completed'
kubectl -n longhorn-system get volumes.longhorn.io   # every volume healthy, 2 replicas
```

Take an etcd snapshot (single control-plane node, so this is the only way back):

```bash
talosctl -n "$CP" -e "$CP" etcd snapshot "etcd-$(date +%F)-before-$TARGET.db"
```

Keep the snapshot outside the repo.

## Upgrade

Worker first:

```bash
talosctl upgrade -n "$WORKER" -e "$CP" \
  --image "factory.talos.dev/installer/$SCHEMATIC:$TARGET"
```

Wait until the node is `Ready` and every Longhorn volume is healthy again, then the control plane:

```bash
talosctl upgrade -n "$CP" -e "$CP" \
  --image "factory.talos.dev/installer/$SCHEMATIC:$TARGET"
```

The Kubernetes API is down while the control-plane node reboots.
`talosctl upgrade` drains the node first and keeps the data partition, so Longhorn replicas survive.

## After Each Step

- Run the checks from "Before Each Step" again.
- Update `machine.install.image` in `node-01/controlplane.yaml` and `node-01/worker.yaml` to the new tag.
- Merge the Renovate PR for the installer, or update [talos/versions.yaml](../../talos/versions.yaml) by hand.

## Kubernetes

After the Talos step that supports it, one minor at a time:

```bash
talosctl -n "$CP" -e "$CP" upgrade-k8s --to 1.36.5 --dry-run
talosctl -n "$CP" -e "$CP" upgrade-k8s --to 1.36.5
```

Then update the kubelet tag in the node configs and merge the kubelet Renovate PR.

## Version Notes

- 1.13: `machine.network.nameservers` now replaces defaults instead of merging. Not set here.
- 1.13: Flannel can enforce NetworkPolicy (`kubeNetworkPoliciesEnabled`). Enable it after 1.14, where it moved to the `KubeFlannelCNIConfig` document.
- 1.14: `ghcr.io/siderolabs/installer` is no longer published. Keep using the Image Factory installer; Renovate looks versions up via `ghcr.io/siderolabs/imager`.
- 1.14: workload isolation (`SecurityProfileConfig`) stays off on upgraded clusters. Leave it off until Longhorn is tested with it.
- 1.14: filesystem trim is off on upgraded clusters until a `FilesystemTrimConfig` document is added.
- 1.14: `apply-config --mode=reboot` was removed.
- 1.14: etcd metrics moved from port `2379` to `2383`. Etcd is not scraped here.

## Rollback

```bash
talosctl rollback -n <node> -e "$CP"
```

Rolls the node back to the previous Talos version on disk. If etcd is broken, recover from the snapshot with `talosctl bootstrap --recover-from=<snapshot>`.




Delete/update this document once the talos upgrade is done. 