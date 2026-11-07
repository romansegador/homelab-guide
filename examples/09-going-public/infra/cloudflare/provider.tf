# The API token comes from the CLOUDFLARE_API_TOKEN environment variable (source ./load-secrets.sh),
# never from a file. It needs: Account › Cloudflare Tunnel › Edit, Account › Access: Apps and
# Policies › Edit, Zone (your domain) › DNS › Edit. All available on the free plan.
provider "cloudflare" {}
