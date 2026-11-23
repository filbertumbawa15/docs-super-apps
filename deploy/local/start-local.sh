#!/usr/bin/env bash
# Jalankan docs-super-apps di localhost (macOS / Linux).
#   bash deploy/local/start-local.sh             # jalankan
#   bash deploy/local/start-local.sh --reconfig  # isi ulang .env
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT="$(pwd)"
ENV_FILE="$ROOT/.env"

command -v node >/dev/null 2>&1 || { echo "[GAGAL] Node.js belum terpasang. Pasang Node 18+ dari https://nodejs.org"; exit 1; }
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
(( NODE_MAJOR >= 18 )) || { echo "[GAGAL] Butuh Node.js 18+, terpasang $(node -v)"; exit 1; }

get() { [[ -f "$ENV_FILE" ]] && sed -n "s/^$1=//p" "$ENV_FILE" | tail -n1 | sed -e 's/^"//' -e 's/"$//' || true; }

if [[ ! -f "$ENV_FILE" || "${1:-}" == "--reconfig" ]]; then
  echo "Mengisi konfigurasi (.env). Tekan Enter untuk memakai nilai lama."
  OLD_HOST="$(get API_HOST)"; OLD_APP="$(get APP_ID)"; OLD_KEY="$(get ACCESS_KEY)"; OLD_PORT="$(get PORT)"
  read -r -p "  Host API [${OLD_HOST:-https://HOST-API/admin-be}]: " H; H="${H:-$OLD_HOST}"
  read -r -p "  App-Id${OLD_APP:+ [tetap yang lama]}: " A; A="${A:-$OLD_APP}"
  read -r -s -p "  Access-Key (tidak ditampilkan${OLD_KEY:+; Enter = tetap yang lama}): " K; echo; K="${K:-$OLD_KEY}"
  read -r -p "  Port lokal [${OLD_PORT:-5173}]: " P; P="${P:-${OLD_PORT:-5173}}"
  H="${H%/}"
  [[ "$H" =~ ^https?:// && -n "$A" && -n "$K" ]] || { echo "[GAGAL] Host (http/https), App-Id, dan Access-Key wajib diisi."; exit 1; }
  umask 077
  cat >"$ENV_FILE" <<ENV
API_HOST="$H"
APP_ID="$A"
ACCESS_KEY="$K"
INSECURE_TLS="true"
PORT="$P"
ENV
  echo "[ OK ] .env disimpan."
fi

exec node deploy/local/server.js
