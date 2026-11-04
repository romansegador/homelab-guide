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
It's a full, certified Kubernetes in a single program. It installs in a minute, idles at well
under 1 GB of RAM, and includes what a one-machine cluster needs (ingress, a load balancer,
volumes). What you learn transfers to any Kubernetes. Alternatives: **k0s** and **MicroK8s**
(similar idea), **Talos** (an immutable OS that is only Kubernetes: great, but more to learn at
once), or full **kubeadm** (more parts to run yourself).

### Why install it with a script and a config file, not cloud-init or a tool like k3sup?
The config file is the source of truth, and it lives in your repository. The install is one
visible step that you can read, rerun and debug. Baking k3s into cloud-init would rebuild the
cluster automatically with the VM, but a failure would be hidden inside a first boot, and it
mixes "the machine" with "the cluster". **k3sup** is a handy installer, but it's one more tool,
and it hides the config. Either is a fine choice later, once you know what the steps do.

### Why embedded etcd and not the default SQLite?
For one machine SQLite is lighter, but etcd brings two things the guide wants:
- **built-in snapshots**, scheduled, with copies sent off the machine. With SQLite you'd build
  that yourself;
- **room to grow**: more *server* nodes can join an etcd cluster later. With SQLite, extra
  machines can only join as workers.

The cost is some extra RAM (a few hundred MB) and more disk writes. On an SSD that's fine.

### Why do the snapshot keys go in a Kubernetes Secret, not in the config file?
So the config file holds no credentials and can live in git. k3s reads the bucket details from a
Secret in `kube-system` when it takes a snapshot. In chapter 4 that Secret will come from the
secrets manager instead of a script. One catch: to **restore** onto a fresh machine, there's no
cluster to hold the Secret yet, so you pass the bucket details on the command line. They're in
your password manager.

### Why keep Traefik, ServiceLB and local-path?
They're already there, they work, and they fit one machine. Traefik is also what many Docker
setups already use for ingress. Replacing them is easy later (k3s can disable each one), and each
replacement would be one more thing to learn before your first app runs. local-path volumes are
plain folders on one machine. That's fine here, because the whole cluster is one machine. A second
machine would bring a replicated storage choice, and that's on the roadmap.

### Why pin the k3s version?
So installing again (on a rebuilt machine) gives the same cluster as before. Upgrades happen when
you choose to, one minor version at a time, after a snapshot. That's covered in the Day 2 chapter.

