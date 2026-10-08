#!/usr/bin/env bash
# Start or stop the local model for ai.erasmus.works. Linked into ~/.local/bin as `llm`;
# also used by the "Start local AI" / "Stop local AI" desktop shortcuts.
#   llm                start the model and follow its log here; Ctrl+C stops everything again
#                      (if the model was already running, Ctrl+C only stops following the log)
#   llm chrome         same, plus the "Browser (my Chrome)" agent (Ctrl+C stops both)
#   llm -d             start in the background, return once the model answers (llm chrome -d too)
#   llm stop           stop the model and the My Chrome agent
#   llm chrome on|off  start (or restart, to reload its allowed sites) or stop only the My Chrome agent
#   llm status         show whether the model and the My Chrome agent are running
#   llm -h             this help
set -euo pipefail

HEALTH=http://127.0.0.1:8080/health
WAIT_SECONDS=180
CHROME_UNITS=(browser-mcp browser-mcp-auth)

say() {
  echo "$1"
  notify-send --app-name "Local AI" --icon "${2:-dialog-information}" "Local AI" "$1" 2>/dev/null || true
}

healthy() { curl -sf --max-time 2 "$HEALTH" | grep -q '"ok"'; }

wait_ready() {
  echo -n "Loading the model"
  for ((i = 0; i < WAIT_SECONDS; i += 2)); do
    if healthy; then
      echo
      say "The model is ready at ai.erasmus.works (took ~${i}s)." emblem-ok-symbolic
      return
    fi
    if ! systemctl --user is-active --quiet llama-server; then
      echo
      say "llama-server stopped while loading. See: journalctl --user -u llama-server -n 50" dialog-error
      exit 1
    fi
    echo -n "."
    sleep 2
  done
  echo
  say "The model didn't answer within ${WAIT_SECONDS}s. See: journalctl --user -u llama-server -n 50" dialog-error
  exit 1
}

stop() {
  systemctl --user stop llama-server "${CHROME_UNITS[@]}"
  say "The model is stopped; the GPU is free."
}

chrome_status() {
  local u
  for u in "${CHROME_UNITS[@]}"; do
    systemctl --user is-active --quiet "$u" || { echo "My Chrome agent: off"; return; }
  done
  echo "My Chrome agent: on"
}

if [[ "${1:-}" == chrome && ( "${2:-}" == on || "${2:-}" == off ) ]]; then
  if [[ "$2" == on ]]; then
    systemctl --user restart "${CHROME_UNITS[@]}"; say "My Chrome agent is on."
  else
    systemctl --user stop "${CHROME_UNITS[@]}"; say "My Chrome agent is off."
  fi
  exit 0
fi

detach=false
chrome=false
for arg in "$@"; do
  case "$arg" in
    -d | --detach) detach=true ;;
    chrome) chrome=true ;;
    stop) stop; exit 0 ;;
    status)
      if healthy; then echo "Model: ready"
      elif systemctl --user is-active --quiet llama-server; then echo "Model: loading"
      else echo "Model: off"; fi
      chrome_status; exit 0 ;;
    -h | --help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg (try llm -h)"; exit 2 ;;
  esac
done

units=(llama-server)
if $chrome; then
  systemctl --user start "${CHROME_UNITS[@]}"
  units+=("${CHROME_UNITS[@]}")
fi
unit_args=()
for u in "${units[@]}"; do unit_args+=(-u "$u"); done

already=false
systemctl --user is-active --quiet llama-server && already=true

if $detach; then
  $already || systemctl --user start llama-server
  if $already && healthy; then say "The model is already running."; else wait_ready; fi
  exit 0
fi

if $already; then
  echo "llama-server was already running; Ctrl+C stops following the log, the model keeps running."
  exec journalctl --user "${unit_args[@]}" -f -n 20 --output=cat
fi

echo "Following the log; Ctrl+C stops the model (use llm -d to keep it running in the background)."
# Follow first (no old lines), then start, so the log shows this start from the beginning.
journalctl --user "${unit_args[@]}" -f -n 0 --output=cat &
log_pid=$!
trap 'kill "$log_pid" 2>/dev/null; echo; stop; exit 0' INT TERM
systemctl --user start llama-server
# wait returns early when a signal arrives, so loop until the log follower is really gone
while kill -0 "$log_pid" 2>/dev/null; do wait "$log_pid" || true; done
