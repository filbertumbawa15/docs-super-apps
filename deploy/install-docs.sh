#!/usr/bin/env bash
# Instalasi / pembaruan situs dokumentasi docs-super-apps di VPS (Ubuntu/Debian).
# Menyajikan file statis lewat Nginx di port khusus (default 5173).
#
# Konfigurasi API (host, App-Id, Access-Key) dibaca dari file ENV di server:
#   /etc/docs-super-apps/docs.env   (pemilik root, mode 600)
# Kalau file itu belum ada, script menanyakan nilainya sekali lalu menyimpannya.
# Dari ENV itu script membuat assets/config.js yang dipakai data.html.
#
# Pemakaian:
#   sudo bash install-docs.sh              # instal atau perbarui
#   sudo bash install-docs.sh --reconfig   # isi ulang file ENV
#
# Aman dijalankan ulang.

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/filbertumbawa15/docs-super-apps.git}"
BRANCH="${BRANCH:-main}"
APP_DIR="${APP_DIR:-/var/www/docs-super-apps}"
PORT="${PORT:-5173}"
SITE_NAME="docs-super-apps"
ENV_DIR="/etc/${SITE_NAME}"
ENV_FILE="${ENV_DIR}/docs.env"
HTPASSWD="/etc/nginx/.htpasswd-${SITE_NAME}"
NGINX_CONF="/etc/nginx/sites-available/${SITE_NAME}"
RECONFIG=0
[[ "${1:-}" == "--reconfig" ]] && RECONFIG=1

info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31m[GAGAL]\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. Pemeriksaan awal -------------------------------------------------------
[[ $EUID -eq 0 ]] || fail "Jalankan dengan sudo: sudo bash $0"
command -v apt-get >/dev/null 2>&1 || fail "Script ini untuk Ubuntu/Debian (butuh apt-get)."
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )) || fail "PORT tidak valid: $PORT"

# --- 2. Paket ------------------------------------------------------------------
NEED=()
command -v nginx   >/dev/null 2>&1 || NEED+=(nginx)
command -v git     >/dev/null 2>&1 || NEED+=(git)
command -v curl    >/dev/null 2>&1 || NEED+=(curl)
command -v openssl >/dev/null 2>&1 || NEED+=(openssl)
if ((${#NEED[@]})); then
  info "Memasang paket: ${NEED[*]}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq "${NEED[@]}"
fi
ok "Paket tersedia"

# --- 3. Cek port tidak dipakai program lain ------------------------------------
if command -v ss >/dev/null 2>&1; then
  USERS="$(ss -ltnpH "sport = :${PORT}" 2>/dev/null || true)"
  if [[ -n "$USERS" ]] && ! grep -q nginx <<<"$USERS"; then
    echo "$USERS"
    fail "Port ${PORT} sudah dipakai program lain. Pilih port lain, mis. sudo PORT=5174 bash $0"
  fi
fi

# --- 4. File ENV ---------------------------------------------------------------
env_get() { # baca KEY=VALUE tanpa mengeksekusi isi file
  local key="$1"
  [[ -f "$ENV_FILE" ]] || return 0
  sed -n "s/^${key}=//p" "$ENV_FILE" | tail -n1 | sed -e 's/^"//' -e 's/"$//'
}

if [[ ! -f "$ENV_FILE" || $RECONFIG -eq 1 ]]; then
  [[ -t 0 ]] || fail "File ENV $ENV_FILE belum ada. Jalankan script ini secara interaktif sekali untuk mengisinya."
  info "Mengisi konfigurasi API (disimpan di $ENV_FILE, hanya bisa dibaca root)"
  OLD_HOST="$(env_get API_HOST)"; OLD_APP="$(env_get APP_ID)"; OLD_USER="$(env_get BASIC_AUTH_USER)"
  read -r -p "  Host API [${OLD_HOST:-contoh: https://10.0.0.1/admin-be}]: " IN_HOST
  IN_HOST="${IN_HOST:-$OLD_HOST}"
  read -r -p "  App-Id${OLD_APP:+ [tetap yang lama]}: " IN_APP
  IN_APP="${IN_APP:-$OLD_APP}"
  read -r -s -p "  Access-Key (tidak ditampilkan; kosongkan untuk tetap yang lama): " IN_KEY; echo
  IN_KEY="${IN_KEY:-$(env_get ACCESS_KEY)}"
  echo "  Login halaman sangat disarankan, karena Access-Key ikut terkirim ke browser."
  read -r -p "  Username login halaman [${OLD_USER:-kosongkan = tanpa login}]: " IN_USER
  IN_USER="${IN_USER:-$OLD_USER}"
  IN_PASS=""
  if [[ -n "$IN_USER" ]]; then
    read -r -s -p "  Password login (kosongkan untuk tetap yang lama): " IN_PASS; echo
    [[ -n "$IN_PASS" || -f "$HTPASSWD" ]] || fail "Password login wajib diisi saat pertama kali."
  fi

  IN_HOST="${IN_HOST%/}"
  [[ "$IN_HOST" =~ ^https?:// ]] || fail "Host API harus diawali http:// atau https://"
  [[ -n "$IN_APP" && -n "$IN_KEY" ]] || fail "App-Id dan Access-Key wajib diisi."
  for v in "$IN_HOST" "$IN_APP" "$IN_KEY" "$IN_USER"; do
    [[ "$v" != *$'\n'* && "$v" != *'"'* && "$v" != *'\'* ]] || fail "Nilai tidak boleh mengandung tanda kutip, backslash, atau baris baru."
  done

  install -d -m 700 "$ENV_DIR"
  umask 077
  cat >"$ENV_FILE" <<EOF
# Konfigurasi docs-super-apps. Jangan di-commit ke git.
API_HOST="${IN_HOST}"
APP_ID="${IN_APP}"
ACCESS_KEY="${IN_KEY}"
BASIC_AUTH_USER="${IN_USER}"
EOF
  chmod 600 "$ENV_FILE"

  if [[ -n "$IN_USER" && -n "$IN_PASS" ]]; then
    printf '%s:%s\n' "$IN_USER" "$(openssl passwd -apr1 "$IN_PASS")" >"$HTPASSWD"
  elif [[ -z "$IN_USER" ]]; then
    rm -f "$HTPASSWD"
  fi
  umask 022
  ok "File ENV disimpan: $ENV_FILE"
fi

API_HOST="$(env_get API_HOST)"
APP_ID="$(env_get APP_ID)"
ACCESS_KEY="$(env_get ACCESS_KEY)"
BASIC_AUTH_USER="$(env_get BASIC_AUTH_USER)"
[[ -n "$API_HOST" && -n "$APP_ID" && -n "$ACCESS_KEY" ]] || fail "ENV belum lengkap. Jalankan: sudo bash $0 --reconfig"

# --- 5. Ambil / perbarui kode --------------------------------------------------
if [[ -d "$APP_DIR/.git" ]]; then
  info "Memperbarui kode di $APP_DIR (branch $BRANCH)"
  git -C "$APP_DIR" fetch --depth 1 origin "$BRANCH"
  git -C "$APP_DIR" reset --hard "origin/$BRANCH"
elif [[ -e "$APP_DIR" && -n "$(ls -A "$APP_DIR" 2>/dev/null)" ]]; then
  fail "$APP_DIR sudah ada dan bukan repo git. Pindahkan dulu atau set APP_DIR lain."
else
  info "Meng-clone $REPO_URL ke $APP_DIR"
  mkdir -p "$(dirname "$APP_DIR")"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi
[[ -f "$APP_DIR/index.html" ]] || fail "index.html tidak ditemukan di $APP_DIR"
ok "Kode siap: $(git -C "$APP_DIR" log -1 --format='%h %s')"

# --- 6. Buat assets/config.js dari ENV -----------------------------------------
cat >"$APP_DIR/assets/config.js" <<EOF
// Dibuat otomatis oleh install-docs.sh dari ${ENV_FILE}. Jangan diedit / di-commit.
window.APP_CONFIG = {
  apiHost: "${API_HOST}",
  appId: "${APP_ID}",
  accessKey: "${ACCESS_KEY}"
};
EOF
chmod -R a+rX "$APP_DIR"
ok "assets/config.js dibuat dari ENV (host: ${API_HOST})"

# --- 7. Konfigurasi Nginx ------------------------------------------------------
AUTH_BLOCK="    # Tanpa login (BASIC_AUTH_USER kosong)"
if [[ -n "$BASIC_AUTH_USER" && -f "$HTPASSWD" ]]; then
  chown root:www-data "$HTPASSWD" 2>/dev/null || true
  chmod 640 "$HTPASSWD"
  AUTH_BLOCK="    auth_basic \"Docs Super Apps\";
    auth_basic_user_file ${HTPASSWD};"
fi

info "Menulis konfigurasi Nginx: $NGINX_CONF"
cat >"$NGINX_CONF" <<EOF
# Dikelola oleh install-docs.sh; perubahan manual akan tertimpa saat script dijalankan ulang.
server {
    listen ${PORT};
    listen [::]:${PORT};
    server_name _;

    root ${APP_DIR};
    index index.html;
    charset utf-8;

${AUTH_BLOCK}

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header Referrer-Policy no-referrer always;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location = /assets/config.js {
        add_header Cache-Control "no-store" always;
        add_header X-Content-Type-Options nosniff always;
    }

    location /assets/ {
        expires 7d;
        add_header Cache-Control "public";
    }

    # Jangan sajikan file tersembunyi (.git, .env, dll.) dan file non-situs
    location ~ /\. { deny all; return 404; }
    location ~* \.(sh|md|example)$ { deny all; return 404; }
    location ^~ /deploy/ { deny all; return 404; }

    access_log /var/log/nginx/${SITE_NAME}.access.log;
    error_log  /var/log/nginx/${SITE_NAME}.error.log;
}
EOF
ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/${SITE_NAME}"

nginx -t || fail "Konfigurasi Nginx tidak valid. Periksa pesan di atas."
systemctl enable --now nginx >/dev/null 2>&1 || true
systemctl reload nginx
ok "Nginx dimuat ulang"

# --- 8. Firewall ---------------------------------------------------------------
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow "${PORT}/tcp" >/dev/null
  ok "UFW: port ${PORT}/tcp dibuka"
else
  warn "UFW tidak aktif; lewati pengaturan firewall lokal."
fi

# --- 9. Uji --------------------------------------------------------------------
sleep 1
code() { curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}$1" || true; }
if [[ -n "$BASIC_AUTH_USER" && -f "$HTPASSWD" ]]; then
  C_NOAUTH="$(code /)"
  [[ "$C_NOAUTH" == "401" ]] || warn "Halaman tanpa login seharusnya 401, didapat $C_NOAUTH"
  ok "Login aktif (tanpa login → $C_NOAUTH)"
else
  C_INDEX="$(code /)"; C_DATA="$(code /data.html)"; C_CFG="$(code /assets/config.js)"
  [[ "$C_INDEX" == "200" && "$C_DATA" == "200" && "$C_CFG" == "200" ]] || fail "Uji lokal gagal (index: $C_INDEX, data: $C_DATA, config: $C_CFG). Lihat /var/log/nginx/${SITE_NAME}.error.log"
  ok "Uji lokal berhasil (index.html, data.html, config.js → 200)"
  warn "Halaman TANPA login: siapa pun yang membuka port ${PORT} bisa melihat Access-Key. Aktifkan dengan: sudo bash $0 --reconfig"
fi
C_GIT="$(code /.git/config)"
[[ "$C_GIT" == "404" || "$C_GIT" == "401" ]] || warn "Folder .git bisa diakses (HTTP $C_GIT); periksa konfigurasi."

PUBLIC_IP="$(curl -s --max-time 5 https://api.ipify.org || hostname -I | awk '{print $1}')"
echo
ok "Selesai. Buka:"
echo "    Dokumentasi  : http://${PUBLIC_IP}:${PORT}/"
echo "    Tampilan data: http://${PUBLIC_IP}:${PORT}/data.html"
echo
warn "Kalau tidak bisa dibuka dari luar, buka port ${PORT}/tcp di security group / firewall penyedia VPS."
echo "Perbarui setelah ada push baru : sudo bash $0"
echo "Ganti host / key / login       : sudo bash $0 --reconfig"
