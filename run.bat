@echo off
setlocal
cd /d "%~dp0"

echo Starting Qlik Sense Impersonator...
echo Once running, open https://localhost:3090/ in your browser.
echo Press Ctrl+C in this window to stop.
echo.

start "" "https://localhost:3090/"
node server.js

echo.
echo Qlik Sense Impersonator stopped.
pause
