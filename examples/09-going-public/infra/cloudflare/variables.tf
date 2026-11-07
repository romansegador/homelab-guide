variable "account_id" {
  description = "Cloudflare account id (not secret: it's part of every R2 address)"
  type        = string
}

variable "zone_id" {
  description = "Zone id of the public domain"
  type        = string
}

variable "domain" {
  description = "The public domain apps are published under"
  type        = string
}

variable "public_apps" {
  description = <<-EOT
    Apps published through the lab-1 tunnel. Key = the hostname's first label (key.domain).
    Every one goes to Traefik in the cluster, which routes it by name like any Ingress.
    `allow_emails` = who may log in through Cloudflare Access (each person = one Access seat).
  EOT
  type = map(object({
    allow_emails     = list(string)
    session_duration = optional(string, "24h")
  }))
}

variable "state_passphrase" {
  description = "Encrypts the OpenTofu state. Export TF_VAR_state_passphrase; never put it in a file"
  type        = string
  sensitive   = true
}
