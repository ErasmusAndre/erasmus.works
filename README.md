# Talos Node Setup

Reference video: https://www.youtube.com/watch?v=VKfE5BuqlSc  
Official guide: https://docs.siderolabs.com/talos/v1.12/getting-started/getting-started

## Prerequisites

- Install Talos ISO on a USB drive.
- From your PC, install `talosctl` if needed: `curl -sL https://talos.dev/install | sh`

## Quick Start (TL;DR)

Set environment variables, for example:

```bash
CONTROL_PLANE_IP=192.168.178.33
CLUSTER_NAME=homelab
DISK_NAME=nvme0n1
```

Run the setup commands:

- Generate config files: `talosctl gen config $CLUSTER_NAME https://$CONTROL_PLANE_IP:6443 --install-disk /dev/$DISK_NAME`
- Check disk name: `talosctl get disks --nodes 192.168.xx.xx --endpoints 192.168.xx.xx --insecure`
- Apply config: `talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml`

The node should now restart. Remove the USB drive.  
After restart, state should transition from Maintenance mode to Booting.

- Bootstrap the node: `talosctl bootstrap -n $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP --talosconfig ./talosconfig`
- The stage should now be Running.

Open the dashboard:

`talosctl dashboard -n $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP --talosconfig ./talosconfig`
