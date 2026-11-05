#!/usr/bin/env bash
# Give ArgoCD read-only access to your private config repository, with a GitHub deploy key.
#
#   bash bootstrap/add-repo-key.sh git@github.com:<YOUR_GITHUB_USER>/<YOUR_CONFIG_REPO>.git
#
# It:
#   1. makes a new SSH key pair in a temporary folder,
#   2. stores the private key in the cluster as an ArgoCD repository Secret, without showing it,
#   3. prints the public key, for you to add on GitHub as a read-only deploy key,
#   4. deletes the temporary folder, so the private key exists only in the cluster.
#
# There's nothing to keep in your password manager: if you rebuild the cluster or lose the key,
# run this again and replace the deploy key on GitHub.
set -euo pipefail

url="${1:-}"
case "$url" in
  git@*:*/*.git) ;;
  *)
    echo "Usage: bash bootstrap/add-repo-key.sh git@github.com:<user>/<repo>.git" >&2
    echo "Use the SSH address (git@…), not https://: deploy keys work over SSH." >&2
    exit 1
    ;;
esac

context="$(kubectl config current-context)"
printf 'Create the repository Secret in the cluster "%s"? [y/N] ' "$context"
read -r answer
[ "$answer" = "y" ] || { echo "Stopped. Nothing was changed." >&2; exit 1; }

kubectl get namespace argocd >/dev/null \
  || { echo "No argocd namespace: install ArgoCD first." >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

ssh-keygen -q -t ed25519 -N "" -C "argocd@$context" -f "$tmp/key"

kubectl -n argocd create secret generic config-repo \
    --from-literal=type=git \
    --from-literal=url="$url" \
    --from-file=sshPrivateKey="$tmp/key" \
    --dry-run=client -o yaml \
  | kubectl label --local -f - argocd.argoproj.io/secret-type=repository -o yaml \
  | kubectl apply -f -

echo
echo "Now add this public key on GitHub: your repository → Settings → Deploy keys → Add deploy key."
echo "Leave \"Allow write access\" unticked."
echo
cat "$tmp/key.pub"
