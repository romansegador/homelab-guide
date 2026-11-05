---
title: Roadmap
description: The chapters of the guide and their status.
---

Each chapter is a milestone that's built for real, then written up. Status is updated as the
build progresses.

| # | Chapter | What you get | Status |
|---|---|---|---|
| 0 | **Plan** | Architecture decisions, machine sizing, DNS and certificate plan | ✅ Written |
| 1 | **The machine** | A VM (or bare metal) with an OS disk and a separate data disk, hardened for SSH | ✅ Tested (OpenTofu path) |
| 2 | **The cluster** | A single-node k3s cluster, `kubectl` and `k9s` on your laptop | ✅ Tested |
| 3 | **GitOps** | A config repository and ArgoCD, bootstrapped with the "app of apps" pattern | ✅ Tested |
| 4 | **Secrets** | An external secrets manager synced into the cluster (Bitwarden Secrets Manager + External Secrets Operator) | ✅ Tested |
| 5 | **HTTPS and private DNS** | cert-manager with DNS-01, a wildcard certificate, ingress, internal DNS records | ✅ Tested |
| 6 | **Your first app** | This guide itself: built by CI, published as an image, deployed by ArgoCD, served over HTTPS | ✅ Tested |
| 7 | **A database** | Postgres managed by an operator, with off-site backups | Planned |
| 8 | **A real app** | A multi-service app (web, API, worker, database) with automated image updates | Planned |
| 9 | **Going public** | Exposing one app to the internet through a tunnel, with an access policy in front | Planned |
| 10 | **Day 2** | Upgrades, backups and restores, monitoring basics, and a full rebuild from zero | Planned |

## Extras under consideration

- **Your own domain from scratch:** buying a domain, moving its DNS to a provider with an API,
  and wiring it into chapter 5.
- **Alternative paths:** for example the same chapters on Docker Swarm.
- **A self-hosted secrets manager** (for example OpenBao) as an alternative to the hosted one
  in chapter 4.
- **A second machine:** adding a worker node, and deciding what can move and what stays pinned.
