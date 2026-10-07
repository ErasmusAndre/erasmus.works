# Talos Upgrade

Upgrade Talos one minor version at a time, worker first, control plane last.
Renovate opens a PR on [talos/versions.yaml](../../talos/versions.yaml) when a new version is out.

Run this from the home network (or over VPN). The Talos API (`:50000`) and Kubernetes API (`:6443`) are LAN-only.

## Path From 1.12.4

| Step | Talos | Kubernetes after | Done |
| --- | --- | --- | --- |
| 1 | `v1.12.12` | `v1.35.x` (optional patch) | 2026-10-07 |
| 2 | `v1.13.11` | `v1.36.x` | 2026-10-07 (Kubernetes `v1.36.5`) |
| 3 | `v1.14.2` | `v1.37.x` | 2026-10-07 (Talos) |

Merge the matching Renovate PR after each step, not before.

## Setup

```bash
cd talos

export CP=192.168.20.33
export WORKER=192.168.20.184   # talos-node-2
export SCHEMATIC=613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245
export TALOSCONFIG="$PWD/node-01/talosconfig"
export KUBECONFIG="$PWD/kubeconfig"
```

Use a `talosctl` that matches the target version of the step, verified against the release checksums:

```bash
export TARGET=v1.12.12
REL="https://github.com/siderolabs/talos/releases/download/$TARGET"
mkdir -p ~/.local/share/talosctl/$TARGET && cd ~/.local/share/talosctl/$TARGET
curl -LO "$REL/talosctl-linux-amd64"
curl -sL "$REL/sha256sum.txt" | grep ' talosctl-linux-amd64$' | sha256sum -c
chmod +x talosctl-linux-amd64 && mv talosctl-linux-amd64 talosctl && cd -
alias talosctl=~/.local/share/talosctl/$TARGET/talosctl
talosctl version --client --short
```

## Before Each Step

```bash
talosctl version -n "$CP","$WORKER" -e "$CP"
talosctl health -n "$CP" -e "$CP"
kubectl get nodes -o wide
kubectl get pods -A | grep -vE 'Running|Completed'
kubectl -n longhorn-system get volumes.longhorn.io   # every attached volume healthy
talosctl get extensions -n "$CP","$WORKER" -e "$CP"  # same schematic on both nodes
```

Upgrading a node with another node's schematic silently drops its extensions.

Take an etcd snapshot (single control-plane node, so this is the only way back):

```bash
mkdir -p ~/talos-backups
talosctl -n "$CP" -e "$CP" etcd snapshot ~/talos-backups/etcd-$(date +%F-%H%M)-before-$TARGET.db
```

Keep snapshots outside the repo. Take a fresh one right before the control plane.

## Upgrade

Worker first:

```bash
talosctl upgrade -n "$WORKER" -e "$CP" \
  --image "factory.talos.dev/installer/$SCHEMATIC:$TARGET"
```

Wait until the node is `Ready` and every attached Longhorn volume is healthy again (rebuild takes 5–10 minutes), then the control plane:

```bash
talosctl upgrade -n "$CP" -e "$CP" \
  --image "factory.talos.dev/installer/$SCHEMATIC:$TARGET"
```

`talosctl upgrade` drains the node first and keeps the data partition, so Longhorn replicas survive.

From talosctl 1.14 the client drains, and a failed drain stops the upgrade before the reboot: the new version is installed but not booted, and the node stays cordoned. With the PDBs below the drain always fails, so finish by hand:

```bash
talosctl reboot -n <node> -e "$CP"
kubectl uncordon <node>
```

## What To Expect

- The drain never completes: single-instance CNPG clusters and Longhorn instance managers have PDBs with 0 allowed disruptions. Up to talosctl 1.13, Talos tries for 5 minutes, logs a warning, then reboots anyway; from 1.14, see above. Postgres is stopped cleanly by the shutdown.
- Each node takes about 8 minutes from cordon to `Ready`. Pods that could not be evicted keep running until the reboot, so apps whose Postgres runs on that node are down for about 4 minutes.
- The Kubernetes API is down for about 1 minute while the control plane reboots.
- Grafana and VictoriaLogs use single-replica volumes on the control plane, so they are down with it.
- Pods stopped by the shutdown can stay listed as `Error` (`terminated in response to imminent node shutdown`) next to their running replacements. Delete them; they are not restarted.
- A single-replica volume can get stuck in `attaching` after the control plane reboots (Longhorn logs `NodeID ... is not the same as the instance manager ... NodeID`). Scale its workload to 0 until the volume is `detached`, then back to 1. Argo CD restores the replica count by itself.

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

Then update the Kubernetes image tags in the node configs and merge the kubelet Renovate PR.

`upgrade-k8s` restarts the control-plane components and kubelets in place (no drain or reboot); the API is unreachable a few times for under a minute.
It also resets the CoreDNS ConfigMap to the Talos default. Argo CD (`kubernetes/infra/coredns-configmap.yaml`, self-heal) restores the custom Corefile within seconds; check that `*.homelab` resolves afterwards.

## Version Notes

- 1.13: `machine.network.nameservers` now replaces defaults instead of merging. Not set here.
- 1.13: Flannel can enforce NetworkPolicy (`kubeNetworkPoliciesEnabled`). Enable it after 1.14, where it moved to the `KubeFlannelCNIConfig` document.
- 1.14: `ghcr.io/siderolabs/installer` is no longer published. Keep using the Image Factory installer; Renovate looks versions up via `ghcr.io/siderolabs/imager`.
- 1.14: workload isolation (`SecurityProfileConfig`) stays off on upgraded clusters. Leave it off until Longhorn is tested with it.
- 1.14: filesystem trim is off on upgraded clusters until a `FilesystemTrimConfig` document is added; see `talos/patches/filesystem-trim.yaml`.
- 1.14: etcd moves to 3.7. Rolling Talos back to 1.13 after that means restoring the pre-upgrade etcd snapshot.
- 1.14: keep the Longhorn mount in the v1alpha1 format; see [longhorn.md](../bootstrap/longhorn.md#talos-requirements).
- 1.14: `apply-config --mode=reboot` was removed.
- 1.14: etcd metrics moved from port `2379` to `2383`. Etcd is not scraped here.

## Rollback

```bash
talosctl rollback -n <node> -e "$CP"
```

Rolls the node back to the previous Talos version on disk. If etcd is broken, recover from the snapshot with `talosctl bootstrap --recover-from=<snapshot>`.




Delete/update this document once the talos upgrade is done. 