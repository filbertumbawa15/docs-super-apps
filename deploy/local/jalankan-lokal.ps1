# Jalankan Dokumentasi SKCK di localhost dalam satu langkah (Windows).
#
#   powershell -ExecutionPolicy Bypass -File jalankan-lokal.ps1
#   powershell -ExecutionPolicy Bypass -File jalankan-lokal.ps1 -Reconfig
#
# Butuh: Git, Node.js 18+, dan GlobalProtect aktif.
param([switch]$Reconfig)
$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/filbertumbawa15/docs-super-apps.git'
$AppDir  = if ($env:APP_DIR) { $env:APP_DIR } else { Join-Path $HOME 'docs-super-apps' }

function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[GAGAL] $m" -ForegroundColor Red; Read-Host 'Tekan Enter untuk keluar' | Out-Null; exit 1 }

# 1. Prasyarat
if (-not (Get-Command git -ErrorAction SilentlyContinue))  { Fail 'Git belum terpasang. Unduh dari https://git-scm.com' }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Fail 'Node.js belum terpasang. Pasang Node 18+ dari https://nodejs.org' }
$nodeMajor = [int](node -p "process.versions.node.split('.')[0]")
if ($nodeMajor -lt 18) { Fail "Butuh Node.js 18+, terpasang $(node -v)" }

# 2. Ambil / perbarui kode
if (Test-Path (Join-Path $AppDir '.git')) {
  Info "Memperbarui kode di $AppDir"
  git -C $AppDir pull --ff-only --quiet
  if ($LASTEXITCODE -ne 0) { Warn 'Gagal memperbarui; memakai versi yang ada.' }
} else {
  Info "Mengambil kode ke $AppDir"
  git clone --quiet --depth 1 $RepoUrl $AppDir
  if ($LASTEXITCODE -ne 0) { Fail 'Gagal mengambil kode dari GitHub.' }
}
Set-Location $AppDir
Ok "Kode: $(git log -1 --format='%h %s')"

# 3. Konfigurasi .env
$EnvFile = Join-Path $AppDir '.env'
function Get-EnvValue($key) {
  if (-not (Test-Path $EnvFile)) { return '' }
  $line = Get-Content $EnvFile | Where-Object { $_ -match "^$key=" } | Select-Object -Last 1
  if ($line) { return ($line -replace "^$key=", '').Trim('"') } else { return '' }
}
if (-not (Test-Path $EnvFile) -or $Reconfig) {
  Info "Isi konfigurasi API (disimpan di $EnvFile). Tekan Enter untuk memakai nilai lama."
  $oldHost = Get-EnvValue 'API_HOST'; $oldApp = Get-EnvValue 'APP_ID'; $oldKey = Get-EnvValue 'ACCESS_KEY'
  $h = Read-Host "  Host API [$(if ($oldHost) { $oldHost } else { 'mis. http://10.0.0.1/admin-be' })]"
  if (-not $h) { $h = $oldHost }
  $a = Read-Host "  App-Id$(if ($oldApp) { ' [tetap yang lama]' })"
  if (-not $a) { $a = $oldApp }
  $sec = Read-Host "  Access-Key (tidak ditampilkan$(if ($oldKey) { '; Enter = tetap yang lama' }))" -AsSecureString
  $k = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
  if (-not $k) { $k = $oldKey }
  $h = $h.TrimEnd('/')
  if ($h -notmatch '^https?://' -or -not $a -or -not $k) { Fail 'Host (http/https), App-Id, dan Access-Key wajib diisi.' }
  @("API_HOST=""$h""", "APP_ID=""$a""", "ACCESS_KEY=""$k""", 'INSECURE_TLS="true"', 'PORT="5173"') |
    Set-Content -Path $EnvFile -Encoding ASCII
  Ok 'Konfigurasi disimpan'
}
$Port = Get-EnvValue 'PORT'; if (-not $Port) { $Port = '5173' }

# 4. Kosongkan port
$conns = Get-NetTCPConnection -LocalPort ([int]$Port) -State Listen -ErrorAction SilentlyContinue
if ($conns) {
  Warn "Port $Port sedang dipakai oleh:"
  $conns | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object {
    $p = Get-Process -Id $_ -ErrorAction SilentlyContinue
    Write-Host "  PID $_ $($p.ProcessName)"
  }
  $y = Read-Host '  Hentikan program tersebut? [y/N]'
  if ($y -match '^[Yy]$') {
    $conns | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 1
    Ok "Port $Port dikosongkan"
  } else {
    Fail "Port $Port masih dipakai. Hentikan dulu programnya, lalu jalankan ulang."
  }
}

# 5. Buka browser setelah server siap
$url = "http://localhost:$Port/data.html"
Start-Job -ScriptBlock {
  param($port, $url)
  for ($i = 0; $i -lt 20; $i++) {
    try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 "http://127.0.0.1:$port/" | Out-Null; Start-Process $url; return } catch { Start-Sleep -Milliseconds 500 }
  }
} -ArgumentList $Port, $url | Out-Null

# 6. Jalankan server (Ctrl+C untuk berhenti)
node deploy/local/server.js
