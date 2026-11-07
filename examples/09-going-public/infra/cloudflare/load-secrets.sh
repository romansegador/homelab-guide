# Load the four secrets OpenTofu needs into THIS terminal, without writing them anywhere.
#
#   source ./load-secrets.sh
#
# It asks for each value with hidden input: paste it from your password manager and press Enter.
# Nothing is saved to disk or to your shell history. The values last until you close the terminal.
# Works in zsh (the macOS default) and bash.

# Sourcing is required: run as a program, the values would vanish when it exits.
if [ -n "${ZSH_VERSION:-}" ]; then
  case "${ZSH_EVAL_CONTEXT:-}" in
    *:file*) ;;
    *) echo "Run it with: source ./load-secrets.sh" >&2; exit 1 ;;
  esac
elif [ -n "${BASH_VERSION:-}" ] && [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "Run it with: source ./load-secrets.sh" >&2
  exit 1
fi

_tofu_ask() {
  # $1 = variable name, $2 = prompt
  printf '%s: ' "$2" >&2
  IFS= read -r -s "$1"
  printf '\n' >&2
  export "$1"
}

_tofu_ask CLOUDFLARE_API_TOKEN "Cloudflare API token (Tunnel, Access, DNS edit)"

_tofu_ask AWS_ACCESS_KEY_ID "State bucket: Access Key ID"
_tofu_ask AWS_SECRET_ACCESS_KEY "State bucket: Secret Access Key"
_tofu_ask TF_VAR_state_passphrase "State passphrase"

unset -f _tofu_ask

# Report which values are set, never the values themselves.
for _v in PROXMOX_VE_API_TOKEN AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY TF_VAR_state_passphrase; do
  if [ -n "$(eval "printf '%s' \"\${$_v:-}\"")" ]; then
    printf '  %-26s set\n' "$_v" >&2
  else
    printf '  %-26s EMPTY\n' "$_v" >&2
  fi
done
unset _v
