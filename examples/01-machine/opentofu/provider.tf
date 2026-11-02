# The API token is NOT configured here. Export it in your shell before running tofu:
#   export PROXMOX_VE_API_TOKEN='tofu@pve!provider=<the secret Proxmox showed you once>'
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure_tls

  # SSH is only used to upload the cloud-init snippet (the Proxmox API can't upload snippets).
  # It uses your running ssh-agent; check with `ssh-add -l` and `ssh root@<proxmox-host> true`.
  ssh {
    agent    = true
    username = var.proxmox_ssh_user
  }
}
