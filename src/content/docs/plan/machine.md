---
title: Sizing the machine
description: How much CPU, memory and disk you need, and why the data gets its own disk.
---

## Recommended spec

| Resource | Recommended | Minimum | Notes |
|---|---|---|---|
| CPU | 6 vCPU | 4 vCPU | Mostly idle. Bursts during image pulls, builds and backups |
| Memory | 16 GB | 8 GB | The platform takes ~1.5–2 GB. Rolling updates briefly run two copies of an app |
| OS disk | 40 GB | 30 GB | OS and k3s binaries only |
| Data disk | 100 GB | 50 GB | Container images, persistent volumes, logs. **A separate disk** |
| Network | Static IP on your LAN | — | For example `192.168.10.50` |
| OS | Ubuntu Server 24.04 LTS or Debian 13 | — | Any modern systemd distribution works |

### Where these numbers come from
They're based on a real small homelab: an identity provider, a reverse proxy, a Postgres
database, a scheduler and a three-service web app. All of that used about **3 GB of RAM** for
its containers, and CPU sat almost idle. 16 GB leaves room for:
- the platform components (k3s, ArgoCD, cert-manager, External Secrets),
- rolling updates that start the new version before stopping the old one,
- growth.

Measure your own workloads if you're migrating (`docker stats`, `free -m`, `df -h`) and adjust.

## Why a separate data disk

Container images and logs grow until something cleans them up. If they share a disk with the
OS, a full disk can take the whole machine down, including your SSH access. A separate data disk
(mounted at, say, `/var/lib/rancher`) means:
- a full data disk degrades apps, but the OS stays healthy and reachable;
- you can grow, snapshot or replace the data disk on its own.

## Physical machine or VM?

Either works.
- **A VM on a hypervisor** (Proxmox, for example) gives you snapshots before risky changes,
  whole-machine backups, and room to run something else alongside.
- **Bare metal** is simpler, with one less layer.

The rest of the guide doesn't care which. Chapter 1 shows the VM route, with notes for bare metal.

## Before chapter 1, decide

- [ ] Hostname for the machine (for example `lab-1`).
- [ ] Its static IP (for example `192.168.10.50`), reserved on your router.
- [ ] VM or bare metal, and where its backups will go.
