#!/usr/bin/env bash
set -euo pipefail

step() { printf "\n==> %s\n" "$1"; }

step "Updating apt package index"
sudo apt-get update

step "Installing required packages (apt-transport-https, ca-certificates, curl, cryptomator, fuse3, gpg)"
sudo apt-get install -y apt-transport-https ca-certificates curl cryptomator fuse3 gpg

step "Configuring Kubernetes apt repository"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key \
  | gpg --dearmor \
  | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

step "Updating apt package index after adding Kubernetes repository"
sudo apt-get update

step "Installing/updating kubectl"
sudo apt-get install -y kubectl

step "Installing/updating talosctl"
curl -sL https://talos.dev/install | sh

step "Configuring talos1 alias"
sed -i "/^alias talos1/d" "$HOME/.bashrc"
echo "alias talos1='talosctl dashboard -n 192.168.20.33 -e 192.168.20.33 --talosconfig \$HOME/code/erasmus.works/talos/node-01/talosconfig'" >> "$HOME/.bashrc"

step "Done"
echo "Run this once in your current shell:"
echo "  source ~/.bashrc"
