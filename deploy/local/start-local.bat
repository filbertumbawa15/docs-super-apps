@echo off
rem Jalankan docs-super-apps di localhost (Windows).
setlocal
cd /d "%~dp0..\.."

where node >nul 2>nul
if errorlevel 1 (
  echo [GAGAL] Node.js belum terpasang. Pasang Node 18+ dari https://nodejs.org
  pause
  exit /b 1
)

if not exist ".env" (
  copy "deploy\local\.env.example" ".env" >nul
  echo File .env dibuat. Isi API_HOST, APP_ID, dan ACCESS_KEY, simpan, lalu tutup Notepad.
  notepad ".env"
)

node deploy\local\server.js
pause
