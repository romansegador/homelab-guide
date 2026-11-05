#!/usr/bin/env bash
# Put the Bitwarden machine account's access token in the cluster: the one secret you create by
# hand. Every other secret then comes from Bitwarden through External Secrets.
#
#   bash bootstrap/add-bitwarden-token.sh
#
# It asks for the token with hidden input (paste it from your password manager and press Enter),
# and stores it as the Secret external-secrets/bitwarden-access-token. The token never appears on
# screen, in your shell history, or on the command line of a running process.
# Rerun it to replace the token, for example after rotating it in Bitwarden.
set -euo pipefail

namespace="external-secrets"
name="bitwarden-access-token"

context="$(kubectl config current-context)"
printf 'Store the Bitwarden access token in the cluster "%s"? [y/N] ' "$context"
read -r answer
[ "$answer" = "y" ] || { echo "Stopped. Nothing was changed." >&2; exit 1; }

printf 'Bitwarden machine account access token: ' >&2
IFS= read -r -s token
printf '\n' >&2
[ -n "$token" ] || { echo "Empty token. Nothing was changed." >&2; exit 1; }

kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl -n "$namespace" create secret generic "$name" \
    --from-file=token=<(printf '%s' "$token") \
    --dry-run=client -o yaml \
  | kubectl apply -f -
unset token

echo "Done. External Secrets reads it from $namespace/$name."
