# Local AI (ai.erasmus.works)

Private ChatGPT at https://ai.erasmus.works. The model runs on the laptop GPU; everything else runs in the cluster. The laptop scripts are copied in [`linux/local-ai/`](../linux/local-ai/); the live copy is `~/code/ew/local-ai/`. Keep both in sync.

## What runs where

| Piece | Where | Defined in |
|---|---|---|
| Qwen3.6-35B-A3B (Unsloth `UD-Q4_K_XL`), llama.cpp `b11468` | Laptop, :8080 | `linux/local-ai/run.sh` |
| Open WebUI 0.11.4 + CNPG Postgres | `app-ai` | `kubernetes/apps/ai/` |
| SearXNG + Playwright (page reading) | `app-ai-web` | `kubernetes/apps/ai-web/` |
| Playwright MCP sandbox (browser agent) | `app-ai-browser` | `kubernetes/apps/ai-browser/` |
| Playwright MCP for my own Chrome + key proxy | Laptop, :8933 local, proxy :8932 | `linux/local-ai/browser-mcp*` |
| Login | Cloudflare Access (`Homelab-Admin`), then Authentik | Cloudflare dashboard, `blueprints/ai.yaml` |
| Cluster → laptop | UniFi `Allow-Cluster-to-llama` (→ `192.168.178.81`, TCP 8080, 8932), laptop ufw | UniFi, ufw |
| Secrets | Bitwarden `llama-api-key`, `ai-*` | ExternalSecrets |

The laptop must be on, at home, on Wi-Fi (`192.168.178.81`). Otherwise the UI works but the model doesn't answer. No cloud fallback, by choice.

## Use

```bash
llm              # model, log in this terminal; Ctrl+C stops everything
llm chrome       # model + My Chrome agent
llm -d           # in the background (llm chrome -d for both)
llm stop         # stop everything
llm chrome on    # only the My Chrome agent (restarts it, reloading allowed sites); "llm chrome off" stops it
llm status
```

Desktop shortcuts: **Start local AI** (`llm -d`), **Stop local AI** (`llm stop`). `llama-server` starts at boot; the My Chrome units only run when started. **Stopping them is what disables My Chrome**: while they run, a request with the key can open Chrome itself. Each message opens a Connect page in Chrome (no extension token, on purpose); an unexpected one means something else is trying.

## Rebuild the laptop

1. Ubuntu, NVIDIA driver (`nvidia-smi` works), Node 22, Flatpak Google Chrome with the Playwright Extension. Fixed IP `192.168.178.81` in UniFi; a new IP must change in UniFi, `kubernetes/apps/ai/networkpolicy.yaml` and both Open WebUI connections.
2. Files:
   ```bash
   D=~/code/ew/local-ai; R=~/code/ew/erasmus.works/linux/local-ai; mkdir -p $D/browser-mcp && cd $D
   cp $R/{run.sh,llm.sh,browser-mcp.sh,browser-mcp-auth.js,*.service} .
   cp $R/browser-mcp-package.json browser-mcp/package.json; cp $R/browser-mcp-package-lock.json browser-mcp/package-lock.json
   npm ci --prefix browser-mcp
   B=b11468; U=https://github.com/ggml-org/llama.cpp/releases/download/$B; mkdir -p llama.cpp
   curl -sL --fail $U/llama-$B-bin-ubuntu-cuda-12.8-x64.tar.gz | tar xz -C llama.cpp
   curl -sL --fail $U/cudart-llama-$B-bin-ubuntu-cuda-12.8-x64.tar.gz | tar xz -C llama.cpp
   mkdir -p models && curl -L --fail -C - -o models/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf \
     https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf   # ~21 GB
   ```
3. Keys in `~/.config/local-ai/` (mode 600): `api-key` = Bitwarden `llama-api-key`; `browser-mcp-key` = new `openssl rand -hex 32`, pasted in Open WebUI > Integrations > My Chrome.
4. Services:
   ```bash
   for u in llama-server browser-mcp browser-mcp-auth; do systemctl --user link $D/$u.service; done
   systemctl --user enable llama-server; sudo loginctl enable-linger $USER
   ln -s $D/llm.sh ~/.local/bin/llm; cp $R/local-ai-*.desktop ~/.local/share/applications/
   sudo ufw allow from 192.168.20.0/24 to any port 8080 proto tcp
   sudo ufw allow from 192.168.20.33 to any port 8932 proto tcp
   sudo ufw allow from 192.168.20.184 to any port 8932 proto tcp
   sudo ufw enable
   ```
5. `llm -d`, then chat with each model at ai.erasmus.works.

## Open WebUI settings (in its database, not Git)

After the first start, the Admin Panel wins over `values.yaml`. Backed up by CNPG and VolSync.

| Admin > Settings | Setting |
|---|---|
| Connections | `http://192.168.178.81:8080/v1`, key `llama-api-key` |
| Web Search | SearXNG `http://searxng.app-ai-web.svc.cluster.local:8080/search?q=<query>`, 5 results, 20k chars; loader **Playwright** `ws://playwright.app-ai-web.svc.cluster.local:3000` (not "Default", which fetches outside the sandbox) |
| Documents | Embedding model by path `/app/backend/data/models/paraphrase-multilingual-MiniLM-L12-v2` (by repo name it fills the PVC) |
| Interface | Task model Reasoning Effort `none` |
| Integrations | MCP `browser` → `http://playwright-mcp.app-ai-browser.svc.cluster.local:8931/mcp`; MCP `my-chrome` → `http://192.168.178.81:8932/mcp` (Bearer). Both admin only, filter list `browser_navigate,browser_navigate_back,browser_snapshot,browser_find,browser_click,browser_type,browser_fill_form,browser_select_option,browser_press_key,browser_hover,browser_wait_for,browser_tabs` |
| Chats | Tool permissions on; my mode **Full access** (+ menu) |
| Workspace > Models | `browser-agent` and `my-chrome-agent`: only their MCP tool, built-in tools off, page text treated as data |

## Safety

- Sandboxes (`app-ai-web`, `app-ai-browser`): public internet only, ingress only from Open WebUI, Pod Security `restricted`.
- Open WebUI egress: Postgres, the sandboxes, the laptop and Cloudflare HTTPS (for login) only.
- Relies on Flannel NetworkPolicy enforcement (fail-open; alerts go to ntfy).
- The MCP filter list hides `browser_run_code_unsafe` and any new tools.
- Sandbox sites allowlist: `--allowed-origins` in `playwright-mcp.yaml` (public test sites only; private sites go in the My Chrome list on the laptop).
- My Chrome: key proxy, ufw (Talos nodes only), Connect click per message. Allowed sites: `~/.config/local-ai/allowed-origins` on the laptop, one origin per line, not in Git (no file = every site, empty file = none). `llm chrome on` reloads it.
- No community Open WebUI tools/functions.

## Decisions

- Flannel enforcement, not Cilium.
- Access + Authentik.
- Local model only.
- Open WebUI as the harness.
- Full access until approval works.
- My Chrome uses my own profile.
- **No workarounds to make Qwen do tasks it can't** (long pages, long flows); security measures stay.

## Limits and fixes

- Each chat turn is a new browser session: put the whole task in one message.
- Long pages exceed the 64k context: not a bug.
- `ERR_BLOCKED_BY_CLIENT`: the site isn't on the allowlist.
- Stalls on "Executing..." after Allow: the 0.11.4 approval bug.
- Login breaks after a while: Cloudflare IP ranges changed (update `networkpolicy.yaml`).
- Authentik login fails after a change: restart Authentik after `authentik-env` refreshes.

## Upgrading

- **Open WebUI:** bump the Playwright image in `ai-web/playwright.yaml` to match its `playwright` package.
- **llama.cpp:** new release folder, update `BIN` in `run.sh` (both copies).
- **Laptop MCP:** `npm install --prefix ~/code/ew/local-ai/browser-mcp @playwright/mcp@<version>`, copy `package*.json` here.
- **Rotating the API key:** change the laptop file and Bitwarden, then restart Open WebUI after the ExternalSecret refreshes.

## Open items

- Re-test "Ask for approval" on the next Open WebUI release.
- Log out and in once (Authentik with Cloudflare-only egress).
- Maybe later: an extension token for My Chrome, on whitelisted sites only, in a Chrome used only for the agent. First confirm the allowed-origins file blocks other sites in extension mode (untested).
- Phase 6 (designed): mail/task assistant, read-only IMAP, drafts only, never mixed with browsing.
- Phase 7: image input (`mmproj`), retry Odysseus.
