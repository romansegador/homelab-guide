---
name: cluster
description: Homelab Guide chapter 2. Use when installing a single-node Kubernetes cluster with k3s on the homelab machine - pinned version, config file in git, embedded etcd with scheduled snapshots on /data plus a nightly Proxmox VM backup (optional S3 upload), secrets encryption, local-path storage on /data - and setting up kubectl, k9s, helm and the kubeconfig on the user's laptop.
---

# Chapter 2: The cluster

You're helping the user install k3s on the machine from chapter 1 and manage it from their laptop.

Guide page: `/cluster/install/` (or `src/content/docs/cluster/install.mdx` in the guide repo).
Reasoning behind the choices: `/start-here/faq/` (chapter 2 section).
Example files: `examples/02-cluster/` (`config.yaml`, `install.sh`, `test-volume.yaml`, and
`create-etcd-s3-secret.sh` for the optional bucket upload).

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
3. Which shell the user runs (`~/.zshrc` or `~/.bashrc` for the KUBECONFIG line).

## Steps

1. Laptop: `brew install kubernetes-cli k9s helm`. `kubectl version --client` must be >= 1.36
   (kubectl supports clusters one minor version older or newer than itself). Watch for an older
   kubectl earlier in `PATH`, for example Docker Desktop's in `/usr/local/bin`.
2. Copy `examples/02-cluster/` to `infra/k3s/`. Set `tls-san` to the machine's DNS name.
3. Laptop (with the user's OK): `bash infra/k3s/install.sh <user>@<machine>`. It copies the config,
   installs k3s at the version pinned in the script (official `get.k3s.io` script), waits for
   `Ready`, takes a `first` snapshot and writes `~/.kube/<machine>.yaml`. It never prints secrets.
   Rerun it after changing `config.yaml` (the installer restarts k3s).
4. The user saves the server token (`ssh <user>@<machine> sudo cat /var/lib/rancher/k3s/server/token | pbcopy`)
   and the kubeconfig (`pbcopy < ~/.kube/<machine>.yaml`) to their password manager, as secure notes. The token is needed to restore snapshots
   on a new host. Never run that command yourself.
5. Laptop: add `export KUBECONFIG="$HOME/.kube/config:$HOME/.kube/<machine>.yaml"` to the shell
   startup file, then `kubectl config use-context <machine>`. Missing files in the list are skipped.
6. Machine: `sudo k3s etcd-snapshot ls` shows `first` with a `file://` entry under
   `/data/etcd-snapshots`.
7. Nightly VM backup (with the user's OK): add the VM to an existing job, or create one
   (UI *Datacenter → Backup → Add*, or `pvesh create /cluster/backup --schedule 02:30 --vmid <id>
   --storage <storage> --mode snapshot --compress zstd --prune-backups keep-daily=7,keep-weekly=4`),
   then *Run now*.
8. Optional bucket upload: separate bucket + scoped key, `bash infra/k3s/create-etcd-s3-secret.sh`
   (the user enters the values), uncomment `etcd-s3` / `etcd-s3-config-secret`, rerun `install.sh`,
   take a snapshot: both `file://` and `s3://` entries appear.

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
