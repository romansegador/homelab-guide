---
name: real-app
description: Homelab Guide chapter 8. Use when deploying a multi-service app (web, API, worker, Postgres) to the homelab k3s cluster from its own private repository: CI publishing sha-<commit> and version images to GHCR, one Helm chart with staging and prod values in the config repository, a CloudNativePG database per environment, and Argo CD Image Updater committing new staging tags while prod changes only through pull requests.
---

# Chapter 8: A real app

You're helping the user run the guide's sample app ("notes": a static page, a FastAPI API, a worker
that uses Postgres as its queue) in two environments:
- **staging** (`notes-staging`) follows every push to the app's `main`: CI publishes
  `sha-<7 chars>` images, Image Updater commits the newest tag to `charts/notes/values-staging.yaml`,
  ArgoCD deploys it;
- **prod** (`notes-prod`) runs release images (`v0.1.0` → `0.1.0`) and changes only when the user
  merges a pull request that edits `charts/notes/values-prod.yaml`.

Guide pages: `/real-app/build/` and `/real-app/deploy/` (`src/content/docs/real-app/`).
Reasoning behind the choices: `/start-here/faq/` (chapter 8 section).
Files: `examples/08-real-app/app/` → the user's new private `notes` repository;
`examples/08-real-app/{apps,charts,manifests}/` → their config repository.

## Ground rules

- **Never handle secret values.** Two secrets are needed, and the user creates and stores both in
  Bitwarden Secrets Manager (project of the cluster) themselves:
  - `ghcr-pull-token`: a GitHub **classic** token with only `read:packages`;
  - `config-repo-write-key`: the private half of an SSH deploy key with **write** access on the
    config repository.
  Never print, copy, read back or store them. Don't run `ssh-keygen` for the user unless they ask,
  and if they do, never `cat` the private key: `pbcopy < file`, then delete the files.
- **Get explicit approval** before pushing to any repository, pushing a git tag (it publishes
  images), adding a deploy key, merging a pull request, or deleting anything.
- Never put `latest` or a moving tag in a values file. Never point Image Updater at prod.
- The deploy key must not live in the user's password-manager SSH agent: GitHub may then
  authenticate the user as the deploy key, and other repositories fail with `Repository not found`.

## Ask first

1. Chapters 3, 4, 5 and 7 are done (ArgoCD, the `bitwarden` ClusterSecretStore, the wildcard
   certificate, CloudNativePG + Barman Cloud plugin, `db-backup-*` keys in Bitwarden).
2. Their GitHub user or organisation (lowercase in image names), and the app repository's name
   (`notes` gives `notes-api` / `notes-web`; another name means changing the image names in
   `values.yaml` and in the ImageUpdater rule).
3. The config repository's **SSH** URL, their `lab.<subdomain>`, and the chapter 7 bucket and
   Cloudflare account id (and whether the bucket is EU-jurisdiction).

## Steps

1. Create the empty private repository `notes`; copy `examples/08-real-app/app` (with hidden
   files) into it; push `main`. Watch **Images** (`gh run watch`): both packages get `sha-<7>`.
2. Tag `v0.1.0` and push it (approval): packages get `0.1.0`.
3. User creates the classic token and stores `ghcr-pull-token`.
4. User creates the deploy key (write) on the config repository and stores
   `config-repo-write-key`.
5. Copy `apps/`, `charts/notes/`, `manifests/image-updates/` into the config repository. Replace
   `<YOUR_CONFIG_REPO_URL>`, `<YOUR_GITHUB_USER>`, `lab.home.example.com`, `<YOUR_FIRST_SHA_TAG>`,
   `<YOUR_BACKUP_BUCKET>`, `<YOUR_CLOUDFLARE_ACCOUNT_ID>`. `grep -rn "<YOUR_"` prints nothing.
   Validate: `helm lint charts/notes -f charts/notes/values-staging.yaml` (and prod).
   Commit and push (approval).
6. Wait: `kubectl -n argocd get applications` (all Synced/Healthy),
   `kubectl -n notes-staging get pods`, `kubectl -n notes-prod get pods`.

## Troubleshooting

- `ImagePullBackOff`: `kubectl -n notes-staging get externalsecret registry-credentials` must be
  `SecretSynced`; the tag must exist (staging's first tag is set by hand); owner lowercase; the token
  must be classic with `read:packages`.
- API/worker restarting at first: the database isn't ready yet (`kubectl -n notes-staging get
  cluster`). They recover on their own.
- Image Updater does nothing: `kubectl -n argocd logs deploy/argocd-image-updater-controller`.
  `images_considered=0` → the Application name doesn't match `namePattern`; registry errors → the
  `registry-credentials` Secret in `argocd`; git errors → `git-creds` (key without write access,
  HTTPS URL instead of SSH, or the key pasted without its line breaks).
- Image Updater commits but nothing changes: the `writeBackTarget` path must be
  `helmvalues:/charts/notes/values-staging.yaml` (leading `/` = repository root).
- Prod has no backups: `kubectl -n notes-prod get backups`, `kubectl -n notes-prod describe
  objectstore notes-prod-offsite`; the endpoint needs `.eu.` for an EU bucket.

## Verify

- Both sites load; a note goes `[pending]` → `[done, N words]`; the footer shows the version
  (`sha-…` in staging, `0.1.0` in prod).
- Push a visible change to the app's `main`: within minutes a commit by `argocd-image-updater`
  changes `values-staging.yaml`, and staging shows it. Prod doesn't change.
- Tag `v0.2.0`, then a pull request changing `values-prod.yaml` to `0.2.0`; after merge prod shows
  `0.2.0`. Revert it with GitHub's **Revert** button (another pull request).
- `kubectl -n notes-prod get backups` shows a completed backup; `ContinuousArchiving` is `True`.

## Done when

- [ ] All checks pass; staging updated itself and prod changed only through a pull request.
- [ ] Next chapter: **going public** (one app reachable from the internet through a tunnel).
