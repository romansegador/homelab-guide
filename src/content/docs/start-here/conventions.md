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

- `$` marks a command you run on your **laptop**. `server$` marks one you run **on the
  machine** over SSH.
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
