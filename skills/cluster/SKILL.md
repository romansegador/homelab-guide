---
name: cluster
description: Homelab Guide chapter 2. Use when installing a single-node Kubernetes cluster with k3s on the homelab machine - pinned version, config file in git, embedded etcd with scheduled snapshots on /data plus a nightly Proxmox VM backup (optional S3 upload), secrets encryption, local-path storage on /data - and setting up kubectl, k9s, helm and the kubeconfig on the user's laptop.
---

# Chapter 2: The cluster

You're helping the user install k3s on the machine from chapter 1 and manage it from their laptop.

Guide page: `/cluster/install/` (or `src/content/docs/cluster/install.mdx` in the guide repo).
Reasoning behind the choices: `/start-here/faq/` (chapter 2 section).
Example files: `examples/02-cluster/` (`config.yaml`, `test-volume.yaml`, and `create-etcd-s3-secret.sh`
for the optional bucket upload).

## Ground rules

- **Never ask for, print or handle secret values.** In this chapter those are: the k3s **server
  token**, the **kubeconfig** (it's the cluster admin key), and, with the optional bucket upload,
  the bucket's **access keys**. The user copies the token and kubeconfig into their password
  manager themselves, and enters bucket keys into `create-etcd-s3-secret.sh` (hidden prompts). Never `cat` the token,
  never paste the kubeconfig's contents anywhere, never put keys in `config.yaml`.
- **Installing k3s, rebooting, creating or changing a Proxmox backup job, or deleting anything
  needs the user's explicit OK.** Show the exact commands first.
- The config file holds no secrets and belongs in the user's private repo (`infra/k3s/`).
- k3s uploads snapshots only to **S3-compatible** storage. SFTP/rsync targets (for example a
  Hetzner Storage Box) can't receive them; they get the VM backups later instead.
- When using `etcd-s3-config-secret`, set **no other `etcd-s3-*` options** in `config.yaml`, or k3s
  ignores the Secret.

## Ask first

1. The machine's DNS name or IP, and the SSH user (`ops` in the guide).
2. The Proxmox backup storage outside the machine (for example a NAS), and whether a backup job
   already exists that the VM can join (`pvesh get /cluster/backup`, read-only).
3. Whether `~/.kube/config` already exists on the laptop (merge instead of overwrite).

## Steps

1. Laptop: `brew install kubernetes-cli k9s helm`. `kubectl version --client` must be >= 1.36
   (kubectl supports clusters one minor version older or newer than itself). Watch for an older
   kubectl earlier in `PATH`, for example Docker Desktop's in `/usr/local/bin`.
2. Copy `examples/02-cluster/` to `infra/k3s/`. Set `tls-san` to the machine's DNS name.
   `scp` it to the machine, then `sudo install -D -m 600 … /etc/rancher/k3s/config.yaml`.
3. Machine: download `https://get.k3s.io` to a file, then
   `sudo INSTALL_K3S_VERSION=<pinned> sh /tmp/install-k3s.sh`. Check `sudo k3s kubectl get nodes`.
4. The user saves `/var/lib/rancher/k3s/server/token` to their password manager. They're needed
   for restoring snapshots on a new host.
5. Kubeconfig: the user runs the guide's `ssh … sudo cat /etc/rancher/k3s/k3s.yaml | sed … >
   ~/.kube/lab-1.yaml`. Merge with an existing config (back it up first), then
   `kubectl config use-context <name>`.
6. Machine: `sudo k3s etcd-snapshot save --name first`, then `sudo k3s etcd-snapshot ls`: a
   `file://` entry under `/data/etcd-snapshots`.
7. Nightly VM backup (with the user's OK): add the VM to an existing job, or create one
   (UI *Datacenter → Backup → Add*, or `pvesh create /cluster/backup --schedule 02:30 --vmid <id>
   --storage <storage> --mode snapshot --compress zstd --prune-backups keep-daily=7,keep-weekly=4`),
   then *Run now*.
8. Optional bucket upload: separate bucket + scoped key, `bash infra/k3s/create-etcd-s3-secret.sh`
   (the user enters the values), uncomment `etcd-s3` / `etcd-s3-config-secret`, copy the config,
   `sudo systemctl restart k3s`, take a snapshot: both `file://` and `s3://` entries appear.

## Verify

- `kubectl get nodes` → Ready. `kubectl get pods -A` → all Running/Completed.
- `test-volume.yaml`: `kubectl exec test-volume -- cat /mnt/hello.txt`. On the machine, the file
  is under `/data/local-path`. Delete the test afterwards.
- `sudo k3s secrets-encrypt status` → Enabled.
- `kubectl -n kube-system get svc traefik` → EXTERNAL-IP is the machine's IP. HTTP returns 404.
- After a reboot (with the user's OK): node Ready, pods back to Running.

## Done when

- [ ] All checks pass, also after a reboot.
- [ ] Token and kubeconfig (and bucket keys, if used) are in the password manager. `infra/k3s/`
      is committed.
- [ ] The VM is in a nightly backup job, and a first backup has run.
- [ ] Next chapter: **gitops**.
