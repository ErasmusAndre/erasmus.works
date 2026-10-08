#!/usr/bin/env bash
# Playwright MCP in extension mode: lets the "My Chrome" agent in Open WebUI drive tabs in my
# own (Flatpak) Google Chrome through the Playwright Extension. Listens on localhost:8933 only;
# browser-mcp-auth.js is the way in from the cluster (port 8932, bearer key).
# No PLAYWRIGHT_MCP_EXTENSION_TOKEN on purpose: every chat message opens a connect page in
# Chrome and nothing happens until I click Connect and pick the tab.
# Allowed sites: ~/.config/local-ai/allowed-origins, one origin per line (https://example.com),
# # for comments. Kept out of Git on purpose. No file = every site; an empty file = no site.
# Restart to apply changes (llm chrome on).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ORIGINS_FILE="$HOME/.config/local-ai/allowed-origins"

origin_args=()
if [[ -f "$ORIGINS_FILE" ]]; then
  origins=$(sed 's/#.*//' "$ORIGINS_FILE" | tr -s ' \t\r\n' '\n' | sed '/^$/d' | paste -sd ';')
  # Playwright treats an empty list as "allow all", so block everything with a name that never resolves.
  origin_args=(--allowed-origins "${origins:-https://nothing-allowed.invalid}")
  echo "allowed origins: ${origins:-none}"
else
  echo "no $ORIGINS_FILE: every site is allowed"
fi

exec node "$DIR/browser-mcp/node_modules/@playwright/mcp/cli.js" \
  --extension \
  --browser chrome \
  --executable-path /var/lib/flatpak/exports/bin/com.google.Chrome \
  --host 127.0.0.1 \
  --port 8933 \
  --image-responses omit \
  --output-dir "${XDG_RUNTIME_DIR:-/tmp}/browser-mcp" \
  "${origin_args[@]}"
