---
name: going-public
description: Homelab Guide chapter 9. Use when publishing one homelab k3s app on the internet through a Cloudflare Tunnel (cloudflared in the cluster, outbound only) with Cloudflare Access (email one-time PIN allowlist) in front, the tunnel, routes, DNS and Access managed by OpenTofu, traffic going to Traefik over verified HTTPS, all on Cloudflare's free plan.
---

# Chapter 9: Going public

You're helping the user publish the notes app's prod at `https://notes.<domain>`:
Cloudflare Access (one-time PIN to allowed emails) → the `lab-1` tunnel → cloudflared (2 pods in
k3s) → Traefik over HTTPS (Let's Encrypt cert for the public name, checked via
`origin_server_name`) → the app's public Ingress (`publicHost` in the notes chart).

Guide page: `/going-public/tunnel/` (`src/content/docs/going-public/tunnel.mdx`).
Reasoning: `/start-here/faq/` (chapter 9). Files: `examples/09-going-public/`
(`infra/cloudflare/`, `apps/cloudflared.yaml`, `manifests/cloudflared/`); the notes chart's
`templates/public.yaml` is in `examples/08-real-app/charts/notes/`.

## Ground rules

- **Free plan only, under the free limits.** Before every create, state the limit and the count:
  1,000 tunnels, 500 Access apps, 500 reusable policies, 50 Access seats (per person, shared by all
  apps), DNS records free. Never enable a paid feature (extra rate-limiting rules, load balancing,
  longer log retention, Argo Smart Routing).
- **Never handle secret values.** The user creates the Cloudflare API token and enters it through
  `source ./load-secrets.sh` (with the state bucket keys and passphrase). The tunnel token goes
  `tofu output -raw tunnel_token | pbcopy` → secrets manager as `cloudflare-tunnel-token`. Never
  print, read back or store either; never run `tofu output` without `-raw … | pbcopy`.
- **Get explicit approval** before `tofu apply`, pushing to the config repository, or merging.
  Review the `tofu plan` with the user resource by resource, with the free-plan check for each.
- Don't touch Cloudflare resources OpenTofu didn't create (other tunnels, Access apps, records).

## Ask first

1. Chapters 1, 5 and 8 done: tofu state bucket + passphrase, DNS on Cloudflare + the `letsencrypt`
   ClusterIssuer, notes prod running.
2. Do they have a Zero Trust organisation (team name) and the One-time PIN login method? (Create:
   Zero Trust → plan Free; may ask for a payment method, not charged.)
3. Account id, zone id, domain, and who may log in (emails = seats).

## Steps

1. User creates the API token: Account Cloudflare Tunnel Edit, Account Access: Apps and Policies
   Edit, Zone DNS Edit (specific zone).
2. Copy `examples/09-going-public` into the config repository. In `infra/cloudflare/`: copy
   `backend.hcl` from `infra/proxmox/`, `terraform.tfvars` from the example. Replace
   `<YOUR_CONFIG_REPO_URL>` in `apps/cloudflared.yaml`. Don't push yet.
3. User runs `source ./load-secrets.sh`, `tofu init -backend-config=backend.hcl`, `tofu plan`.
   Expect 5 to add (tunnel, tunnel config, DNS record, Access policy, Access app) and a warning that
   the tunnel config can't be destroyed by the provider (harmless). Then `tofu apply` (approval).
4. User stores the tunnel token as `cloudflare-tunnel-token`. Commit `infra/cloudflare/` with
   `.terraform.lock.hcl` (never `*.tfstate`).
5. `publicHost: notes.<domain>` in `charts/notes/values-prod.yaml`; commit and push with
   `apps/cloudflared.yaml` and `manifests/cloudflared/` (approval).

## Troubleshooting

- cloudflared `CrashLoopBackOff` / auth errors: `kubectl -n cloudflared get externalsecret
  tunnel-token` must be `SecretSynced`; the stored value must be the whole token.
- Public URL shows Cloudflare error 1033: no connector is running (check the pods).
- Error 502 after login: cloudflared can't reach Traefik or the TLS check fails. `kubectl -n
  notes-prod get certificate notes-public` must be Ready; test with
  `curl --resolve notes.<domain>:443:<machine IP> https://notes.<domain>/` → `200 0`.
- Login page offers no PIN: add the One-time PIN login method in Zero Trust.
- `tofu apply` fails on the DNS record: a record with that name already exists; ask the user
  before removing or importing it.

## Verify

- From outside the LAN, `https://notes.<domain>` redirects to `<team>.cloudflareaccess.com`; after
  the PIN, the app loads. Another email gets no code.
- `kubectl -n cloudflared logs deployment/cloudflared` shows `Registered tunnel connection` and the
  config with the hostname; the dashboard shows the tunnel Healthy with 2 connectors.

## Done when

- [ ] All checks pass; the free-plan budget is unchanged except the counted items.
- [ ] Next chapter: **day 2** (upgrades, backups and restores, monitoring, full rebuild).
