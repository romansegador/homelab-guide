# The state is encrypted on your laptop before it's uploaded, so the bucket only ever holds
# ciphertext. The passphrase is NOT configured here. Export it in your shell:
#   export TF_VAR_state_passphrase=…   (at least 16 characters; keep it in your password manager)
# Lose the passphrase and the state can't be read: OpenTofu then no longer knows it manages the VM.
terraform {
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true # refuse to ever write the state unencrypted
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true # saved plan files (tofu plan -out=…) hold the same details
    }
  }
}
