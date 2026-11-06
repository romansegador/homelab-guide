---
title: FAQ
description: Why the guide chose each tool and approach, the alternatives it considered, and when you might pick differently.
---

Every chapter makes choices: one tool over another, or one way of doing something. This page
keeps the reasoning, the alternatives that were considered, and when you might choose
differently. The big architectural decisions are in
[Architecture decisions](/plan/architecture/).

## General

### Why one machine instead of several VMs?
Several VMs on one physical box look like a cluster but fail together. See
[decision 1](/plan/architecture/#1-one-machine-not-a-simulated-cluster).

### Can I follow the guide with Terraform, Ansible or Docker Swarm instead?
The chapters describe *what* you build. Tool-specific steps are in labelled tabs. Where a common
alternative works with the same files, the chapter says so. Terraform is one example. Other paths
(for example Docker Swarm) are listed as extras on the [roadmap](/start-here/roadmap/).

## Chapter 1 · The machine

### Which Ubuntu image, and why 26.04?
The **Ubuntu Server cloud image**: Ubuntu Server already installed on a disk, with no desktop,
built for VMs that are configured by cloud-init. It's what cloud providers boot. The even smaller
*minimal* cloud images exist, but they drop tools you'll want when something goes wrong.

**26.04 LTS** because, for a new machine, the newest LTS gives the longest support (standard
security updates until 2031, versus 2029 for 24.04). Waiting for the first point release (26.04.1)
lets early bugs get fixed. k3s lists 26.04 as a supported OS. Pick 24.04 instead if software you
depend on doesn't support 26.04 yet.

The example **pins a dated build** (`release-YYYYMMDD`) with its SHA-256, instead of the moving
`current` link. Then the image only changes when you change it, and Proxmox verifies the download.
Security updates still arrive: cloud-init upgrades all packages on first boot, and unattended
upgrades keep doing it.

### Why OpenTofu and not Terraform?
They're nearly the same tool. In August 2023 HashiCorp moved Terraform from an open-source licence
(MPL) to a "source-available" one (the Business Source License). The community forked the last
open version as **OpenTofu**, which the Linux Foundation now hosts. IBM has since bought HashiCorp.

- **For a homelab, both are free to use.** The BSL restricts companies that build competing
  products, not you.
- **The guide's examples work with both.** Same language, same providers. Replace `tofu` with
  `terraform`.
- **Why the guide picks OpenTofu:**
  - **Open source.** An open-source guide shouldn't depend on a licence its owner can change again.
  - **State encryption.** OpenTofu can encrypt its state file itself, and Terraform can't (see
    below). The state describes your infrastructure, and in this guide it's stored outside your
    network.
- **When to pick Terraform instead:** your team or employer already uses it, or you want its
  hosted service (HCP Terraform). There are more tutorials and answers online for Terraform, and
  most of them apply to OpenTofu as-is.

### Why does OpenTofu need SSH to Proxmox if it uses the API?
OpenTofu runs on your laptop and does almost everything through the Proxmox API over HTTPS:
creating the VM, its disks, the image download. The one exception is the **cloud-init file**.
Proxmox stores custom cloud-init files as "snippets", and its API has no way to upload a snippet.
So the provider copies that single file over SSH.

### Why a restricted SSH user instead of root?
Root SSH into the hypervisor means a stolen laptop key, or a compromised CI job, owns every VM on
the host. The guide's `tofu` user may run exactly two commands as root: a version check
(`pvesm apiinfo`), and `tee` into the snippets folder with a strict file-name pattern. It's one
extra setup step and removes the need for root SSH entirely.

Alternatives considered:

| Option | Why not (here) |
|---|---|
| **Root SSH** | Simplest, but gives OpenTofu and anything that runs it full control of the host. |
| **No snippet, API only.** Use Proxmox's built-in cloud-init fields: user, key, IP, DNS. | Those fields can't install packages, harden SSH, or format the data disk. That work would move to a second step and a second tool. |
| **Copy the snippet by hand once** | No SSH from OpenTofu, but a manual step every time the file changes, so the repository stops being the whole story. |

### Can I run OpenTofu from CI instead of my laptop?
Yes. Nothing in the setup is tied to your laptop: the state is remote, and the secrets are
environment variables. Two things to solve first:
- **Network.** A cloud-hosted runner (for example GitHub's) can't reach a Proxmox host on your home
  network. You'd need a self-hosted runner at home, or a VPN.
- **Secrets.** The four values (API token, bucket keys, passphrase) become CI secrets.

For one machine that's created once and rarely changed, the guide runs OpenTofu from the laptop.
Ongoing automation happens inside the cluster with GitOps, from chapter 3.

### Where is the OpenTofu state, and why remote and encrypted?
The **state** is OpenTofu's record of what it created: "this VM, with this id, is mine". Lose it
and OpenTofu thinks nothing exists. The next `apply` tries to create a second VM, and recovering
means importing everything back by hand. So the state should outlive your laptop.

| Option | Verdict |
|---|---|
| **Local file on the laptop** | Lost with the laptop, and no one else, including CI, can use it. |
| **Committed to the private git repository (encrypted)** | No extra service, and you get history. But there's no locking, and you must remember to commit after every `apply`. Workable for one person. |
| **A bucket on the homelab** (MinIO, Garage) | Chicken and egg: the state of the machine would live on that machine. |
| **Cloudflare R2 (or any S3-compatible storage), encrypted** ✅ | Off-site, free at this size, and it has locking, so two runs can't clash. |

It's **encrypted by OpenTofu before upload** (AES-GCM, with a key derived from your passphrase).
The storage provider only ever holds ciphertext, and a leaked bucket key reveals nothing. The cost
is one more secret to keep: the passphrase.

The guide uses R2 because a Cloudflare account is already part of the plan (DNS in chapter 5, the
tunnel in chapter 9). Any S3-compatible bucket works the same way.

### Why cloud-init instead of Ansible for the OS setup?
The machine is configured **once, at first boot**, from a single file that lives next to the VM
definition. That keeps chapter 1 to one tool and one command. Everything that runs on the machine
afterwards is managed by the cluster and GitOps. Ansible shines when you configure many machines
repeatedly over their lifetime. With one machine that you'd rather rebuild than patch by hand, it
would be a second tool for little gain.

## Chapter 2 · The cluster

### Why k3s?
It's a full, certified Kubernetes in a single program. It installs in a minute, a fresh cluster
idles at about 1 GB of RAM (1.2 GB for the whole machine, OS included), and includes what a one-machine cluster needs (ingress, a load balancer,
volumes). What you learn transfers to any Kubernetes. Alternatives: **k0s** and **MicroK8s**
(similar idea), **Talos** (an immutable OS that is only Kubernetes: great, but more to learn at
once), or full **kubeadm** (more parts to run yourself).

### Why install it with a script and a config file, not cloud-init or a tool like k3sup?
The config file is the source of truth, and it lives in your repository. The install is one
short script, run from your laptop over SSH, that you can read, rerun and debug. It wraps the
official k3s install script, and does by hand-sized steps what k3sup does. Baking k3s into cloud-init would rebuild the
cluster automatically with the VM, but a failure would be hidden inside a first boot, and it
mixes "the machine" with "the cluster". **k3sup** is a handy installer, but it's one more tool,
and it hides the config. Either is a fine choice later, once you know what the steps do.

### Why embedded etcd and not the default SQLite?
For one machine SQLite is lighter, but etcd brings two things the guide wants:
- **built-in snapshots**, scheduled, with an optional upload to a bucket. With SQLite you'd build
  that yourself;
- **room to grow**: more *server* nodes can join an etcd cluster later. With SQLite, extra
  machines can only join as workers.

The cost is some extra RAM (a few hundred MB) and more disk writes. On an SSD that's fine.

### Where do the snapshots go off the machine, and why not a bucket?
k3s writes each snapshot to the data disk. The guide gets them off the machine with a **nightly
Proxmox backup of the whole VM** to backup storage you already have, such as a NAS. One job then
covers everything: the OS, the app volumes on `/data`, and the snapshots, with no new account or
keys. The VM backup also copies the live etcd files, but those are only crash-consistent. The
snapshot files inside it are clean, point-in-time copies, and they're what you restore from.

| Option | Verdict |
|---|---|
| **Nightly VM backup to a NAS** ✅ | Uses storage you already have, and covers the whole machine. At most one day of changes is lost, and the copy stays in your home until you send it off-site. |
| **k3s uploads to an S3 bucket** (R2, AWS S3…) | Off-site every 6 hours, independent of Proxmox. One more account and set of keys. The chapter shows it as an optional step. |
| **An S3 service on the NAS** (MinIO, Garage) | Snapshots off the machine every 6 hours, but one more service to run. |

k3s only uploads to **S3-compatible** storage. A backup service that speaks SFTP or rsync (for
example a Hetzner Storage Box) can't receive snapshots directly. It's a good place for an
off-site copy of your backup storage, which the Day 2 chapter covers.

If you use a bucket, its keys go in a **Kubernetes Secret**, not in `config.yaml`, so the config
file holds no credentials and can live in git. To **restore** onto a fresh machine there's no
cluster to hold the Secret yet, so you pass the bucket details on the command line.

### Why keep Traefik, ServiceLB and local-path?
They're already there, they work, and they fit one machine. Traefik is also what many Docker
setups already use for ingress. Replacing them is easy later (k3s can disable each one), and each
replacement would be one more thing to learn before your first app runs. local-path volumes are
plain folders on one machine. That's fine here, because the whole cluster is one machine. A second
machine would bring a replicated storage choice, and that's on the roadmap.

### Why pin the k3s version?
So installing again (on a rebuilt machine) gives the same cluster as before. Upgrades happen when
you choose to, one minor version at a time, after a snapshot. That's covered in the Day 2 chapter.

### Why does the install script change an AppArmor setting?
Ubuntu 26.04 turns on `kernel.apparmor_restrict_unprivileged_unconfined` by default. With it on,
every container runs under a "stacked" AppArmor label (`cri-containerd.apparmor.d//&unconfined`)
that the container runtime's own profile doesn't expect. The result: **processes in the same
container can't send each other signals.** Most apps don't notice. Postgres does: its processes wake
each other with signals, so the first connection waits forever and the database never finishes
starting (chapter 7). The kernel log shows it as `apparmor="DENIED" operation="signal"`.

The script turns that one setting off in `/etc/sysctl.d/20-apparmor.conf`, the override file
Ubuntu's own config points to. Containers still run under their AppArmor profile, just without the
stacked label. The fix belongs in the container runtime
([containerd#14485](https://github.com/containerd/containerd/issues/14485)). Once a k3s release
ships it, the setting can go back on. If you installed k3s before this was in the script, add the
file and reboot the machine, because running containers keep their old label.


## Chapter 3 · GitOps

### Why ArgoCD and not Flux?
Both are mature, open-source GitOps tools from the CNCF, and both would do the job. The guide picks
**ArgoCD** for its **web UI**: you see every app, its sync state and the difference between git and
the cluster, which helps a lot while you learn. **Flux** has no built-in UI and is driven by its CLI
and Kubernetes objects. It's lighter, and a great choice if you prefer working in the terminal.

### Which ArgoCD version, and why?
The newest release that's **tested on your Kubernetes version**. ArgoCD publishes the versions each
release is tested against, and at the time of writing only 3.6 lists Kubernetes 1.37, the version
k3s installs in chapter 2. The guide pins its first patch release (3.6.1), through the Helm chart
version that ships it. Check the table in ArgoCD's docs ("Tested Kubernetes versions") when you
upgrade either one.

### Why install it with Helm and then let ArgoCD manage itself?
Something has to install ArgoCD before ArgoCD can install anything, so the first install is by
hand. Helm makes that one command, with your settings in a values file in git. Then
`apps/argocd.yaml` gives ArgoCD the same chart, version and values, and ArgoCD takes over.

| Option | Why not (here) |
|---|---|
| **Helm, then upgrades by hand** | Works, but ArgoCD itself sits outside GitOps: its version and settings live in your shell history, not in a commit. |
| **The plain install manifest** (`kubectl apply -f install.yaml`) | No Helm, but every setting becomes a patch on a large YAML file, which is harder than a values file. |

The catch: once ArgoCD manages itself, a bad change to its own settings can break the tool you'd
use to fix it. If that happens, `helm upgrade` with the last good values file brings it back.

### Why a deploy key to read the repository?
A **deploy key** is an SSH key that reaches **one repository** and, unless you allow it, can
**only read**. That's exactly what ArgoCD needs. A leaked key exposes your config, and nothing else
on your GitHub account.

| Option | Why not (here) |
|---|---|
| **A GitHub App** | Short-lived tokens and fine-grained permissions, and one app can cover many repositories. Worth it with several repositories, but more setup for one. |
| **A fine-grained personal access token** | Tied to your user account, and it expires, so it needs rotating by hand. |
| **A public repository** | No credentials at all, but your config names your hosts and structure. |

The private key is never saved anywhere but the cluster. If you lose it, you make a new one: a
deploy key is cheap to replace.

### Why "app of apps" and not an ApplicationSet?
An **ApplicationSet** generates Applications from a pattern, for example one per folder under
`apps/`. It's less YAML when you have many similar apps, but it's one more concept, and per-app
settings get harder. With **app of apps**, each app is one plain, readable Application file. It's
easy to see why something runs: there's a file for it. You can move to ApplicationSets later
without changing the apps themselves.

### Why port-forward to reach the UI?
Because nothing is exposed on the network yet, and there's nothing to undo later. Opening the UI on
your LAN now would mean plain HTTP, so your admin password would cross the network unencrypted.
Chapter 5 gives ArgoCD a proper `https://` address with a real certificate.

## Chapter 4 · Secrets

### Why a secrets manager, and not encrypted secrets in git (SOPS, Sealed Secrets)?
Encrypted secrets in git work well, and need no outside service. But the encrypted files stay in
your history forever, so a key that leaks later unlocks every old version too. Rotating a secret
means re-encrypting and committing. A secrets manager keeps the values out of git entirely, lets you
change a secret without a commit, and is where you'd look for a password anyway. See
[decision 4](/plan/architecture/#4-secrets-live-in-a-secrets-manager-off-the-machine).

### Why Bitwarden Secrets Manager?
It's hosted (nothing more to run or back up at home), its free plan covers a homelab (3 projects,
3 machine accounts, unlimited secrets), and many people already use Bitwarden for passwords.

Two honest caveats:
- External Secrets marks its Bitwarden support as **alpha**: it works, but it has fewer users than
  the big cloud providers, and its settings may change between versions. The guide pins the version
  and was tested with it. The same label is on Infisical, Doppler, 1Password and OpenBao, so
  switching to another hosted manager doesn't avoid it.
- It needs a helper service inside the cluster, the Bitwarden SDK server, with its own certificate.

| Alternative | When to pick it |
|---|---|
| **Infisical** or **Doppler** | Similar hosted managers that External Secrets reaches directly, with no helper service or certificate. Pick one if you don't use Bitwarden. |
| **1Password** | If you already pay for it. |
| **A cloud provider's manager** (AWS, Google Cloud, Azure) | If you already have an account there. They're among External Secrets' stable providers, but they're paid per secret and per request. |
| **Self-hosted** (OpenBao, Vault) | If nothing may leave your home. It's one more critical service to run and back up, and it's on the roadmap's extras. |

### Why install cert-manager in this chapter?
The Bitwarden SDK server only speaks HTTPS, so it needs a certificate, and making certificates is
cert-manager's job. The alternative, a certificate made by hand with `openssl`, is one more thing
created outside git, and you'd have to remember to renew it. Chapter 5 needed cert-manager anyway.

The certificate is **self-signed and long-lived** (10 years) on purpose. It's only used inside the
cluster, between two components, and the store trusts exactly that certificate. The SDK server
reads its certificate only when it starts, so a renewed short-lived certificate wouldn't be picked
up until the pod restarted.

### Which versions, and why?
The newest releases, checked against each project's table of supported Kubernetes versions.
External Secrets 2.14 is tested on Kubernetes 1.37. cert-manager 1.21 lists Kubernetes up to 1.36:
its next release (1.22) is expected around November 2026, with its Kubernetes versions not yet
announced. Moving to it will be a one-line change in `apps/cert-manager.yaml`. cert-manager uses only stable Kubernetes APIs, so a version one step
behind is a small risk.

### Why one ClusterSecretStore and one project?
One project and one machine account means one token to create by hand, and one store that every
namespace can use. The cost: any app's ExternalSecret could ask for any secret in the project. With
one administrator, that's fine. With several teams, or apps you trust less, give each its own
project, machine account and (namespaced) SecretStore, so a leaked token reaches less.

### Why point to secrets by name, not by id?
A name like `demo-message` is readable in git and in reviews. You can see what an app uses without
opening Bitwarden. Names must be unique within the project, and External Secrets reports an error if
two secrets share one. An id survives a rename, but git then shows only opaque ids.

## Chapter 5 · HTTPS and private DNS

### Why one wildcard certificate, and not one per app?
Every certificate Let's Encrypt issues is published in public **certificate transparency logs**,
however you proved you own the domain. One certificate per app would list each app's name there,
and anyone could search for them (for example on crt.sh). The names don't let anyone in, because
they only resolve on your LAN, but they do tell an attacker what software you run. A wildcard
certificate shows only `*.lab.home.example.com`.

The usual argument for per-app certificates is a smaller blast radius: a leaked key affects one app.
That mostly disappears here. One Traefik ends HTTPS for every app, so it holds every key either way,
and whoever compromises it gets them all. A wildcard also means one renewal to watch instead of many.

Per-app certificates make sense when different teams or different ingress controllers own different
apps. Then each Ingress can ask cert-manager for its own.

### Doesn't the DNS challenge keep the names private?
No. DNS-01 is only how you prove you own the domain: a temporary record in public DNS, instead of
Let's Encrypt connecting to your server. It keeps your services **unreachable** from the internet.
It doesn't keep them **unlisted**: the certificate itself still goes into the public logs.

### Why does cert-manager check the challenge on public DNS servers?
Before asking Let's Encrypt to check, cert-manager looks up the challenge record itself. By
default it asks the cluster's DNS, which forwards to your internal DNS. Your internal DNS answers
for `home.example.com` itself, so it says the record doesn't exist, and cert-manager waits forever.
The two `extraArgs` lines make cert-manager ask public servers (Cloudflare's `1.1.1.1` here), which
see what Let's Encrypt sees.

If your internal DNS doesn't answer for your domain (for example, it only forwards), you don't need
them, but they do no harm.

### Why a new API token, and not reuse one?
A token for each user means you can revoke or rotate one without breaking another. The token only
gets DNS edit on one zone, so a leaked token can't touch the rest of your account. It can still
change any record in that zone, which is why it lives in the secrets manager and nowhere else.

### Why one DNS record by hand, and not external-dns?
external-dns writes a DNS record for each Ingress automatically. With a wildcard record, there's
nothing left for it to do: every name under the subdomain already reaches the cluster. It would add
a component, and a key that can write to your internal DNS, to save one record you add once.

external-dns makes sense when apps live on different machines, or when you can't use a wildcard.

### Why change k3s's own Traefik, and not install another ingress controller?
k3s already runs Traefik, and lets you change its settings with a `HelmChartConfig` file, which
k3s merges into its own install. That file lives in git like everything else. Installing a second
controller would mean disabling k3s's one, and then keeping your own up to date.

### Why a standard Ingress, and not Gateway API or Traefik's IngressRoute?
The standard Ingress is the simplest way to route a name to an app, every controller understands
it, and most examples online use it. Gateway API is its newer, more capable successor, and Traefik
supports it. It's worth a look once you need what it adds, such as splitting traffic between
versions. IngressRoute is Traefik's own format: powerful, but it ties every app to Traefik.

### Why start with Let's Encrypt's test service?
The real service has strict limits. For example, it issues at most five identical certificates a
week. A mistake while setting up can use them up, and lock you out for days. The test service has
generous limits, so you fix mistakes there and switch to the real one once.

### Why no email address in the issuers?
Let's Encrypt used the address for expiry warnings, and it stopped sending them in 2025.
cert-manager renews the certificate on its own, and the address isn't needed.

### Why does ArgoCD serve plain HTTP now?
Traefik handles HTTPS for every app with the same certificate, and passes requests on to the app
inside the cluster. If ArgoCD kept its own self-signed HTTPS too, Traefik would have to be told to
trust it. The `argocd` command-line tool also works through Traefik, with its `--grpc-web` flag.

## Chapter 6 · Your first app

### Why GitHub Container Registry?
It sits next to the code: GitHub Actions pushes to it with the workflow's own token, so there's no
registry password to create or store. Public images are free, and anyone can pull them without
logging in, including your cluster.

| Alternative | When to pick it |
|---|---|
| **Docker Hub** | If your images already live there. It needs an access token stored in GitHub, and limits how often anonymous users can pull. |
| **A registry in your cluster** (Zot, Harbor) | If images may not leave home. It's one more service to run, back up and keep secure, and your cluster then depends on itself to start its apps. |
| **Your cloud provider's registry** | If you already deploy there. |

### Why publish on a git tag, and not on every merge?
A tag is a decision: "this is a release". Each version gets a readable number, and its image never
changes. Publishing on every merge gives you an image per commit, with names like `sha-1a2b3c4`
that say little, and many images to clean up. Pull requests still build the image, without
publishing it, so a broken `Dockerfile` shows up before it's merged.

### Why does the image tag drop the `v`?
`v0.1.0` is the git convention, and `0.1.0` is the image convention. The workflow's
`type=semver` rule turns one into the other, and ignores tags that aren't versions.

### Why change the version by hand in the config repository?
Every deployment is then a commit you made: you can see what changed, when, and undo it with
`git revert`. Automating it means giving some tool write access to your config repository, or
running one more component in the cluster. Chapter 8 does that, once a real app releases often
enough to need it.

### Why plain YAML, and not Kustomize or a Helm chart?
One app, one environment: a Deployment, a Service and an Ingress say everything, and the version is
one line. **Helm** is the standard way to *package* software for others to install, which is why
the tools in chapters 3 to 5 come as charts. For your *own* apps, teams use both Helm and
**Kustomize**. Kustomize is built into `kubectl` and ArgoCD, and fits "the same app with small
changes for dev and prod". A chart pays off when you need templating logic, or install the same app
many times. Chapter 8 revisits this for a multi-service app.

### Why an unprivileged nginx, with a read-only file system?
A static site needs nothing more. The container runs as a normal user, can't gain privileges,
can't change its own files, and writes only to a temporary folder. If someone found a flaw in
nginx, there would be little they could do with it. It costs a few lines of YAML.

### Why build for amd64 and arm64?
So the same image runs on a mini PC and on a Raspberry Pi. The site is plain HTML, CSS and JS, the
same on every platform, so the build runs once, natively, and only the small nginx layer differs.
That avoids emulating arm64, which would make CI many times slower.

### What is the build record (attestation)?
A signed statement, stored with the image, saying which repository, commit and workflow built it.
`gh attestation verify` checks it. It lets you prove an image came from your CI and not from
someone's laptop, and it costs one step in the workflow.

### Why are the GitHub Actions pinned by major version, not by commit?
`actions/checkout@v7` gets fixes automatically, and the actions used here come from GitHub and
Docker. Pinning each action to a commit is safer against a compromised action, but every update
becomes a manual change. Tools like Dependabot or Renovate make that easy, and they are worth adding
once you have several repositories.

### What if my image is private?
The cluster then needs credentials to pull it: a registry token, stored in the secrets manager,
synced into the app's namespace by an ExternalSecret of type `kubernetes.io/dockerconfigjson`, and
named in the Deployment's `imagePullSecrets`. Chapter 8 does this for a private app.

## Chapter 7 · A database

### Why an operator, and not a plain Postgres container?
A Postgres container with a volume runs fine, until you need a backup you can trust, a restore, or
a major version upgrade. Then you're writing scripts for each. An operator already knows how: it
makes consistent backups, archives WAL continuously, restores into a new cluster from one YAML
file, and runs upgrades in the right order. A plain container plus a nightly `pg_dump` is simpler,
but it only gives you last night's data, and you test the restore by hand.

### Why CloudNativePG?
It's the most widely used Postgres operator, a CNCF project, and built for Kubernetes from the
start. Backups, point-in-time recovery and restores are part of the Cluster file.

| Alternative | When to pick it |
|---|---|
| **Crunchy PGO** | If you want pgBackRest, a very mature backup tool. It's heavier, and still needs object storage for off-site backups. |
| **Zalando postgres-operator** | If you already know it. It's older, and its backups (WAL-G) need more setup. |
| **A plain container + `pg_dump`** | For a throwaway database, or if your backups can only go somewhere that isn't object storage (for example SFTP). |

### Which versions, and why?
CloudNativePG 1.30, the newest. It officially supports Kubernetes 1.34 to 1.36, and lists 1.37,
which this guide runs, as "tested, but not supported": the project runs its tests on it, but
doesn't promise fixes for problems found only there. Postgres 18 is the newest version it
supports.

### Why the Barman Cloud plugin, and not the operator's built-in backups?
CloudNativePG used to back up to object storage by itself (`barmanObjectStore` in the Cluster).
That's deprecated in favour of the plugin, which keeps the backup code out of the operator and out
of the Postgres image. New setups should use the plugin. It needs cert-manager, which you already
have.

### Why one instance?
On one machine, a second instance would sit on the same disk, in the same box: if the machine
fails, both fail. It would double the memory and protect nothing. With a second machine, set
`instances: 2`, and the operator adds a replica and handles failover.

### Why Cloudflare R2 for backups?
CloudNativePG backs up to S3-compatible object storage, and R2 is S3-compatible, off-site, and has
a free tier that a homelab database fits in easily: 10 GB of storage, a million writes and ten
million reads a month, per account (not per bucket). A small database with 14 days of backups and
WAL uses a fraction of that. R2 also doesn't charge for downloads, so a restore costs nothing.

If you'd rather keep backups at home, run S3-compatible storage on your NAS (for example Garage),
and copy that off-site separately. A storage service that only speaks SFTP (like a Hetzner Storage
Box) doesn't work with the plugin directly.

### Are the backups encrypted?
R2 encrypts everything it stores, and the connection uses HTTPS. The plugin can't encrypt backups
itself before they leave the cluster. That's why the access key only reaches one bucket, and lives
only in the secrets manager.

### Why let the operator create the passwords?
It creates a strong password for the app user, stores it in a Secret next to the database, and an
app reads it from there. Nobody types it, and it never touches git or your laptop. A password from
the secrets manager would be one more value to create and keep in sync, for no gain, because only
the app inside the cluster uses it. The Postgres superuser has no password and no network access:
`kubectl exec` is how you get an admin shell.

### Why restore in this chapter, and not later?
A backup you've never restored is a hope. Restoring into a second cluster proves that the bucket
alone is enough, without touching the original. Do it again whenever you change how backups work.

### Why a 14-day retention?
Long enough to notice a problem, like a bad migration or deleted rows, and restore to before it.
Short enough to stay small. Change `retentionPolicy` if you need more.

### Why a port-forward to connect a database tool, and not open the database to the network?
`kubectl port-forward` opens nothing new. The database stays reachable only inside the cluster, the
tunnel exists only while the command runs, and only someone with your kubeconfig can open it. It
works the same for every database you add later. The tunnel is also encrypted on its way to the
cluster, which is why the tool's own SSL stays off.

The alternatives are a permanent opening:
- **Expose port 5432** through Traefik (as a TCP route) or a LoadBalancer service. Then every
  machine on the network can try to log in, so you'd want TLS checked end to end and network rules
  too. Worth it when other machines need constant access, for example a reporting tool on another
  server.
- **A web database tool in the cluster** (pgAdmin, DbGate). Handy from any browser, but it's one
  more app to log in to, secure and keep updated, with the passwords of every database inside it.

### Why does the demo declare its own namespace?
ArgoCD's `CreateNamespace=true` option creates a namespace if it's missing, but ArgoCD never deletes
a namespace it made that way. Declared as a file in the app's folder, the namespace is managed like
everything else, so removing the app removes it too. The Helm-chart apps (cert-manager, the
operator) keep the option: they stay installed.
