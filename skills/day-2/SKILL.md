---
name: day-2
description: Homelab Guide chapter 10 (in progress). Use when adding day-to-day operation tools to the homelab k3s cluster through the config repository: Headlamp as the cluster's web UI with short-lived tokens, a Kubernetes CronJob in the notes app's chart that calls the API on a timetable, and kube-prometheus-stack (Prometheus, Alertmanager to a chat webhook, Grafana) with secrets from Bitwarden Secrets Manager.
---

# Chapter 10: Day 2

You're helping the user add three things to a cluster built with chapters 0 to 9. Each is its own
page and can be done alone:
- **A web page for the cluster** (`/day-2/cluster-ui/`): Headlamp.
- **A scheduled job** (`/day-2/scheduled-jobs/`): a CronJob in `charts/notes`.
- **Monitoring and alerts** (`/day-2/monitoring/`): kube-prometheus-stack.

Not written yet (don't improvise them as if they were the guide): upgrades, backups and restores,
and a full rebuild.

Reasoning behind the choices: `/start-here/faq/` (chapter 10 section).
Files: `examples/10-day-2/{apps,manifests}/` and
`examples/08-real-app/charts/notes/templates/schedule.yaml` → the user's config repository.

## Ground rules

- **Never handle secret values.** The user creates and stores these in Bitwarden Secrets Manager
  (the cluster's project) themselves:
  - `alertmanager-slack-webhook`: the chat channel's incoming-webhook URL;
  - `grafana-admin-password`: a password they choose.
  Never print, copy, read back or store them. A Headlamp token is a cluster-administrator
  credential for as long as it lasts: don't create one for the user, and never ask them to paste
  one to you; give them the command.
- **Get explicit approval** before pushing to the config repository (ArgoCD deploys on push),
  starting a job by hand in prod, sending a test alert (it posts in their channel), or deleting
  anything.
- Never publish Headlamp, Prometheus or Alertmanager through the tunnel of chapter 9.

## Ask first

1. Chapters 3, 4 and 5 are done (ArgoCD, the `bitwarden` ClusterSecretStore, the wildcard
   certificate). The scheduled job also needs chapter 8 (notes staging and prod).
2. Their `lab.<subdomain>` and the config repository's SSH URL.
3. For monitoring: which chat service. The example is Slack; another one means changing the
   `receivers` block in `apps/monitoring.yaml`. And their time zone, for the job's timetable.

## Steps

### Cluster web page
1. Copy `examples/10-day-2/apps/headlamp.yaml` to `apps/`; replace `lab.home.example.com`.
   Commit and push (approval).
2. `kubectl -n argocd get application headlamp` → Synced/Healthy; `kubectl -n headlamp get pods`.
3. The user runs `kubectl -n headlamp create token headlamp --duration=24h` and pastes the token
   at `https://headlamp.lab.<subdomain>`.

### Scheduled job
1. If their chart predates this page: copy `templates/schedule.yaml` and the `schedule:` block of
   `values.yaml` from `examples/08-real-app/charts/notes`.
2. `values-prod.yaml`: `schedule: {enabled: true, timeZone: <theirs>}`. `values-staging.yaml`:
   `schedule: {enabled: true, suspend: true}`.
3. Validate: `helm lint charts/notes -f charts/notes/values-prod.yaml` (and staging). Commit and
   push (approval).
4. `kubectl -n notes-prod get cronjob` → `nightly-note`, `SUSPEND False`; staging `True`.

### Monitoring
1. The user creates the channel and webhook, and stores both secrets.
2. Copy `apps/monitoring.yaml`, `apps/monitoring-config.yaml`, `manifests/monitoring/`. Replace
   `lab.home.example.com` and `<YOUR_CONFIG_REPO_URL>`. `grep -rn "<YOUR_"` prints nothing.
   Commit and push (approval).
3. `kubectl -n argocd get application monitoring monitoring-config` → Synced/Healthy (first sync
   takes a couple of minutes); `kubectl -n monitoring get externalsecret` → both `SecretSynced`;
   `kubectl -n monitoring get pods` → six Running.

## Troubleshooting

- Alertmanager or Grafana pod stuck in `ContainerCreating`: its Secret doesn't exist yet. Check
  `kubectl -n monitoring get externalsecret`; the Bitwarden entry names must match exactly.
- `monitoring-config` fails on `PrometheusRule`: the kind arrives with the `monitoring` app. It
  retries by itself; wait for `monitoring` to be Healthy.
- `monitoring` stuck OutOfSync on CRDs: the Application needs `ServerSideApply=true` (it's in the
  example).
- Alerts named `...Down` for etcd, scheduler, controller manager or kube-proxy: the four
  `enabled: false` lines at the top of the values are missing.
- No message in the channel: `kubectl -n monitoring logs
  alertmanager-monitoring-kube-prometheus-alertmanager-0 -c alertmanager` shows the error from the
  chat service; the stored value must be the whole webhook URL, with no line break.
- A manual job run fails with `add note: HTTP 000`: nothing answered at `http://api`. The app is
  asleep (the job can't wake it) or the API pod isn't ready.
- `KubeJobFailed` keeps repeating: it fires while a failed Job exists. Delete the Job once the
  cause is understood.

## Verify

- Headlamp accepts the token and lists the pods of every namespace.
- `kubectl -n notes-prod create job --from=cronjob/nightly-note nightly-note-manual-1` (approval)
  → Job `Complete`, log `add note: HTTP 201`, a "Nightly check" note in the app.
- Test alert (approval): `kubectl -n monitoring exec
  alertmanager-monitoring-kube-prometheus-alertmanager-0 -c alertmanager -- amtool alert add
  TestAlert severity=info --annotation=summary=test --alertmanager.url=http://localhost:9093` →
  a `[FIRING:1] TestAlert` message, then `[RESOLVED]` a few minutes later.
- Grafana opens as `admin` and shows *Node Exporter / Nodes*.

## Done when

- [ ] The checks of the pages the user chose pass, and every file is committed in the config
      repository.
- [ ] Still to come in this chapter: upgrades, backups and restores, a full rebuild.
