# Longhorn Notes

## Current State

- Longhorn is installed from `kubernetes/infra/longhorn/`.
- Longhorn stores data at `/var/lib/longhorn`.
- This repo currently targets a 2-node intermediate setup.
- New Longhorn volumes default to 2 replicas.
- This improves storage redundancy, but it is not full cluster HA while the cluster still has a single control-plane node.

## Repo Paths

- `kubernetes/infra/longhorn/application.yaml`
- `kubernetes/infra/longhorn/values.yaml`
- `talos/image-factory/longhorn.yaml`
- `talos/patches/longhorn-host-path.yaml`

## Talos Requirements

Every node that should host Longhorn replicas needs:

- Talos system extensions:
  - `siderolabs/iscsi-tools`
  - `siderolabs/util-linux-tools`
- a kubelet bind mount for `/var/lib/longhorn`

This repo keeps Longhorn on the existing Talos `EPHEMERAL` disk path instead of using a separate `UserVolumeConfig`.

Keep the mount in the v1alpha1 `machine.kubelet.extraMounts` format. Talos 1.14+ still honors it for upgraded clusters, but the new `KubeletConfig` document has no `extraMounts`; moving the patch to it removes the mount. Switching to a `UserVolumeConfig` means moving the data to `/var/mnt/<name>` first ([siderolabs/talos#14411](https://github.com/siderolabs/talos/issues/14411)).

## Apply To A Node

The committed Longhorn image-factory schematic currently resolves to:

```bash
export SCHEMATIC_ID=613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245
```

Example:

```bash
export CONTROL_PLANE_IP=192.168.20.33
export NODE_IP=192.168.20.xx
export SCHEMATIC_ID=613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245

talosctl patch machineconfig \
  --nodes "$NODE_IP" \
  --endpoints "$CONTROL_PLANE_IP" \
  --talosconfig ./talos/node-01/talosconfig \
  --patch @./talos/patches/longhorn-host-path.yaml

talosctl upgrade \
  --nodes "$NODE_IP" \
  --endpoints "$CONTROL_PLANE_IP" \
  --talosconfig ./talos/node-01/talosconfig \
  --image "factory.talos.dev/installer/${SCHEMATIC_ID}:v1.12.4"
```

Reboot the node after the upgrade and wait for it to return.

## Verify

```bash
talosctl get extensions --nodes 192.168.20.xx --endpoints 192.168.20.33 --talosconfig ./talos/node-01/talosconfig
talosctl mounts --nodes 192.168.20.xx --endpoints 192.168.20.33 --talosconfig ./talos/node-01/talosconfig

export KUBECONFIG="$PWD/talos/kubeconfig"
kubectl -n longhorn-system get pods
kubectl get nodes -o wide
```

## Notes

- Replica defaults are set in `kubernetes/infra/longhorn/values.yaml`.
- Current defaults are `defaultSettings.defaultReplicaCount: 2` and `persistence.defaultClassReplicaCount: 2`.
- Revisit replica count again when adding a third Longhorn-capable node.
