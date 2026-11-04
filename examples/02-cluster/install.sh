#!/usr/bin/env bash
# Install k3s on the machine, from your laptop, with the config.yaml next to this script.
#
#   bash infra/k3s/install.sh ops@lab-1.home.example.com
#
# It runs four steps over SSH, and you can rerun it safely:
#   1. copies config.yaml to /etc/rancher/k3s/config.yaml on the machine,
#   2. installs k3s at the pinned version below, with the official install script,
#   3. waits for the node to be Ready, and takes a first etcd snapshot,
#   4. saves the kubeconfig as ~/.kube/<machine>.yaml, pointed at the machine's name.
# It never prints the kubeconfig or the server token.
set -euo pipefail

K3S_VERSION="v1.37.2+k3s1"

if [ $# -ne 1 ] || [[ "$1" != *@* ]]; then
  echo "Usage: bash install.sh <user>@<machine DNS name>" >&2
  exit 1
fi
target="$1"
host="${target#*@}"
name="${host%%.*}"
here="$(cd "$(dirname "$0")" && pwd)"
kubeconfig="$HOME/.kube/$name.yaml"

echo "1/4 Copying config.yaml to the machine"
ssh "$target" 'sudo install -D -m 600 /dev/stdin /etc/rancher/k3s/config.yaml' < "$here/config.yaml"

echo "2/4 Installing k3s $K3S_VERSION (about a minute)"
ssh "$target" "curl -sfL https://get.k3s.io -o /tmp/install-k3s.sh \
  && sudo INSTALL_K3S_VERSION='$K3S_VERSION' sh /tmp/install-k3s.sh \
  && rm /tmp/install-k3s.sh"

echo "3/4 Waiting for the node to be Ready, then taking a first snapshot"
ssh "$target" 'for i in $(seq 60); do
    sudo k3s kubectl get nodes --no-headers 2>/dev/null | grep -qw Ready && break
    sleep 5
  done
  sudo k3s kubectl get nodes --no-headers | grep -qw Ready \
    || { echo "The node is not Ready after 5 minutes. Check: sudo journalctl -u k3s" >&2; exit 1; }
  sudo k3s etcd-snapshot save --name first >/dev/null'

echo "4/4 Saving the kubeconfig as $kubeconfig"
mkdir -p "$HOME/.kube"
umask 077
ssh "$target" 'sudo cat /etc/rancher/k3s/k3s.yaml' \
  | sed -e "s/127\.0\.0\.1/$host/" -e "s/: default\$/: $name/" > "$kubeconfig.tmp"
mv "$kubeconfig.tmp" "$kubeconfig"

echo "Done. k3s $K3S_VERSION is running on $host, and its context is called \"$name\"."
