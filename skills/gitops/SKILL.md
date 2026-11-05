---
name: gitops
description: Homelab Guide chapter 3. Use when installing ArgoCD on the homelab k3s cluster with Helm, giving it a read-only GitHub deploy key for the private config repository, bootstrapping the "app of apps" root Application, letting ArgoCD manage its own install, and proving GitOps with a demo app (self-heal, change by commit, removal by commit).
---

# Chapter 3: GitOps

You're helping the user hand their cluster over to git with ArgoCD.

Guide page: `/gitops/argocd/` (or `src/content/docs/gitops/argocd.mdx` in the guide repo).
Reasoning behind the choices: `/start-here/faq/` (chapter 3 section).
Example files: `examples/03-gitops/` (`apps/`, `bootstrap/root.yaml`, `manifests/argocd/values.yaml`,
`manifests/hello/hello.yaml`, `bootstrap/add-repo-key.sh`).

## Ground rules

- **Never ask for, print or handle secret values.** In this chapter those are the **deploy key's
  private half** (only `bootstrap/add-repo-key.sh` touches it, and it never leaves the cluster) and the
  **ArgoCD admin password** (the user copies it to their clipboard and password manager).
- **Installing ArgoCD, applying the root Application, or deleting anything needs the user's
  explicit OK.** Show the exact commands first.
- After the root Application exists, **change the cluster through git only**. A `kubectl` change to
  something ArgoCD manages is reverted by self-heal. Never `helm upgrade` ArgoCD once it manages
  itself (except to recover a broken ArgoCD).
- Pick the ArgoCD version from its "Tested Kubernetes versions" table for the cluster's Kubernetes
  version. The chart version in `helm install --version` and in `apps/argocd.yaml` must match.
- `apps/argocd.yaml` has **no** resources finalizer: deleting it must never delete ArgoCD. Demo and
  real apps do have one, so removing their file removes their resources.

## Ask first

1. The private repository's **SSH** address (`git@github.com:<user>/<repo>.git`), and that `git push`
   works from the laptop.
2. The address ArgoCD will have in chapter 5 (for `global.domain`).
3. That the kubectl context is the right cluster (`kubectl config current-context`).

## Steps

1. Copy `examples/03-gitops/*` to the repo root. Replace `<YOUR_CONFIG_REPO_URL>` in
   `bootstrap/root.yaml`, `apps/argocd.yaml` and `apps/hello.yaml`; set `domain` in
   `manifests/argocd/values.yaml`. Commit and push to `main`.
2. `helm repo add argo https://argoproj.github.io/argo-helm`, `helm repo update argo`, then
   `helm install argocd argo/argo-cd --version <chart> -n argocd --create-namespace -f manifests/argocd/values.yaml`
   and `kubectl -n argocd wait --for=condition=Available deployment --all --timeout=300s`.
3. The user runs `bash bootstrap/add-repo-key.sh <ssh url>` and adds the printed public key on GitHub as a
   deploy key with write access **off**.
4. The user copies the admin password (`kubectl -n argocd get secret argocd-initial-admin-secret -o
   jsonpath='{.data.password}' | base64 -d | pbcopy`) into their password manager. UI:
   `kubectl -n argocd port-forward service/argocd-server 8080:443`, then https://localhost:8080.
5. `kubectl apply -f bootstrap/root.yaml`. `kubectl -n argocd get applications`: `root`, `argocd`,
   `hello` all `Synced` and `Healthy`. A repository error usually means the deploy key is missing
   or was added to another repository.

## Verify

- `kubectl -n hello get pods`: one pod Running.
- Self-heal: `kubectl -n hello scale deployment hello --replicas=3` goes back to 1 within seconds.
- Commit `replicas: 2` in `manifests/hello/hello.yaml` and push (Refresh in the UI to skip the 3-minute
  poll): two pods.
- Delete `apps/hello.yaml` and `manifests/hello/`, push: the `hello` Application and namespace are gone.

## Done when

- [ ] All checks pass, and the demo app is removed.
- [ ] The ArgoCD admin password is in the password manager.
- [ ] `apps/`, `bootstrap/`, `manifests/` are committed. No secrets in the repo.
- [ ] Next chapter: **secrets**.
