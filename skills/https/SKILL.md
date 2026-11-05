---
name: https
description: Homelab Guide chapter 5. Use when giving the homelab k3s cluster's apps private DNS names and trusted HTTPS, with one wildcard internal DNS record, cert-manager and Let's Encrypt DNS-01 (Cloudflare token from the secrets manager), one wildcard certificate as k3s Traefik's default (HelmChartConfig), and standard Ingresses, all deployed by ArgoCD.
---

# Chapter 5: HTTPS and private DNS

You're helping the user give every app in the cluster a private name under one subdomain (for
example `*.lab.home.example.com`) with a trusted Let's Encrypt wildcard certificate, deployed
through ArgoCD (chapter 3), with the DNS token from the secrets manager (chapter 4).

Guide page: `/https/certificates-and-dns/` (or `src/content/docs/https/certificates-and-dns.mdx`).
Reasoning behind the choices: `/start-here/faq/` (chapter 5 section).
Example files: `examples/05-https/` (`apps/cert-manager.yaml` and `manifests/argocd/values.yaml`
replace chapter 4's and chapter 3's; `apps/https.yaml`, `manifests/https/`, and the `hello` demo).

## Ground rules

- **Never ask for, print or handle secret values.** The user creates the DNS provider's API token
  and stores it in Bitwarden Secrets Manager as `cloudflare-dns-api-token`. Never read the synced
  Secret's data, or the certificate's private key.
- **Changing the cluster goes through git.** Pushing to the config repository, editing the
  internal DNS server, or deleting anything needs the user's explicit OK.
- The internal DNS server usually serves other things too (often production). Propose the exact
  record change and how to reload, and wait for approval before touching it. Back up the zone first.
- Use Let's Encrypt **staging** until the certificate is Ready. The real service allows five
  identical certificates a week.

## Ask first

1. The private subdomain (for example `lab.home.example.com`) and the cluster machine's LAN IP.
2. Which internal DNS server they use (bind9, AdGuard Home, Pi-hole, router…), and whether it
   answers for the parent domain itself (then the `extraArgs` in `apps/cert-manager.yaml` are
   required, see FAQ).
3. The DNS provider. The examples use Cloudflare; another provider needs a different `dns01`
   solver in `manifests/https/cluster-issuers.yaml` (cert-manager DNS01 docs).
4. That chapter 4 is done (`kubectl get clustersecretstore bitwarden` is `Valid`).

## Steps

1. The user creates a DNS API token (Cloudflare: Zone·DNS·Edit + Zone·Zone·Read, one zone) and
   adds it to the cluster's Bitwarden project as `cloudflare-dns-api-token`.
2. Add one wildcard record: `*.<subdomain>` → the cluster's IP. Check with
   `dig +short anything.<subdomain>`.
3. Copy `examples/05-https/*` into the repo. Replace `<YOUR_CONFIG_REPO_URL>` in `apps/https.yaml`
   and `apps/hello.yaml`; replace `lab.home.example.com` in `wildcard-certificate.yaml`, the ArgoCD
   values and `hello.yaml`. Commit and push.
4. Wait for `kubectl -n argocd get applications` (all Synced/Healthy) and
   `kubectl -n kube-system get certificate wildcard` (READY True, staging).
5. Change the certificate's `issuerRef.name` to `letsencrypt`, push; wait for READY True again.

## Troubleshooting

- Certificate stuck: `kubectl -n kube-system describe certificate wildcard`, then
  `kubectl get challenges -A` and `kubectl describe challenge -A`.
  - "propagation check failed" for a long time: cert-manager is asking the internal DNS; check the
    `extraArgs` reached the pod (`kubectl -n cert-manager get deploy cert-manager -o yaml`).
  - Cloudflare auth errors: token missing (`kubectl -n cert-manager get externalsecret`), wrong
    permissions, or wrong zone.
- Browser shows Traefik's default certificate: `wildcard-tls` doesn't exist yet in `kube-system`,
  or the HelmChartConfig hasn't been applied (`kubectl -n kube-system get helmchartconfig traefik`;
  k3s's helm job reinstalls Traefik, `kubectl -n kube-system get pods`).
- `404 page not found` from Traefik: no Ingress claims that name (check `kubectl get ingress -A`).
- ArgoCD UI redirect loop: `server.insecure: true` missing from the ArgoCD values.

## Verify

- `curl -sS -o /dev/null -w '%{http_code}\n' https://hello.<subdomain>` → `200` (no `-k`).
- `curl -sI http://hello.<subdomain>` → permanent redirect to `https://`.
- `https://argocd.<subdomain>` opens with no browser warning.
- Delete `apps/hello.yaml` and `manifests/hello/`, push: the name answers `404 page not found`.

## Done when

- [ ] All checks pass with the real Let's Encrypt certificate, and the demo is removed.
- [ ] The DNS token is in Bitwarden Secrets Manager only. No secret values in the repo.
