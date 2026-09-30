#!/usr/bin/env bash
# Creates Bitwarden Secrets Manager secrets for ExternalSecrets, without the web vault.
#
#   ./linux/bws-secrets.sh missing kubernetes/apps/kudos
#       List the Bitwarden keys that ExternalSecrets under a path reference but that don't exist yet.
#
#   ./linux/bws-secrets.sh create kudos-auth-secret:base64 kudos-postgres-password:hex ghcr-pull-token:prompt
#       Create each secret that doesn't exist yet. Existing secrets are never changed.
#
# Types:
#   hex      32 random bytes as hex (64 chars). Passwords, Garage secret keys.
#   base64   32 random bytes as base64. Session/signing secrets.
#   prompt   Ask for the value (hidden input). Tokens from other services.
#   vapid    Web push key pair: creates <name>-public-key and <name>-private-key.
#
# Needs: bws (Bitwarden Secrets Manager CLI), jq, openssl; npx for `vapid`.
# Token: BWS_ACCESS_TOKEN, or the file ~/.config/bws/token (override with BWS_TOKEN_FILE).
# It must be a machine-account token with write access to the project.
set -euo pipefail

PROJECT_ID="${BWS_PROJECT_ID:-f2215b03-7218-473e-a29f-b40901159f28}"
export BWS_SERVER_URL="${BWS_SERVER_URL:-https://vault.bitwarden.eu}"

die() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }
usage() { sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit "${1:-0}"; }

need() { command -v "$1" >/dev/null || die "$1 is not installed"; }
preflight() {
  need bws
  need jq
  need openssl
  local token_file="${BWS_TOKEN_FILE:-$HOME/.config/bws/token}"
  if [ -z "${BWS_ACCESS_TOKEN:-}" ] && [ -r "$token_file" ]; then
    BWS_ACCESS_TOKEN="$(<"$token_file")"
    export BWS_ACCESS_TOKEN
  fi
  [ -n "${BWS_ACCESS_TOKEN:-}" ] || die "set BWS_ACCESS_TOKEN or put the token in $token_file"
  # Listing a project the token can't access returns [] rather than an error, so check first.
  bws project list --output json --color no | jq -e --arg id "$PROJECT_ID" 'any(.[]; .id == $id)' >/dev/null \
    || die "the token can't see project $PROJECT_ID (give its machine account 'Can read, write' on it)"
}

existing_keys() { bws secret list "$PROJECT_ID" --output json --color no | jq -r '.[].key'; }

# Bitwarden keys referenced by remoteRef blocks in ExternalSecret manifests under the given paths.
referenced_keys() {
  find "$@" -name '*.yaml' -print0 \
    | xargs -0 awk '/remoteRef:/ { inref = 1; next } inref && /^[[:space:]]*key:/ { print $2; inref = 0 }' \
    | tr -d '"'"'" | sort -u
}

create() { # key value
  bws secret create "$1" "$2" "$PROJECT_ID" --output none --color no \
    --note "Created by linux/bws-secrets.sh on $(date +%F)"
  printf '  \033[1;32mcreated\033[0m %s\n' "$1"
}

cmd_missing() {
  [ $# -gt 0 ] || usage 1
  local have
  have="$(existing_keys)"
  referenced_keys "$@" | while read -r key; do
    grep -qxF "$key" <<<"$have" || echo "$key"
  done
}

cmd_create() {
  [ $# -gt 0 ] || usage 1
  local have spec name type value pair
  have="$(existing_keys)"
  exists() { grep -qxF "$1" <<<"$have"; }

  for spec in "$@"; do
    name="${spec%%:*}"
    type="${spec#*:}"
    [ "$name" != "$spec" ] && [ -n "$name" ] || die "expected NAME:TYPE, got '$spec'"

    case "$type" in
      hex | base64 | prompt)
        if exists "$name"; then printf '  exists  %s\n' "$name"; continue; fi
        case "$type" in
          hex) value="$(openssl rand -hex 32)" ;;
          base64) value="$(openssl rand -base64 32)" ;;
          prompt)
            read -rsp "  value for $name: " value </dev/tty; echo
            [ -n "$value" ] || die "empty value for $name"
            ;;
        esac
        create "$name" "$value"
        ;;
      vapid)
        # Both halves or neither: a mismatched pair breaks push for every phone.
        if exists "$name-public-key" || exists "$name-private-key"; then
          printf '  exists  %s-public-key / %s-private-key\n' "$name" "$name"; continue
        fi
        need npx
        pair="$(npx --yes web-push generate-vapid-keys --json)"
        create "$name-public-key" "$(jq -r .publicKey <<<"$pair")"
        create "$name-private-key" "$(jq -r .privateKey <<<"$pair")"
        ;;
      *) die "unknown type '$type' for $name (hex, base64, prompt, vapid)" ;;
    esac
  done
}

case "${1:-}" in
  missing) shift; preflight; cmd_missing "$@" ;;
  create) shift; preflight; cmd_create "$@" ;;
  -h | --help | help) usage ;;
  *) usage 1 ;;
esac
