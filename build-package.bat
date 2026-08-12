@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-package.ps1"
pause