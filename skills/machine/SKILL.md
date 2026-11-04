---
name: machine
description: Homelab Guide chapter 1. Use when creating the homelab's machine, typically a Proxmox VM from an Ubuntu cloud image with cloud-init, either through the Proxmox web UI or as code with OpenTofu and the bpg/proxmox provider, with a separate data disk mounted at /data. Also covers OpenTofu setup: a limited Proxmox API token, a restricted SSH user for snippet uploads, and encrypted remote state in Cloudflare R2 or any S3 bucket.
---

# Chapter 1: The machine

You're helping the user create one VM (or prepare a bare-metal machine) that matches their
chapter 0 decisions:
- an Ubuntu Server 24.04 cloud image,
- an OS disk plus a separate data disk mounted at `/data`,
- a static IP, SSH key login only, the guest agent, unattended security updates.

Guide pages: `/machine/opentofu-setup/` (OpenTofu path only) and `/machine/create/` (or
`src/content/docs/machine/*.mdx` in the guide repo). Reasoning behind the choices: `/start-here/faq/`.
Example code: `examples/01-machine/opentofu/` in the guide repo.

## Ground rules

- **Never ask for, generate or handle secret values.** Four secrets exist on the OpenTofu path: the
  Proxmox API token, the bucket's access key id and secret, and the state passphrase. The user
  creates them, stores them in their password manager, and exports them in their own shell
  (`PROXMOX_VE_API_TOKEN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TF_VAR_state_passphrase`).
  Never print them, write them to a file, or put them in `terraform.tfvars` or `backend.hcl`.
- **Never give the provider root SSH** to Proxmox. It uses the restricted `tofu` user, whose sudo
  rules allow only `pvesm apiinfo` and `tee` into the snippets folder. Never widen them to all of
  `pvesm`, `qm`, or a `tee` wildcard.
- **`tofu apply` and anything that creates, changes or deletes a VM needs the user's explicit OK**,
  after they've seen the `tofu plan` output. Same for UI steps that delete disks.
- Before changing Proxmox storage settings (`pvesm set … --content`), show the current value and
  make sure the new list **keeps every existing content type**.
- `terraform.tfvars` and `backend.hcl` hold no secrets and belong in the user's **private** repo.
  Local state and plan files stay out of git (the example's `.gitignore` handles it).
- Warn the user that losing the state passphrase makes the state unreadable.

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

Setup (once, guide page `/machine/opentofu-setup/`):
1. Check that `tofu version` is 1.10 or newer. Install it if missing (https://opentofu.org/docs/intro/install/).
   Terraform also works with the same files, minus state encryption.
2. On Proxmox (as root, by the user or with their OK): create user `tofu@pve`, the `TofuProvisioner`
   role with the privileges listed on the guide page, and an API token
   (`pveum user token add tofu@pve provider --privsep 0`). The user stores the token secret.
3. Restricted SSH user: install `sudo`, create Linux user `tofu` with the user's public key, and
   write `/etc/sudoers.d/tofu` exactly as on the guide page. Run `visudo -c`. Verify from the laptop:
   `ssh tofu@<proxmox> sudo pvesm apiinfo` prints `APIVER` with no password prompt.
4. State bucket: Cloudflare R2 (or any S3-compatible storage, but not one hosted on the homelab), with
   an access key scoped to that bucket only. The user creates it and keeps the keys.
5. State passphrase (16+ characters): the user generates it in their password manager.
6. If the user's SSH key lives in a password manager (Bitwarden/1Password SSH agent): `SSH_AUTH_SOCK`
   must point at its socket, and the public key must be saved to a file (`ssh-add -L > ~/.ssh/homelab.pub`)
   for `ssh_public_key_file`.
7. Finish with the "Where you are now" checklist on the setup page before moving on.

Create the VM (guide page `/machine/create/`, OpenTofu tab):
1. Enable the `snippets` and `import` content types on the image storage, keeping the existing types.
2. Copy `examples/01-machine/opentofu/` to the user's private infra repo. Fill `terraform.tfvars`
   and `backend.hcl` from their `.example` files.
3. The user loads the four secrets with `source ./load-secrets.sh` (hidden prompts, in their own
   terminal; it reports each variable as `set`/`EMPTY`, never the value). Then run
   `tofu init -backend-config=backend.hcl` and `tofu plan`. Walk the user through the plan (expect 3 to add). Apply only after their OK.
4. Confirm the bucket holds `machine/terraform.tfstate`, and that it's encrypted (an
   `encrypted_data` field, no readable resources).

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
