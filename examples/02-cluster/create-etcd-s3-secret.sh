#!/usr/bin/env bash
# Create (or update) the Secret k3s reads to upload etcd snapshots to S3-compatible storage.
#
#   bash create-etcd-s3-secret.sh
#
# Run it on your laptop, with kubectl pointing at the cluster. It asks for the bucket details;
# the access keys are read with hidden input. They go straight to the cluster: nothing is written
# to disk, to your shell history, or to the command line other programs can see.
set -euo pipefail

SECRET_NAME="k3s-etcd-snapshot-s3-config"

context="$(kubectl config current-context)"
read -r -p "kubectl context is '${context}'. Create the Secret there? [y/N] " ok
[ "$ok" = "y" ] || [ "$ok" = "Y" ] || { echo "Stopped." >&2; exit 1; }

read -r -p "S3 endpoint, host only, no https:// (e.g. <ACCOUNT_ID>.r2.cloudflarestorage.com): " endpoint
read -r -p "Bucket: " bucket
read -r -p "Folder inside the bucket [k3s]: " folder
folder="${folder:-k3s}"
read -r -p "Region [auto]: " region
region="${region:-auto}"
read -r -s -p "Access Key ID: " access_key; echo
read -r -s -p "Secret Access Key: " secret_key; echo

# Strip a pasted scheme, just in case.
endpoint="${endpoint#https://}"
endpoint="${endpoint%/}"

kubectl -n kube-system create secret generic "$SECRET_NAME" \
  --type=etcd.k3s.cattle.io/s3-config-secret \
  --from-env-file=<(printf '%s\n' \
    "etcd-s3-endpoint=${endpoint}" \
    "etcd-s3-bucket=${bucket}" \
    "etcd-s3-folder=${folder}" \
    "etcd-s3-region=${region}" \
    "etcd-s3-access-key=${access_key}" \
    "etcd-s3-secret-key=${secret_key}") \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Done. Check with: kubectl -n kube-system get secret ${SECRET_NAME}"
