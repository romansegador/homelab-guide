---
title: Introduction
description: What this guide builds, who it's for, and how it's organised.
---

This guide takes you from an empty machine to a small production platform you can trust with
real apps. It's written while the author builds their own, so every step has been run for real.
Where something went wrong along the way, the guide says so.

## What you'll end up with

- **One machine** (physical or a VM) running a lightweight Kubernetes distribution.
- **GitOps:** every app and every piece of platform config lives in a git repository, and
  [ArgoCD](https://argo-cd.readthedocs.io/) keeps the cluster in sync with it.
- **A secrets manager** outside the machine, synced into the cluster. Secrets never live in git
  in plain text, and they survive losing the machine.
- **Trusted HTTPS for private services**, using Let's Encrypt with DNS validation. Nothing has to
  be reachable from the internet to get a certificate.
- **Private DNS** for your services, plus a clear path to exposing a chosen app publicly
  through a tunnel, without opening ports on your router.
- **A Postgres database** with automated, off-site backups.
- **A real multi-service app** (web front end, API, background worker, database) deployed the same
  way as everything else.
- A **rebuild-from-zero** procedure you've actually tested.

## Who it's for

You're comfortable with a Linux shell, SSH and Docker, and you want to understand what you're
running rather than click through an installer. No prior Kubernetes experience is assumed. The
guide explains each concept the first time it's used.

## How it's organised

- **Chapters** describe *what* you're building and *why*: plan, machine, cluster, GitOps, secrets,
  HTTPS, first app, database, a real app, public exposure, day-2 operations. See the
  [roadmap](/start-here/roadmap/).
- **Paths** are the concrete tools used for a step. The first complete path is
  **k3s + ArgoCD**. The structure leaves room for alternatives (for example Docker Swarm) for the
  same steps later. Path-specific instructions are always clearly labelled.
- **Conventions** for placeholders, commands and secrets are on the
  [conventions](/start-here/conventions/) page. Read it once before you start.

## A word on "production"

"Production" here means: things you depend on, running unattended, recoverable when they break.
It does **not** mean high availability. A single machine is a single point of failure, and the
guide is honest about that. What makes it production-grade is that you can rebuild everything
from git plus your secrets manager plus your backups, and that you've practised doing it.
