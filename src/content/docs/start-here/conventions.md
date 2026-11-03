---
title: Conventions
description: Placeholders, command formatting and how secrets are shown in this guide.
---

## Placeholders

The guide never uses anyone's real environment. Replace these with your own values:

| Placeholder | Meaning |
|---|---|
| `example.com` | Your public domain (registered, with DNS at a provider that has an API) |
| `home.example.com` | The private subdomain used for internal services |
| `*.lab.home.example.com` | Hostnames served by the cluster (for example `guide.lab.home.example.com`) |
| `192.168.10.0/24` | Your home LAN |
| `192.168.10.1` | Your router |
| `192.168.10.53` | Your internal DNS server |
| `192.168.10.50` | The cluster machine |
| `<YOUR_GITHUB_USER>` | Your GitHub user or organisation |
| `<YOUR_…>` | Any other value you choose or that's specific to you |

## Commands

- Commands have no prompt characters (`$`), so the copy button gives you exactly what to run.
- Each block's title says **where** to run it:
  - **Laptop**: your own computer.
  - **Proxmox host**: a root shell on the hypervisor (its web UI's *Shell*, or SSH).
  - **The machine**: the VM (or bare-metal server) you create in chapter 1, over SSH.
- Expected output is described in the text, or shown in a separate block, never mixed in with
  the commands.
- Code blocks carry no `#` comments. Pasted into macOS's default shell (zsh), a comment isn't
  ignored and breaks the command. Explanations go in the text.
- Long commands are split with `\`, so you can paste them as they are.
- Every command that changes something is followed by a way to **check** that it worked.

## Secrets

Secret values never appear in this guide, its examples, or your git repositories in plain text.
When a step needs one, the guide shows **where** the value goes and how it's referenced, for
example:

```yaml
# The value lives in the secrets manager under this key, never in git.
remoteRef:
  key: cloudflare-dns-api-token
```

## Versions

Each chapter lists the exact versions it was tested with. Newer versions usually work. Where an
upgrade is known to change behaviour, the chapter says so.
