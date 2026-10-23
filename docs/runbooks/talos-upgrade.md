# Talos Upgrade

Upgrade Talos one minor version at a time, worker first, control plane last.
Renovate opens a PR on [talos/versions.yaml](../../talos/versions.yaml) when a new version is out; each step is one PR. Merge it after the step, not before.

Run this from the home network (or over VPN). The Talos API (`:50000`) and Kubernetes API (`:6443`) are LAN-only.

## Setup

```bash
cd talos

export CP=192.168.20.33
export WORKER=192.168.20.184   # talos-node-2
export SCHEMATIC=$(grep -oE 'installer/[0-9a-f]{64}' versions.yaml | cut -d/ -f2)
export TARGET=v1.x.y           # version from the Renovate PR; the current version when only changing extensions
export TALOSCONFIG="$PWD/node-01/talosconfig"
export KUBECONFIG="$PWD/kubeconfig"
```

Use a `talosctl` that matches `TARGET`, verified against the release checksums:

```bash
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

From talosctl 1.14 the client drains, and a failed drain stops the upgrade before the reboot: the new version is installed but not booted, and the node stays cordoned. With the PDBs below the drain always fails, so once the command exits, finish by hand right away:

```bash
talosctl reboot -n "$WORKER" -e "$CP"
kubectl uncordon talos-node-2   # as soon as it is Ready; don't wait for Longhorn
```

While the drain runs, evicted pods go `Pending`: the control plane is near 100% memory requests and cannot take the worker's pods. They come back after the uncordon.

Wait until every attached Longhorn volume is healthy again (rebuild takes 5–10 minutes), take a fresh etcd snapshot, then the control plane without a drain:

```bash
talosctl upgrade -n "$CP" -e "$CP" --drain=false \
  --image "factory.talos.dev/installer/$SCHEMATIC:$TARGET"
```

A drain there would evict pods onto the worker, which has no room either. With `--drain=false` the node installs, reboots and restarts its pods in place. `talosctl upgrade` keeps the data partition, so Longhorn replicas survive.

## Changing Extensions

Adding or removing a Talos extension (e.g. `siderolabs/i915` for the Intel iGPU) is the same procedure with the current version as `TARGET`:

1. Edit [talos/image-factory/schematic.yaml](../../talos/image-factory/schematic.yaml) and get the new ID: `curl -X POST --data-binary @image-factory/schematic.yaml https://factory.talos.dev/schematics`.
2. Put the new ID in the installer image in [talos/versions.yaml](../../talos/versions.yaml), then re-run Setup so `SCHEMATIC` picks it up. Both nodes use the same schematic.
3. Upgrade both nodes as above, then update `machine.install.image` (see "After Each Step").

Don't push workloads that need the new extension (e.g. a `gpu.intel.com/i915` request) until both nodes have it. A pod that can't schedule leaves Argo CD waiting on its health forever, and later fixes in Git aren't applied until that sync is terminated (Argo UI → app → Terminate).

## What To Expect

- The drain never completes: single-instance CNPG clusters and Longhorn instance managers have PDBs with 0 allowed disruptions. Up to talosctl 1.13, Talos tries for 5 minutes, logs a warning, then reboots anyway; from 1.14, see above. Postgres is stopped cleanly by the shutdown.
- Each node takes about 8 minutes from cordon to `Ready`. Pods that could not be evicted keep running until the reboot, so apps whose Postgres runs on that node are down for about 4 minutes.
- The Kubernetes API is down for about 1 minute while the control plane reboots.
- Grafana and VictoriaLogs use single-replica volumes on the control plane, so they are down with it.
- Pods stopped by the shutdown can stay listed as `Error` (`terminated in response to imminent node shutdown`) next to their running replacements. Delete them; they are not restarted: `kubectl delete pods -A --field-selector=status.phase=Failed`.
- After the control plane reboot, operators (CNPG, VolSync, Longhorn driver deployer, kube-state-metrics) crash-loop for a few minutes until the API settles. Apps whose init containers wait for Postgres can sit in a 5-minute back-off afterwards; they recover on the next retry.
- A single-replica volume can get stuck in `attaching` after the control plane reboots (Longhorn logs `NodeID ... is not the same as the instance manager ... NodeID`). Scale its workload to 0 until the volume is `detached`, then back to 1. Argo CD restores the replica count by itself.

## After Each Step

- Run the checks from "Before Each Step" again.
- `talosctl upgrade` does not change `machine.install.image` in the live config, which a reinstall or reset would use. Update it on each node, and in `node-01/controlplane.yaml` and `node-02/worker.yaml`:

  ```bash
  talosctl patch mc -n <node> -e "$CP" \
    --patch '{"machine":{"install":{"image":"factory.talos.dev/installer/'"$SCHEMATIC:$TARGET"'"}}}'
  ```
- Merge the Renovate PR for the installer, or update [talos/versions.yaml](../../talos/versions.yaml) by hand.

## Kubernetes

After the Talos step that supports it, one minor at a time:

```bash
talosctl -n "$CP" -e "$CP" upgrade-k8s --to <version> --dry-run
talosctl -n "$CP" -e "$CP" upgrade-k8s --to <version>
```

Then update the Kubernetes image tags in the node configs and merge the kubelet Renovate PR.

`upgrade-k8s` restarts the control-plane components and kubelets in place (no drain or reboot); the API is unreachable a few times for under a minute.
Controllers with leader election (CNPG operator, Longhorn CSI sidecars) restart once each when the API goes away; that is expected.
It also resets the CoreDNS ConfigMap to the Talos default. Argo CD (`kubernetes/infra/coredns-configmap.yaml`, self-heal) restores the custom Corefile within seconds; check that `*.homelab` resolves afterwards.

## Notes

- Use the Image Factory installer; `ghcr.io/siderolabs/installer` is no longer published (1.14+). Renovate looks versions up via the `siderolabs/talos` GitHub releases.
- Workload isolation (`SecurityProfileConfig`) is off on this upgraded cluster. Leave it off until Longhorn is tested with it.
- Keep the Longhorn mount in the v1alpha1 format; see [longhorn.md](../bootstrap/longhorn.md#talos-requirements).
- `apply-config --mode=reboot` no longer exists (1.14+).
- Read the release notes for each minor before upgrading; anything that changes the procedure belongs in this file.

## Rollback

```bash
talosctl rollback -n <node> -e "$CP"
```

Rolls the node back to the previous Talos version on disk. If etcd is broken, recover from the snapshot with `talosctl bootstrap --recover-from=<snapshot>`.
