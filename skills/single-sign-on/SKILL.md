---
name: single-sign-on
description: Homelab Guide chapter 11. Use when adding single sign-on to the homelab k3s cluster through the config repository: Authentik as the login provider (CloudNativePG database, blueprint as code, MFA required, akadmin off), a Traefik forward-auth login gate for Headlamp, Prometheus and Alertmanager, OIDC logins for Grafana and ArgoCD, and LAN names plus an OIDC realm for the hypervisor (Proxmox) and a NAS.
---

# Chapter 11: Single sign-on

You're helping the user put one login in front of the tools of a cluster built with chapters 0
to 10. Four pages, in order (each needs the previous ones):
1. **A login provider** (`/single-sign-on/identity-provider/`): Authentik.
2. **A login in front of any tool** (`/single-sign-on/login-gate/`): forward-auth.
3. **Apps that log in with Authentik** (`/single-sign-on/app-logins/`): Grafana, ArgoCD.
4. **Machines outside the cluster** (`/single-sign-on/outside-machines/`): ExternalName names,
   Proxmox OIDC realm.

Reasoning behind the choices: `/start-here/faq/` (chapter 11 section).
Files: `examples/11-single-sign-on/{apps,manifests}/` → the user's config repository. The
blueprint and `apps/authentik.yaml` / `manifests/authentik/secrets.yaml` are split by "Page N"
comments: copy only the parts of the pages done so far.

## Ground rules

- **Never handle secret values.** The user creates these in Bitwarden Secrets Manager (the
  cluster's project) themselves, and pastes the Proxmox one into Proxmox themselves:
  - `authentik-secret-key` (60+ random characters; never changed after the first start);
  - `authentik-oidc-grafana`, `authentik-oidc-argocd`, `authentik-oidc-proxmox` (letters and
    digits only).
  Never print, copy, read back or store them. Don't read a Proxmox realm's config through its API
  or `/etc/pve/domains.cfg` without filtering out `client-key`.
- **Enrolment links are credentials.** `ak create_recovery_key` prints a one-time login link:
  give the user the command; don't run it for them unless they ask, and never store the link.
- **Get explicit approval** before pushing to the config repository (ArgoCD deploys on push),
  changing Traefik's settings (it restarts Traefik), or changing anything on the hypervisor.
- **Order matters:** push a change that reads a new secret only after the user confirms the entry
  exists, or Authentik's new pods can't start. Optionally prove it first with a throwaway
  ExternalSecret, and delete it after.
- Never publish Authentik or any gated tool through the tunnel of chapter 9.

## Ask first

1. Chapters 4, 5, 7 and 10 are done (`bitwarden` store Valid, wildcard cert, CloudNativePG,
   Headlamp + monitoring).
2. Their `lab.<subdomain>`, the config repository's SSH URL, and the usernames for the `admins`
   and `family` groups.
3. For page 4: the hypervisor's and the NAS's DNS names and web UI ports, whether Proxmox has a
   trusted certificate or its self-signed one, and whether an `authentik` realm already exists.

## Steps

### 1. Login provider
1. User creates `authentik-secret-key`.
2. Copy `apps/authentik.yaml`, `apps/authentik-config.yaml`, `manifests/authentik/`. Replace
   `lab.home.example.com`, `<YOUR_CONFIG_REPO_URL>`, `alice`/`bob`. Remove the `AK_OIDC_*` env
   entries, the `authentik-oidc` ExternalSecret, the blueprint from "Page 2" down, and
   `forward-auth.yaml` from the kustomization. `grep -rn "<YOUR_\|example.com"` shows only what
   the user meant to keep. Commit and push (approval).
3. `kubectl -n authentik get cluster,pods` → healthy, server + worker Running (first start: minutes).
4. Worker logs show no blueprint error. User runs
   `kubectl -n authentik exec deploy/authentik-worker -- ak create_recovery_key 60 <username>`,
   sets password + second factor, logs in.

### 2. Login gate
1. Add the blueprint's "Page 2" part, `forward-auth.yaml` (+ kustomization), and the example
   `apps/headlamp.yaml` and `apps/monitoring.yaml` **without** the Grafana `envValueFrom` /
   `grafana.ini` blocks. Commit and push (approval).
2. `curl -s -o /dev/null -w "%{http_code} %{redirect_url}" https://headlamp.lab.<subdomain>/` →
   302 to `auth.lab…`.

### 3. App logins
1. User creates `authentik-oidc-grafana` and `authentik-oidc-argocd`, and confirms.
2. Add the `authentik-oidc` ExternalSecret (grafana, argocd keys), the two `AK_OIDC_*` env entries,
   the blueprint's "Page 3" part, `manifests/monitoring/grafana-oidc.yaml`, the Grafana blocks in
   `apps/monitoring.yaml`, and the example `manifests/argocd/values.yaml`. Commit and push (approval).
3. `kubectl get externalsecret -A | grep oidc` → 3 SecretSynced; each
   `https://auth.lab…/application/o/<app>/.well-known/openid-configuration` returns JSON.

### 4. Machines outside
1. Replace `manifests/https/traefik.yaml` (adds `allowExternalNameServices`), add
   `apps/lan-hosts.yaml` + `manifests/lan-hosts/` with the user's names and ports. Commit and push
   (approval: Traefik restarts once, with surge).
2. `kubectl -n lan-hosts get svc` → ExternalName; `curl` both `.lab` names → 200.
3. User creates `authentik-oidc-proxmox`. Add the `proxmox` key + env entry + blueprint "Page 4"
   part with the user's two redirect URIs. Commit and push (approval).
4. User adds (or modifies) the Proxmox realm with the `read -rsp` command from the page, logs in
   via the authentik realm, and grants their `<user>@authentik` a role as `root@pam`.

## Troubleshooting

- A gated host answers **404 with `x-authentik-id`**: the outpost didn't get the update (seen
  failing on a database deadlock). Re-send it: `ak shell -c "…outpost_send_update.send(<embedded
  outpost pk>)"` (full command on the login-gate page). No restart needed.
- Authentik's new pods in `CreateContainerConfigError`: a secret key they read is missing; check
  `kubectl -n authentik get externalsecret` and the entry names.
- A `.lab` name for an outside machine answers **503**: the Service has no endpoints. If someone
  wrote a selector-less Service + EndpointSlice, ArgoCD skipped the EndpointSlice (excluded by
  default): use ExternalName. Changing an existing ClusterIP Service to ExternalName in place can
  fail: give it a new name.
- ArgoCD logs in but shows nothing / permission denied: no `groups` claim or the user isn't in
  `admins`; `configs.rbac.scopes` must be `"[groups]"`.
- Grafana "login failed" after Authentik: check `role_attribute_path` and that the user is in
  `admins` (`role_attribute_strict` refuses everyone else).
- Proxmox "invalid client": the realm's Client Key differs from the Bitwarden entry, or the
  redirect URI doesn't match exactly the address the user opened.

## Verify

- Authentik login asks for password and second factor; `akadmin` is inactive; blueprint
  *successful*.
- Headlamp, Prometheus, Alertmanager redirect to Authentik and open after login; no token.
- Grafana and ArgoCD log in through Authentik as administrators; local `admin` still works.
- `px.lab…` and `nas.lab…` open; Proxmox logs in through the authentik realm; `root@pam` works.

## Done when

- [ ] The checks of the pages the user did pass, and every file is committed.
- [ ] The user has a way in when Authentik is down: local admins, `root@pam`, `kubectl port-forward`.
