output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.lab1.id
}

output "tunnel_token" {
  description = "Copy to your secrets manager as cloudflare-tunnel-token: tofu output -raw tunnel_token | pbcopy"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.lab1.token
  sensitive   = true
}

output "public_hostnames" {
  value = [for name, _ in var.public_apps : "${name}.${var.domain}"]
}
