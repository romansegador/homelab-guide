---
title: Architecture decisions
description: The big choices behind the platform, and the reasoning, so you can change them knowingly.
---

Before installing anything, decide what you're building. These are the decisions this guide
makes, and why. If your situation differs, the reasoning tells you which ones to revisit.

## The shape

```
                 ┌──────────────────────────── one machine ─────────────────────────────┐
  laptop ──git──▶│  ArgoCD ──syncs──▶ apps (web, API, worker)   Postgres (operator)     │
                 │                     ▲                         │                      │
  secrets        │  External Secrets ──┘                         └─ backups ──▶ off-site │
  manager ──────▶│  cert-manager ──DNS-01──▶ DNS provider API                           │
  (hosted)       │  Ingress (HTTPS) ◀── LAN clients ◀── internal DNS                    │
                 └──────────────────────────────────────────────────────────────────────┘
                              ▲ tunnel (outbound only) for the one public app
```

## Decisions

### 1. One machine, not a simulated cluster
Running three VMs on one physical box *looks* like a cluster but isn't one. If the box or its
disk dies, everything dies together. Replicated storage across VMs on the same disk adds moving
parts (boot ordering, quorum, recovery procedures) without adding safety.

**So:** one machine, sized properly, with real backups off the box. When a second physical
machine arrives, it joins as a worker (see the roadmap extras).

### 2. Kubernetes (k3s) as the first path
k3s is a certified Kubernetes distribution in a single binary. It ships with sensible defaults
(an ingress controller, local storage) and runs comfortably on modest hardware.

**Why Kubernetes on one machine:** the ecosystem. GitOps (ArgoCD), certificate automation
(cert-manager), secret syncing (External Secrets) and database operators are all
Kubernetes-native. You also learn a skill that transfers.

**The honest cost:** more concepts and more YAML than plain Docker. The guide introduces them
one at a time.

### 3. GitOps: the repository is the source of truth
Nothing is changed by hand on the server. You commit, and ArgoCD applies it. That gives you:
- a full history of every change, and a revert button,
- no drift: what runs is what's in git,
- a rebuild that's mostly "point ArgoCD at the repo again".

Use **two repositories**: this guide's example manifests are public, but *your* config repository
should be **private**, because it names your hostnames and structure.

### 4. Secrets live in a secrets manager, off the machine
Secrets don't go in git, not even encrypted, in this path. They live in a hosted secrets manager
(Bitwarden Secrets Manager has a free tier). The External Secrets Operator syncs them into the
cluster as ordinary Kubernetes Secrets.
- Lose the machine, keep the secrets.
- If the secrets manager is briefly unreachable, apps keep running on the last synced copy.
- Exactly **one** secret is created by hand: the access token the operator uses to read the
  others.

A self-hosted manager (OpenBao, Vault) is a fine alternative, but it adds a chicken-and-egg
problem when it runs on the machine it protects. It's covered as an extra.

### 5. HTTPS everywhere, via DNS validation
Internal services get real, trusted Let's Encrypt certificates. Validation uses a DNS record
(DNS-01) created through your DNS provider's API, so nothing needs to be reachable from the
internet. One **wildcard** certificate covers every internal hostname. It's also fewer
certificates to manage, and individual service names don't show up in public certificate
transparency logs.

### 6. Private by default, public by exception
Everything is reachable only from your LAN (or your VPN). The one app you choose to publish goes
out through an **outbound tunnel** with an access policy in front of it. No ports are opened on
your router.

### 7. Backups that leave the building
Two layers:
- machine snapshots (your hypervisor's backup, if you have one), for fast local rollback;
- application-level backups (database dumps, volume backups) pushed **off-site**, for disaster
  recovery.

A backup only counts once you've restored from it. Chapter 10 does exactly that.

## What this guide does not try to do

- **High availability.** One machine is one point of failure. The goal is fast, rehearsed
  recovery.
- **Multi-tenant or enterprise hardening.** Sensible defaults for a homelab, not a compliance
  regime.
