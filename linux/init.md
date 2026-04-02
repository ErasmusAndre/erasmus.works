## Init script

This script installs the core packages needed for this repository and useful tools for Talos/Kubernetes setup (`apt-transport-https`, `ca-certificates`, `curl`, `cryptomator`, `fuse3`, `gpg`, `kubectl`, and `talosctl`).

It configures the Kubernetes v1.35 apt repository and can be run multiple times safely (it rewrites the same keyring/source files and re-runs package installs without destructive changes).
It also updates `~/.bashrc` with:
- `alias talos1=...` for the Talos dashboard
- `alias gensec='openssl rand -hex 32'`
- `export KUBECONFIG=<repo-root>/talos/kubeconfig`

Run:

```bash
./linux/init.sh
```
