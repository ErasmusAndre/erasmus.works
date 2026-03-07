#!/usr/bin/env bash
set -euo pipefail

step() { printf "\n==> %s\n" "$1"; }

step "Updating apt package index"
sudo apt update

step "Installing required packages (curl, cryptomator, fuse3)"
sudo apt install -y curl cryptomator fuse3

step "Installing/updating talosctl"
curl -sL https://talos.dev/install | sh

step "Configuring talos1 alias"
sed -i "/^alias talos1/d" "$HOME/.bashrc"
echo "alias talos1='talosctl dashboard -n 192.168.20.33 -e 192.168.20.33 --talosconfig \$HOME/code/erasmus.works/talos/node-01/talosconfig'" >> "$HOME/.bashrc"

step "Done"
echo "Run this once in your current shell:"
echo "  source ~/.bashrc"
