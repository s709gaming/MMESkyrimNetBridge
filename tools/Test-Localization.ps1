$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& python -B (Join-Path $root 'tools/test_localization.py')
if ($LASTEXITCODE) { throw 'Russian installer/data contracts failed' }
$out = Join-Path $root 'build/diagnostics/localization-tests'
New-Item -ItemType Directory -Force $out | Out-Null
$include = Join-Path $root 'build/native-release/vcpkg_installed/x64-windows-static-md/include'
$exe = Join-Path $out 'localization.exe'
Push-Location $out
try {
    & cmd.exe /d /s /c "`"E:/Visual Studio/Common7/Tools/VsDevCmd.bat`" -arch=x64 -host_arch=x64 >nul && cl.exe /nologo /std:c++latest /utf-8 /EHsc /W4 /WX /DNOMINMAX /I`"$include`" `"$root/tools/test_localization.cpp`" `"$root/src/NarrationStore.cpp`" /Fe:`"$exe`" /link bcrypt.lib"
    if ($LASTEXITCODE) { throw 'Localization native test compile failed' }
    & $exe (Join-Path $root 'fomod/choices/russian/core/SKSE/Plugins/StorageUtilData/MMEAlerts/Localization') (Join-Path $out ([guid]::NewGuid().ToString('N')))
    if ($LASTEXITCODE) { throw 'Localization fallback/personal-text tests failed' }
} finally { Pop-Location }
