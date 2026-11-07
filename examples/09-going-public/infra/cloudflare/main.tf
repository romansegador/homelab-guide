# The lab-1 tunnel: cloudflared runs inside the cluster (manifests/cloudflared) and connects OUT to
# Cloudflare; nothing on your home network is opened to the internet.
#
# Free plan: tunnels, their routes and proxied DNS records are free; Access is free up to 50 seats.

resource "cloudflare_zero_trust_tunnel_cloudflared" "lab1" {
  account_id = var.account_id
  name       = "lab-1"
  # Routes live in Cloudflare (set below), so cloudflared only needs the token.
  config_src = "cloudflare"
}

# What cloudflared receives for each public hostname: send it to Traefik over HTTPS. Traefik
# serves the hostname's own Let's Encrypt certificate, which cloudflared checks against the name
# (origin_server_name), so the hop inside the cluster is encrypted and verified.
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "lab1" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lab1.id

  config = {
    ingress = concat(
      [for name, _ in var.public_apps : {
        hostname = "${name}.${var.domain}"
        service  = "https://traefik.kube-system.svc.cluster.local:443"
        origin_request = {
          origin_server_name = "${name}.${var.domain}"
        }
      }],
      # Anything else that reaches the tunnel gets a 404.
      [{ service = "http_status:404" }]
    )
  }
}

# The token cloudflared runs with. Sensitive: copy it to Bitwarden with
#   tofu output -raw tunnel_token | pbcopy
data "cloudflare_zero_trust_tunnel_cloudflared_token" "lab1" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lab1.id
}

resource "cloudflare_dns_record" "app" {
  for_each = var.public_apps

  zone_id = var.zone_id
  name    = "${each.key}.${var.domain}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.lab1.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1 # "automatic", required for proxied records
  comment = "lab-1 tunnel (config repository: infra/cloudflare)"
}

# Who may reach each app: Cloudflare Access asks for a login before any request reaches the
# tunnel. No allowed_idps: the login page offers every login method your Zero Trust organisation
# has (the one-time PIN by email, unless you add others).
resource "cloudflare_zero_trust_access_policy" "app" {
  for_each = var.public_apps

  account_id = var.account_id
  name       = "${each.key}: allowed people"
  decision   = "allow"
  include    = [for e in each.value.allow_emails : { email = { email = e } }]
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = var.public_apps

  account_id       = var.account_id
  name             = each.key
  type             = "self_hosted"
  domain           = "${each.key}.${var.domain}"
  session_duration = each.value.session_duration
  policies = [{
    id         = cloudflare_zero_trust_access_policy.app[each.key].id
    precedence = 1
  }]
}
