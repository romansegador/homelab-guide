---
name: secrets
description: Homelab Guide chapter 4. Use when connecting the homelab k3s cluster to Bitwarden Secrets Manager with External Secrets Operator (and its Bitwarden SDK server), installing cert-manager for the SDK server's internal certificate, creating the one hand-made bootstrap token, a ClusterSecretStore, and ExternalSecrets that reference secrets by name, all deployed by ArgoCD.
---

# Chapter 4: Secrets

You're helping the user keep every secret in Bitwarden Secrets Manager and sync them into the
cluster with External Secrets, deployed through ArgoCD (chapter 3).

Guide page: `/secrets/external-secrets/` (or `src/content/docs/secrets/external-secrets.mdx`).
Reasoning behind the choices: `/start-here/faq/` (chapter 4 section).
Example files: `examples/04-secrets/` (`apps/cert-manager.yaml`, `apps/external-secrets.yaml`,
`apps/secrets-config.yaml`, `apps/secret-demo.yaml`, `manifests/secrets-config/`,
`manifests/secret-demo/`, `bootstrap/add-bitwarden-token.sh`).

## Ground rules

- **Never ask for, print or handle secret values.** The machine account's **access token** goes
  into the cluster only through `bootstrap/add-bitwarden-token.sh` (hidden prompt), typed by the
  user. Never read a synced Secret's data, except the demo's `demo-message` value when the user asks.
- **Changing the cluster goes through git** (ArgoCD self-heals manual changes). Pushing to the
  config repository, running the token script, or deleting anything needs the user's explicit OK.
- The organization and project ids are **not** secrets and belong in `cluster-secret-store.yaml`.
- The SDK server reads its certificate only at start, so its cert is long-lived (10 years). If it
  is ever reissued, restart `deployment/bitwarden-sdk-server` in `external-secrets`.
- Check each chart version against the project's supported Kubernetes versions (ESO
  "stability-support", cert-manager "supported releases").

## Ask first

1. Whether Bitwarden Secrets Manager is set up: organization, a project for the cluster, a machine
   account with **Can read** on it, and an access token saved in the password manager.
2. The organization id and project id (from the web app's address bar), and whether the account is
   on the US (`bitwarden.com`) or EU (`bitwarden.eu`) cloud.
3. That chapter 3 is done (`kubectl -n argocd get applications` shows `root` Synced).

## Steps

1. The user creates the demo secret `demo-message` in the project.
2. Copy `examples/04-secrets/*` into the repo, merging into the chapter 3 folders.
3. The user runs `bash bootstrap/add-bitwarden-token.sh` (before pushing, so the token is waiting).
4. Replace `<YOUR_CONFIG_REPO_URL>` in `apps/secrets-config.yaml` and `apps/secret-demo.yaml`; set
   `organizationID`, `projectID` (and `.eu` URLs if needed). Commit and push to `main`.
5. Wait for `kubectl -n argocd get applications` (all Synced/Healthy; `secrets-config` and
   `secret-demo` retry until the CRDs exist) and `kubectl get clustersecretstore bitwarden`
   (`Valid`, READY `True`).

## Troubleshooting

- Store not ready: `kubectl describe clustersecretstore bitwarden`. Usual causes: token Secret
  missing or wrong, ids wrong, US/EU URL mismatch, machine account lacks access to the project.
- SDK server pod stuck `ContainerCreating`: the `bitwarden-tls-certs` Secret doesn't exist yet;
  check `kubectl -n external-secrets get certificate`.
- ExternalSecret error "more than one secret": two Bitwarden secrets share the name in the project.

## Verify

- `kubectl -n secret-demo get externalsecret demo` → `SecretSynced`; the Secret's `message` is the
  demo value. Changing it in Bitwarden updates the Secret within a minute.
- Delete `apps/secret-demo.yaml` and `manifests/secret-demo/`, push: namespace `secret-demo` is gone.

## Done when

- [ ] All checks pass, and the demo is removed.
- [ ] The access token is in the password manager. No secret values in the repo.
- [ ] Next chapter: **HTTPS and private DNS** (cert-manager is already installed).
