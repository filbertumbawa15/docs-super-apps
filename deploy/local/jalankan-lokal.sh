#!/usr/bin/env bash
# Jalankan Dokumentasi SKCK di localhost dalam satu langkah (macOS / Linux).
#
#   bash jalankan-lokal.sh              # ambil/perbarui kode, jalankan, buka browser
#   bash jalankan-lokal.sh --reconfig   # isi ulang host / App-Id / Access-Key
#
# Butuh: git, Node.js 18+, dan GlobalProtect aktif.
set -euo pipefail

REPO_URL="https://github.com/filbertumbawa15/docs-super-apps.git"
APP_DIR="${APP_DIR:-$HOME/docs-super-apps}"
PORT="${PORT:-5173}"
RECONFIG=0; [[ "${1:-}" == "--reconfig" ]] && RECONFIG=1

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[GAGAL]\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Prasyarat
command -v git  >/dev/null 2>&1 || fail "Git belum terpasang."
command -v node >/dev/null 2>&1 || fail "Node.js belum terpasang. Pasang Node 18+ dari https://nodejs.org"
(( $(node -p 'process.versions.node.split(".")[0]') >= 18 )) || fail "Butuh Node.js 18+, terpasang $(node -v)"

# 2. Ambil / perbarui kode
if [[ -d "$APP_DIR/.git" ]]; then
  info "Memperbarui kode di $APP_DIR"
  git -C "$APP_DIR" pull --ff-only --quiet || warn "Gagal memperbarui; memakai versi yang ada."
else
  info "Mengambil kode ke $APP_DIR"
  git clone --quiet --depth 1 "$REPO_URL" "$APP_DIR"
fi
cd "$APP_DIR"
ok "Kode: $(git log -1 --format='%h %s')"

# 3. Konfigurasi .env
ENV_FILE="$APP_DIR/.env"
get() { [[ -f "$ENV_FILE" ]] && sed -n "s/^$1=//p" "$ENV_FILE" | tail -n1 | sed -e 's/^"//' -e 's/"$//' || true; }
if [[ ! -f "$ENV_FILE" || $RECONFIG -eq 1 ]]; then
  info "Isi konfigurasi API (disimpan di $ENV_FILE). Tekan Enter untuk memakai nilai lama."
  OLD_HOST="$(get API_HOST)"; OLD_APP="$(get APP_ID)"; OLD_KEY="$(get ACCESS_KEY)"
  read -r -p "  Host API [${OLD_HOST:-mis. http://10.0.0.1/admin-be}]: " H; H="${H:-$OLD_HOST}"
  read -r -p "  App-Id${OLD_APP:+ [tetap yang lama]}: " A; A="${A:-$OLD_APP}"
  read -r -s -p "  Access-Key (tidak ditampilkan${OLD_KEY:+; Enter = tetap yang lama}): " K; echo; K="${K:-$OLD_KEY}"
  H="${H%/}"
  [[ "$H" =~ ^https?:// && -n "$A" && -n "$K" ]] || fail "Host (http/https), App-Id, dan Access-Key wajib diisi."
  ( umask 077; printf 'API_HOST="%s"\nAPP_ID="%s"\nACCESS_KEY="%s"\nINSECURE_TLS="true"\nPORT="%s"\n' "$H" "$A" "$K" "$PORT" >"$ENV_FILE" )
  ok "Konfigurasi disimpan"
fi
PORT="$(get PORT)"; PORT="${PORT:-5173}"

# 4. Kosongkan port
PIDS=""
if command -v lsof >/dev/null 2>&1; then PIDS="$(lsof -t -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
elif command -v fuser >/dev/null 2>&1; then PIDS="$(fuser "$PORT"/tcp 2>/dev/null || true)"; fi
if [[ -n "$PIDS" ]]; then
  warn "Port $PORT sedang dipakai oleh:"
  ps -o pid=,comm= -p $PIDS 2>/dev/null || echo "  PID $PIDS"
  read -r -p "  Hentikan program tersebut? [y/N]: " Y
  if [[ "$Y" =~ ^[Yy]$ ]]; then
    kill $PIDS 2>/dev/null || true; sleep 1
    kill -9 $PIDS 2>/dev/null || true
    ok "Port $PORT dikosongkan"
  else
    fail "Port $PORT masih dipakai. Hentikan dulu programnya, lalu jalankan ulang."
  fi
fi

# 5. Buka browser setelah server siap
URL="http://localhost:$PORT/data.html"
(
  for _ in $(seq 1 20); do
    if curl -s -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; then
      if command -v open >/dev/null 2>&1; then open "$URL"
      elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1
      fi
      exit 0
    fi
    sleep 0.5
  done
) &

# 6. Jalankan server (Ctrl+C untuk berhenti)
exec node deploy/local/server.js
