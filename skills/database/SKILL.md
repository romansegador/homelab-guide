---
name: database
description: Homelab Guide chapter 7. Use when running Postgres on the homelab k3s cluster with the CloudNativePG operator and the Barman Cloud plugin, backing up continuously (base backups + WAL) to S3-compatible object storage such as Cloudflare R2 with credentials from the secrets manager, and proving it with a restore into a new cluster, all deployed by ArgoCD.
---

# Chapter 7: A database

You're helping the user run Postgres with CloudNativePG, with continuous off-site backups through
the Barman Cloud plugin, deployed by ArgoCD (chapter 3), with the bucket key from the secrets
manager (chapter 4) and cert-manager already installed.

Guide page: `/database/postgres/` (or `src/content/docs/database/postgres.mdx`).
Reasoning behind the choices: `/start-here/faq/` (chapter 7 section).
Example files: `examples/07-database/` (`apps/cloudnative-pg.yaml`, `apps/plugin-barman-cloud.yaml`,
`apps/demo-db.yaml`, `manifests/demo-db/`, `restore/demo-restore.yaml`).

## Ground rules

- **Never ask for, print or handle secret values.** The user creates the bucket's access key and
  stores it in Bitwarden Secrets Manager as `db-backup-access-key-id` and
  `db-backup-secret-access-key`. Never read the `backup-credentials` or `<cluster>-app` Secrets.
- **Database contents may be real data.** Only query the demo database, and only with the user's OK.
  Ask before reading any other database.
- **Changing the cluster goes through git.** Pushing, deleting a Cluster (it deletes the data
  volume), and deleting anything in the bucket need the user's explicit OK.
- A restore always goes into a **new** Cluster with no WAL archiver of its own. Never point a
  second cluster's archiver at an existing cluster's folder.

## Ask first

1. Where backups go: an S3-compatible bucket (the examples use Cloudflare R2), its name, endpoint
   (R2: `https://<account-id>.r2.cloudflarestorage.com`), and a key scoped to that bucket.
2. That chapter 4 is done (`kubectl get clustersecretstore bitwarden` is `Valid`) and cert-manager
   runs (`kubectl -n cert-manager get pods`).

## Steps

1. The user creates the bucket and a bucket-scoped read/write key, and stores the key in Bitwarden.
2. Copy `examples/07-database/*` into the repo. Replace `<YOUR_CONFIG_REPO_URL>` in
   `apps/demo-db.yaml`, and `<YOUR_BACKUP_BUCKET>`, `<YOUR_CLOUDFLARE_ACCOUNT_ID>` in
   `manifests/demo-db/object-store.yaml`. Commit and push.
3. Wait for `kubectl -n argocd get applications` (all Synced/Healthy),
   `kubectl -n demo-db get cluster demo` (`Cluster in healthy state`) and
   `kubectl -n demo-db get backups` (`completed`).

## Troubleshooting

- `demo-db` sync errors about unknown kinds: the operator or plugin isn't installed yet; it retries.
- Backup or archiving fails: `kubectl -n demo-db describe cluster demo` (condition
  `ContinuousArchiving`), `kubectl -n demo-db describe backup <name>`, and the plugin sidecar's logs:
  `kubectl -n demo-db logs demo-1 -c plugin-barman-cloud`. Usual causes: wrong bucket or endpoint,
  key not scoped to that bucket, ExternalSecret not synced
  (`kubectl -n demo-db get externalsecret backup-credentials`).
- `AccessDenied` / "Permission denied when accessing bucket": the key works but isn't allowed on
  that bucket. Check that the bucket name in `object-store.yaml` matches the bucket the token is
  scoped to, that the token has read & write, and (R2) that an EU bucket uses the `.eu.` endpoint.
  WAL archiving retries on its own once fixed. A Backup that already failed stays `failed`: ask the
  user before creating an on-demand Backup.
- Cluster stuck in `Setting up primary`, with Postgres connections hanging in `authentication`:
  check the node's kernel log for `apparmor="DENIED" operation="signal"`. On Ubuntu 26.04 that's
  `kernel.apparmor_restrict_unprivileged_unconfined=1` (the chapter 2 install script turns it off;
  FAQ chapter 2). Fixing it means a sysctl file and a reboot of the machine: get the user's OK.
- Plugin pod not ready: cert-manager missing, or the plugin isn't in the operator's namespace
  (`cnpg-system`).
- Restore cluster stuck: no completed base backup yet, or `serverName` doesn't match the original
  cluster's name.

## Connect a database tool (DBeaver, DbGate…)

- The user runs `kubectl -n <ns> port-forward svc/<cluster>-rw 15432:5432` and connects to
  `localhost:15432`, database and user `app`, SSL off: the tunnel is already encrypted, and an SSL
  session closed by the server (e.g. a wrong password) kills the port-forward (`lost connection to pod`).
- Tables created through `kubectl exec … psql` belong to `postgres` unless you `SET ROLE app;` first;
  `app` then gets `permission denied`. Fix: `ALTER TABLE <t> OWNER TO app;` (user's OK).
- The password is in the Secret `<cluster>-app` (key `password`). The user reads it; you never do.
- Don't expose port 5432 to the network (Traefik TCP, LoadBalancer) unless the user asks for it.

## Verify

- `ContinuousArchiving` is `True`; the bucket has `demo/base/` and `demo/wals/`.
- Insert a row, `SELECT pg_switch_wal();`, copy `restore/demo-restore.yaml` into
  `manifests/demo-db/`, push: `demo-restore` becomes healthy and shows the row. Remove the file again.
- Delete `apps/demo-db.yaml` and `manifests/demo-db/`, push: namespace `demo-db` is gone. The user
  may delete `demo/` in the bucket.

## Done when

- [ ] The restore showed data written after the first backup; the demo is removed.
- [ ] The bucket key is in Bitwarden Secrets Manager only. No secret values in the repo.
- [ ] Next chapter: **a real app** (web, API, worker, database), with automated image updates.
