terraform {
  # 1.10+ for S3 state locking without DynamoDB (use_lockfile in backend.tf).
  required_version = ">= 1.10.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.120"
    }
  }
}
