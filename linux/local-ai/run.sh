#!/usr/bin/env bash
# Start Qwen3.6-35B-A3B with llama.cpp (CUDA). OpenAI-compatible API on port 8080, all interfaces.
# ufw only admits the cluster (192.168.20.0/24); every request needs the key in ~/.config/local-ai/api-key.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/llama.cpp/llama-b11468"

export LD_LIBRARY_PATH="$BIN${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$BIN/llama-server" \
  -m "$DIR/models/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf" \
  --alias qwen3.6-35b-a3b \
  --fit on \
  -c 65536 \
  -b 4096 -ub 4096 \
  -fa on \
  --jinja \
  --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0 \
  --host 0.0.0.0 --port 8080 \
  --api-key-file "$HOME/.config/local-ai/api-key" \
  --no-webui \
  "$@"
