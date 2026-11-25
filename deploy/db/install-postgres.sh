#!/usr/bin/env bash
# Instalasi PostgreSQL + skema SKCK & Izin Keramaian (Ubuntu/Debian).
#
# Pemakaian (di VM, lewat SSH):
#   sudo bash install-postgres.sh                     # pasang, buat DB, terapkan skema
#   sudo bash install-postgres.sh --with-sample       # + data contoh (User Uji)
#   sudo ALLOW_CIDR=10.20.0.0/16 bash install-postgres.sh   # izinkan koneksi dari jaringan itu
#
# Default: PostgreSQL hanya mendengar di localhost. Akses dari laptop lewat SSH tunnel:
#   ssh -N -L 5432:127.0.0.1:5432 user@IP-VM
#
# Kredensial disimpan di /etc/docs-super-apps/db.env (root, mode 600).
# Aman dijalankan ulang: password tidak diganti, skema hanya ditambah/diperbarui.

set -euo pipefail

DB_NAME="${DB_NAME:-skck}"
DB_USER="${DB_USER:-skck_app}"
DB_PORT="${DB_PORT:-5432}"
ALLOW_CIDR="${ALLOW_CIDR:-}"             # kosong = hanya localhost
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/filbertumbawa15/docs-super-apps/main/deploy/db}"
ENV_DIR="/etc/docs-super-apps"
ENV_FILE="$ENV_DIR/db.env"
WITH_SAMPLE=0
for a in "$@"; do
  case "$a" in
    --with-sample) WITH_SAMPLE=1 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "Opsi tidak dikenal: $a"; exit 1 ;;
  esac
done

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[GAGAL]\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. Pemeriksaan awal --------------------------------------------------------
[[ $EUID -eq 0 ]] || fail "Jalankan dengan sudo: sudo bash $0"
command -v apt-get >/dev/null 2>&1 || fail "Script ini untuk Ubuntu/Debian (butuh apt-get)."
[[ "$DB_NAME" =~ ^[a-z_][a-z0-9_]*$ && "$DB_USER" =~ ^[a-z_][a-z0-9_]*$ ]] || fail "DB_NAME/DB_USER hanya huruf kecil, angka, garis bawah."
if [[ -n "$ALLOW_CIDR" ]]; then
  [[ "$ALLOW_CIDR" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]] || fail "ALLOW_CIDR tidak valid, contoh: 10.20.0.0/16"
  [[ "$ALLOW_CIDR" != "0.0.0.0/0" ]] || fail "ALLOW_CIDR=0.0.0.0/0 membuka database ke seluruh internet. Pakai jaringan yang spesifik."
fi

# --- 2. Pasang PostgreSQL --------------------------------------------------------
if ! command -v psql >/dev/null 2>&1 || ! ls /usr/lib/postgresql/*/bin/postgres >/dev/null 2>&1; then
  info "Memasang PostgreSQL"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq postgresql postgresql-contrib openssl curl
fi
command -v openssl >/dev/null 2>&1 || apt-get install -y -qq openssl
command -v curl    >/dev/null 2>&1 || apt-get install -y -qq curl
PG_VER="$(ls /usr/lib/postgresql | sort -V | tail -n1)"
PG_CONF_DIR="/etc/postgresql/${PG_VER}/main"
[[ -d "$PG_CONF_DIR" ]] || fail "Konfigurasi PostgreSQL tidak ditemukan di $PG_CONF_DIR"
ok "PostgreSQL ${PG_VER} terpasang"

start_pg() {
  if command -v systemctl >/dev/null 2>&1 && systemctl list-units >/dev/null 2>&1; then
    systemctl enable --now postgresql >/dev/null 2>&1 || true
    systemctl restart postgresql
  else
    pg_ctlcluster "$PG_VER" main restart 2>/dev/null || pg_ctlcluster "$PG_VER" main start
  fi
}

# --- 3. Konfigurasi jaringan & keamanan -------------------------------------------
PG_CONF="$PG_CONF_DIR/postgresql.conf"
HBA="$PG_CONF_DIR/pg_hba.conf"
MARK="# docs-super-apps"

set_conf() { # set_conf key value
  if grep -qE "^[#[:space:]]*$1[[:space:]]*=" "$PG_CONF"; then
    sed -i -E "s|^[#[:space:]]*($1)[[:space:]]*=.*|\1 = $2|" "$PG_CONF"
  else
    echo "$1 = $2" >>"$PG_CONF"
  fi
}
set_conf password_encryption "'scram-sha-256'"
set_conf port "$DB_PORT"
if [[ -n "$ALLOW_CIDR" ]]; then
  set_conf listen_addresses "'*'"
else
  set_conf listen_addresses "'localhost'"
fi

# Aturan pg_hba milik script ini selalu ditulis ulang
sed -i "/${MARK}/d" "$HBA"
{
  echo "host    ${DB_NAME}    ${DB_USER}    127.0.0.1/32    scram-sha-256    ${MARK}"
  echo "host    ${DB_NAME}    ${DB_USER}    ::1/128         scram-sha-256    ${MARK}"
  [[ -n "$ALLOW_CIDR" ]] && echo "host    ${DB_NAME}    ${DB_USER}    ${ALLOW_CIDR}    scram-sha-256    ${MARK}"
} >>"$HBA"
start_pg
for _ in $(seq 1 20); do runuser -u postgres -- pg_isready -q -p "$DB_PORT" && break; sleep 0.5; done
runuser -u postgres -- pg_isready -q -p "$DB_PORT" || fail "PostgreSQL tidak bisa dijalankan. Cek: journalctl -u postgresql"
if [[ -n "$ALLOW_CIDR" ]]; then SCOPE="localhost + $ALLOW_CIDR"; else SCOPE="hanya localhost"; fi
ok "PostgreSQL berjalan di port ${DB_PORT} (${SCOPE})"

PSQL=(runuser -u postgres -- psql -X -q -v ON_ERROR_STOP=1 -p "$DB_PORT")

# --- 4. User & database ------------------------------------------------------------
install -d -m 700 "$ENV_DIR"
DB_PASS=""
[[ -f "$ENV_FILE" ]] && DB_PASS="$(sed -n 's/^DB_PASSWORD=//p' "$ENV_FILE" | tr -d '"')"
if [[ -z "$DB_PASS" ]]; then
  DB_PASS="$(openssl rand -base64 36 | tr -dc 'A-Za-z0-9' | head -c 32)"
  NEW_PASS=1
else
  NEW_PASS=0
fi

if [[ "$("${PSQL[@]}" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'")" != "1" ]]; then
  "${PSQL[@]}" -c "CREATE ROLE ${DB_USER} LOGIN" >/dev/null
fi
# Password lewat variabel psql (tidak muncul di daftar proses)
"${PSQL[@]}" -v pw="$DB_PASS" <<SQL >/dev/null
ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD :'pw';
SQL
if [[ "$("${PSQL[@]}" -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")" != "1" ]]; then
  "${PSQL[@]}" -c "CREATE DATABASE ${DB_NAME} OWNER postgres ENCODING 'UTF8' TEMPLATE template0" >/dev/null
fi
"${PSQL[@]}" -d "$DB_NAME" -c "REVOKE ALL ON DATABASE ${DB_NAME} FROM PUBLIC; GRANT CONNECT, TEMPORARY ON DATABASE ${DB_NAME} TO ${DB_USER}; REVOKE CREATE ON SCHEMA public FROM PUBLIC;" >/dev/null

umask 077
cat >"$ENV_FILE" <<EOF
# Koneksi database docs-super-apps. Jangan di-commit.
DB_HOST="127.0.0.1"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASS}"
DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:${DB_PORT}/${DB_NAME}"
EOF
chmod 600 "$ENV_FILE"
umask 022
ok "Database '${DB_NAME}' dan user '${DB_USER}' siap$([[ $NEW_PASS -eq 1 ]] && echo ' (password baru dibuat)')"

# --- 5. Skema ----------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
fetch() { # fetch nama-file -> path
  if [[ -f "$HERE/$1" ]]; then cp "$HERE/$1" "$WORK/$1"
  else curl -fsSL "$REPO_RAW/$1" -o "$WORK/$1" || fail "Gagal mengunduh $1 dari $REPO_RAW"
  fi
  chmod 644 "$WORK/$1"; chmod 755 "$WORK"
}
fetch schema.sql
info "Menerapkan skema"
"${PSQL[@]}" -d "$DB_NAME" -v app_user="$DB_USER" -f "$WORK/schema.sql" >/dev/null
ok "Skema 'layanan' diterapkan"

if [[ $WITH_SAMPLE -eq 1 ]]; then
  fetch sample-data.sql
  "${PSQL[@]}" -d "$DB_NAME" -f "$WORK/sample-data.sql" >/dev/null
  ok "Data contoh dimasukkan (NIK 0000000000000001)"
fi

# --- 6. Firewall --------------------------------------------------------------------
if [[ -n "$ALLOW_CIDR" ]] && command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow from "$ALLOW_CIDR" to any port "$DB_PORT" proto tcp >/dev/null
  ok "UFW: port ${DB_PORT} dibuka hanya untuk ${ALLOW_CIDR}"
fi

# --- 7. Uji koneksi sebagai user aplikasi -------------------------------------------
TABLES="$(PGPASSWORD="$DB_PASS" psql -X -h 127.0.0.1 -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc \
  "SELECT string_agg(table_name, ', ' ORDER BY table_name) FROM information_schema.tables WHERE table_schema='layanan' AND table_type='BASE TABLE'")" \
  || fail "User aplikasi tidak bisa terhubung. Periksa $HBA"
ok "Uji koneksi berhasil. Tabel: ${TABLES}"

echo
ok "Selesai."
echo "  Kredensial    : sudo cat ${ENV_FILE}"
echo "  Masuk psql    : sudo -u postgres psql -d ${DB_NAME}"
echo "  Coba lookup   : sudo -u postgres psql -d ${DB_NAME} -c \"SELECT layanan.lookup('0000000000000001')\""
if [[ -z "$ALLOW_CIDR" ]]; then
  echo "  Dari laptop   : ssh -N -L ${DB_PORT}:127.0.0.1:${DB_PORT} ${SUDO_USER:-ubuntu}@IP-VM   lalu host=127.0.0.1"
fi
