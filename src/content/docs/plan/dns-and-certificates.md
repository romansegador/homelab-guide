---
title: DNS and certificates plan
description: How private hostnames get trusted HTTPS certificates without being exposed to the internet.
---

## The idea in one paragraph

You own a public domain (`example.com`) whose DNS is hosted by a provider with an API. Your
services use **private** hostnames under it (`*.lab.home.example.com`), which only your internal
DNS server resolves, to your machine's LAN IP. To prove to Let's Encrypt that you control those
names, cert-manager briefly creates a TXT record in the **public** zone through the provider's
API (the DNS-01 challenge). Let's Encrypt never connects to your network.

## What you need

| Item | Example | Why |
|---|---|---|
| A registered domain | `example.com` | Let's Encrypt only issues for real, public domains |
| DNS hosted at a provider with an API | Cloudflare, among many others | cert-manager creates the challenge record automatically |
| An API token limited to DNS edits on that zone | stored in the secrets manager | Least privilege: it can't touch anything else |
| An internal DNS server | your router, Pi-hole, bind9, AdGuard… at `192.168.10.53` | Resolves private hostnames on your LAN |

## Naming plan

- Pick one **private subdomain** for everything the cluster serves, for example
  `lab.home.example.com`.
- Add **one wildcard record** in your internal DNS: `*.lab.home.example.com → 192.168.10.50`.
- Request **one wildcard certificate** for `*.lab.home.example.com`.

New services then need no DNS change and no new certificate. You just pick a name under the wildcard.

:::tip[Avoid host names in service URLs]
Name services after **what they are** (`guide.lab.home.example.com`), not **where they run**
(`app.server-2.home.example.com`). Then moving a service to another machine doesn't break
bookmarks, single sign-on redirect URLs or certificates.
:::

## Split-horizon, briefly

The private names exist **only** in your internal DNS. Public DNS knows nothing about them,
except for the short-lived challenge TXT records. If you later publish one app, it gets a
**public** name (for example `app.example.com`) served through a tunnel. That's chapter 9.

## Optional: start with a brand-new domain

If you don't have a domain yet, or want a clean one for the lab, an extra chapter will cover:
buying one, pointing its nameservers at a DNS provider with an API, creating the scoped API
token, and checking that everything works before chapter 5.

## Before chapter 1, decide

- [ ] Your domain and DNS provider.
- [ ] The private subdomain (for example `lab.home.example.com`).
- [ ] Where your internal DNS runs, and whether it supports wildcard records.
