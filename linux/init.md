## Init script

This script installs the core packages needed for this repository and useful tools for Talos/Kubernetes setup (`apt-transport-https`, `ca-certificates`, `curl`, `cryptomator`, `fuse3`, `gpg`, `kubectl`, and `talosctl`).

It configures the Kubernetes v1.35 apt repository and can be run multiple times safely (it rewrites the same keyring/source files and re-runs package installs without destructive changes).

Run:

```bash
./linux/init.sh
```
