@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-native.ps1"
echo.
if errorlevel 1 (echo Native build failed.) else (echo Native build finished successfully.)
pause
