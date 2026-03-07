#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y curl cryptomator fuse3

curl -sL https://talos.dev/install | sh

# Use talosctl from PATH when available, otherwise fallback to default install dir.
if command -v talosctl >/dev/null 2>&1; then
  talosctl version --client
elif [ -x "$HOME/.talos/bin/talosctl" ]; then
  "$HOME/.talos/bin/talosctl" version --client
else
  echo "talosctl installed but not found in PATH."
  echo "Try: export PATH=\"\$PATH:\$HOME/.talos/bin\""
  exit 1
fi
