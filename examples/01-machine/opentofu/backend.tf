# Where OpenTofu keeps its state: an S3-compatible bucket (Cloudflare R2 in the guide).
# The bucket and endpoint live in backend.hcl (copy backend.hcl.example), loaded with:
#   tofu init -backend-config=backend.hcl
# The bucket credentials are NOT configured here. Export them in your shell:
#   export AWS_ACCESS_KEY_ID=… AWS_SECRET_ACCESS_KEY=…
terraform {
  backend "s3" {
    key = "machine/terraform.tfstate"

    # Lock the state with a lock file next to it, so two runs can't write at the same time.
    use_lockfile = true
  }
}
