#!/bin/bash
# ============================================================
#  Build + deploy Linux/WSL binárky EasyProject MCP serveru
#
#  Spouštět ve WSL:
#     bash /mnt/d/Projekty/Claude/EasyProject-MCP-Server/scripts/build-linux.sh
#
#  Co dělá:
#   1) cargo build --release (target dir v $HOME kvůli rychlosti a
#      aby se nemíchal s Windows buildem ve target/)
#   2) zkopíruje ELF do deployment/easyproject-mcp-server-linux
#   3) ověří, že binárka obsahuje očekávané symboly (easy_sprint_id)
#   4) smoke test: initialize + tools/list přes stdio, vypíše počet nástrojů
#
#  Commit + push řeší scripts/publish-release.ps1
# ============================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/deployment/easyproject-mcp-server-linux"
TARGET_DIR="${CARGO_TARGET_DIR:-$HOME/ep-mcp-target}"
# Symboly, které musí být v každém čerstvém buildu (rozšiřovat s novými featurami)
REQUIRED_SYMBOLS=(easy_sprint_id fixed_version_id download_attachment)

# cargo nemusí být v PATH, pokud skript běží v non-login shellu (wsl.exe bash script.sh)
if ! command -v cargo >/dev/null 2>&1 && [ -f "$HOME/.cargo/env" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
fi
command -v cargo >/dev/null 2>&1 || { echo "CHYBA: cargo není v PATH. Nainstaluj rustup." >&2; exit 1; }

echo "=== 1. cargo build --release ==="
echo "    repo:       $REPO"
echo "    target dir: $TARGET_DIR"
cd "$REPO"
CARGO_TARGET_DIR="$TARGET_DIR" cargo build --release

BIN="$TARGET_DIR/release/easyproject-mcp-server"
if [ ! -f "$BIN" ]; then
  echo "CHYBA: build neprodukoval $BIN" >&2
  exit 1
fi

echo "=== 2. Kopie do deployment/ ==="
cp "$BIN" "$OUT"
chmod +x "$OUT"
ls -la "$OUT"

echo "=== 3. Ověření symbolů ==="
fail=0
for sym in "${REQUIRED_SYMBOLS[@]}"; do
  if grep -qa "$sym" "$OUT"; then
    echo "    OK   $sym"
  else
    echo "    CHYBÍ $sym" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || { echo "CHYBA: binárka neobsahuje očekávané symboly." >&2; exit 1; }

echo "=== 4. Smoke test (stdio initialize + tools/list) ==="
# Dummy klíč — smoke test nevolá API, jen ověří start serveru a registraci nástrojů
tools=$(
  EASYPROJECT_API_KEY=smoketest EASYPROJECT_BASE_URL=https://ep.pdsoft.eu/ \
  timeout 20 "$OUT" 2>/dev/null <<'EOF' | grep -o '"name":"[a-z_]*"' | sort -u | wc -l
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"1"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
EOF
)
echo "    registrovaných nástrojů: $tools"
[ "$tools" -ge 25 ] || { echo "CHYBA: tools/list vrátil jen $tools nástrojů." >&2; exit 1; }

echo
echo "Hotovo. Linux binárka nasazena: $OUT"
echo "Dál: scripts/publish-release.ps1 (commit + push), nebo restart Claude Code ve WSL."
