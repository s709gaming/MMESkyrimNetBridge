@echo off
setlocal
pushd "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-package.ps1"
set "MME_BUILD_EXIT=%ERRORLEVEL%"

if not "%MME_BUILD_EXIT%"=="0" (
    echo.
    echo MME Extensions package build FAILED with exit code %MME_BUILD_EXIT%.
) else (
    echo.
    echo Latest package: "%~dp0dist\MME Extensions.zip"
)

popd
pause
exit /b %MME_BUILD_EXIT%
