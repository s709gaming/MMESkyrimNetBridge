@echo off
setlocal

rem Run the PowerShell builder from this batch file's own directory.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-package.ps1"

rem Keep the window open so compilation errors or the ZIP path remain visible.
echo.
if errorlevel 1 (
    echo Build failed.
) else (
    echo Build finished successfully.
)
pause
