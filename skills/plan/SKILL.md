---
name: plan
description: Homelab Guide chapter 0. Use when someone is planning a single-machine homelab (one server or VM, Kubernetes/k3s or similar, GitOps, HTTPS for private hostnames) and needs to decide machine sizing, hostnames, IPs, domain, private subdomain and DNS setup before building anything.
---

# Chapter 0: Plan

You're helping the user make the decisions that every later chapter depends on. Nothing is
installed or changed in this chapter. The output is a short **decisions file** that the user keeps.

Guide pages for this chapter (read them if you can fetch URLs; otherwise follow this skill):
`/plan/architecture/`, `/plan/machine/`, `/plan/dns-and-certificates/` on the guide site, or
the matching files under `src/content/docs/plan/` in the guide repository.

## Ground rules

- **Never ask for secret values** (API tokens, passwords, private keys). Only ask *where* the user
  will keep them. Secrets are entered by the user, directly into the tool that needs them.
- The decisions file must contain **no secrets**. It may contain hostnames and private IPs. Remind
  the user to keep it out of public repositories.
- Explain each choice briefly and give a recommendation. The user decides.

## Ask, one topic at a time

1. **Workloads.** What will run here (apps, databases, how many users)? If they're migrating,
   ask for current usage (`docker stats --no-stream`, `free -m`, `df -h`) and size from that.
2. **Machine.** VM on a hypervisor (which one?) or bare metal. Recommend 6 vCPU / 16 GB RAM, a
   40 GB OS disk plus a **separate** ~100 GB data disk. Minimum 4 vCPU / 8 GB / 30 + 50 GB.
3. **Network.** LAN subnet, gateway, a free static IP for the machine (reserved on the router),
   the machine's hostname.
4. **Domain and DNS provider.** A registered public domain at a DNS provider with an API (for
   DNS-01 certificates). If they have none, note that the guide's "own domain from scratch" extra
   covers buying one.
5. **Private subdomain.** One subdomain for everything the cluster serves (for example
   `lab.home.example.com`). Recommend naming services after what they are, not where they run.
6. **Internal DNS.** What resolves names on their LAN (router, Pi-hole, bind9, AdGuard…), its IP,
   and whether it supports wildcard records.
7. **Backups.** Where machine backups go (hypervisor backup target) and where off-site backups
   will go later (an S3-compatible bucket, a storage box…).

## Output

Write `homelab-decisions.md` in a location the user chooses:

```markdown
# Homelab decisions
- Machine: <VM on Proxmox node X | bare metal>, <cpu> vCPU, <ram> GB, OS disk <n> GB, data disk <n> GB
- OS: <Ubuntu Server 24.04 LTS | Debian 13>
- Hostname: <name>   IP: <ip/cidr>   Gateway: <ip>   LAN DNS: <ip>
- Domain: <example.com> at <DNS provider>
- Private subdomain: <lab.home.example.com>   Wildcard record: *.<sub> -> <machine ip>
- Internal DNS server: <what>, supports wildcards: <yes/no>
- Backups: machine -> <target>; off-site -> <later/target>
- Secrets will be kept in: <password manager / secrets manager> (values NOT in this file)
```

## Done when

- [ ] Every line of the decisions file is filled in, or explicitly marked "later".
- [ ] The user confirms the file. Then suggest the next chapter: **machine**.
