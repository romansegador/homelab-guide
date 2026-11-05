---
name: first-app
description: Homelab Guide chapter 6. Use when building a static site (the guide itself) into a container image with GitHub Actions, publishing it to GitHub Container Registry on a version tag, and deploying it to the homelab k3s cluster with ArgoCD (plain Deployment, Service and Ingress), then releasing and rolling back by commit.
---

# Chapter 6: Your first app

You're helping the user ship their first app through the whole path: a version tag in git → CI
builds and publishes an image to `ghcr.io` → a one-line commit in the config repository → ArgoCD
deploys it at `https://guide.<subdomain>` (chapter 5's wildcard DNS and certificate).

Guide page: `/first-app/publish-and-deploy/` (or `src/content/docs/first-app/publish-and-deploy.mdx`).
Reasoning behind the choices: `/start-here/faq/` (chapter 6 section).
Files: in the guide repository's root, `Dockerfile`, `nginx.conf`, `.github/workflows/image.yml`;
for the config repository, `examples/06-first-app/` (`apps/guide.yaml`, `manifests/guide/guide.yaml`).

## Ground rules

- **Never handle secret values.** Nothing in this chapter needs one: the workflow uses its own
  `GITHUB_TOKEN`, and the image is public.
- **Publishing is outward-facing.** Pushing a version tag publishes an image, and changing package
  visibility makes it public. Get the user's explicit OK for each. Pushing to the config repository
  or deleting anything needs it too.
- Never deploy `latest` or a moving tag: the config repository names an exact version.
- Don't change the workflow's permissions beyond what it has (`contents: read`, `packages: write`,
  `id-token: write`, `attestations: write`).

## Ask first

1. Whether they forked the guide (and enabled Actions in the fork), or use their own static site
   (then adapt the `Dockerfile`'s build stage).
2. Their GitHub user or organisation (the image is `ghcr.io/<owner>/homelab-guide`, lowercase).
3. That chapter 5 is done (an app answers on `https://<name>.<subdomain>`).

## Steps

1. Push tag `v0.1.0` in the app repository; watch the **Image** workflow (`gh run watch`).
2. The user makes the package public (Package settings → Change visibility). Check:
   `curl -s "https://ghcr.io/token?scope=repository:<owner>/homelab-guide:pull"` prints a token.
3. Copy `examples/06-first-app/*` into the config repository; replace `<YOUR_CONFIG_REPO_URL>`,
   `<YOUR_GITHUB_USER>` and `lab.home.example.com`. Commit and push.
4. Wait for `kubectl -n guide get pods` (Running) and
   `curl -sS -o /dev/null -w '%{http_code}\n' https://guide.<subdomain>` (`200`).

## Troubleshooting

- Pod `ImagePullBackOff`: the package is still private, the tag doesn't exist (the image tag has no
  `v`), or the owner has uppercase letters (image names are lowercase).
- Workflow didn't run on the tag: Actions not enabled in the fork, or the tag doesn't start with `v`.
- Pod `CrashLoopBackOff`: `kubectl -n guide logs deploy/guide`. nginx needs `/tmp` writable (the
  `emptyDir` in the Deployment).
- A page loses `https://` on redirect: `absolute_redirect off;` missing from `nginx.conf`.

## Verify

- Release `v0.1.1`, bump the tag in `manifests/guide/guide.yaml`, push: the deployment's image is
  `…:0.1.1` and the page shows the change.
- `git revert` that commit, push: back to `…:0.1.0`.
- `gh attestation verify oci://ghcr.io/<owner>/homelab-guide:0.1.0 --owner <owner>` succeeds.

## Done when

- [ ] All checks pass; the guide runs the intended version.
- [ ] Next chapter: **a database** (Postgres with an operator and off-site backups).
