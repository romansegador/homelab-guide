---
name: machine
description: Homelab Guide chapter 1. Use when creating the homelab's machine, typically a Proxmox VM from an Ubuntu cloud image with cloud-init, either through the Proxmox web UI or as code with OpenTofu and the bpg/proxmox provider, with a separate data disk mounted at /data.
---

# Chapter 1: The machine

You're helping the user create one VM (or prepare a bare-metal machine) that matches their
chapter 0 decisions:
- an Ubuntu Server 24.04 cloud image,
- an OS disk plus a separate data disk mounted at `/data`,
- a static IP, SSH key login only, the guest agent, unattended security updates.

Guide page: `/machine/create/` (or `src/content/docs/machine/create.mdx` in the guide repo).
Example code: `examples/01-machine/opentofu/` in the guide repo.

## Ground rules

- **Never ask for or handle secret values.** The Proxmox API token is created and exported by the
  user (`export PROXMOX_VE_API_TOKEN=…` in their own shell). Never print it, write it to a file, or
  put it in `terraform.tfvars`.
- **`tofu apply` and anything that creates, changes or deletes a VM needs the user's explicit OK**,
  after they've seen the `tofu plan` output. Same for UI steps that delete disks.
- Before changing Proxmox storage settings (`pvesm set … --content`), show the current value and
  make sure the new list **keeps every existing content type**.
- `terraform.tfvars` and `*.tfstate*` stay out of git (the example's `.gitignore` handles it).

## Ask first

1. Read their decisions file (chapter 0) if it exists. Otherwise collect: hostname, IP/CIDR,
   gateway, DNS server, search domain, CPU/RAM/disk sizes.
2. **Method:** Proxmox web UI (manual, good for a first time) or **OpenTofu** (as code,
   reproducible). Recommend OpenTofu if they're comfortable in a terminal.
3. Proxmox details: node name (`pvesh get /nodes`), VM storage (often `local-lvm`), the storage for
   images and snippets (often `local`), network bridge (often `vmbr0`), Proxmox version
   (`pveversion`; 8.4+ is needed for the "import" content type).
4. Which SSH public key to install (`~/.ssh/id_ed25519.pub` or similar).

## Path A: OpenTofu

1. Check that `tofu version` is 1.8 or newer. Install it if missing (https://opentofu.org/docs/intro/install/).
2. On Proxmox (as root, by the user or with their OK):
   - enable the `snippets` and `import` content types on the image storage, keeping the existing types;
   - create user `tofu@pve`, a role with the privileges listed on the guide page, and an API token
     (`pveum user token add tofu@pve provider --privsep 0`).

   The user stores the token secret themselves.
3. Copy `examples/01-machine/opentofu/` to the user's private infra repo. Fill
   `terraform.tfvars` from `terraform.tfvars.example`.
4. SSH agent: the provider uploads the cloud-init snippet over SSH as `root` (or the configured
   user) to the Proxmox host. Check with `ssh-add -l` and `ssh root@<proxmox> true`.
5. `tofu init`, then `tofu plan`. Walk the user through the plan. Apply only after their OK.

## Path B: Proxmox web UI

Follow the guide page's UI tab step by step. The data disk is formatted and mounted by hand
after first boot (the commands are on the page), because the UI can't attach custom cloud-init
user-data.

## Verify (both paths)

Run over SSH (`ssh <user>@<ip>`), and show the user each result:
- `cloud-init status --wait` → `status: done`
- `lsblk -f` → data disk with an ext4 filesystem labelled `data`
- `findmnt /data` → mounted, and `grep /data /etc/fstab` → present (survives reboots)
- `systemctl is-active qemu-guest-agent` → `active` (and Proxmox shows the VM's IP)
- `sshd -T | grep -E 'passwordauthentication|permitrootlogin'` → `no` / `no`
- `systemctl is-enabled unattended-upgrades` → `enabled`
- Reboot once (`sudo reboot`), then re-check `findmnt /data`.

## Done when

- [ ] Every check above passes, including after a reboot.
- [ ] The user takes a first VM backup or snapshot in Proxmox (optional, but recommended).
- [ ] Suggest the next chapter: **cluster**.
