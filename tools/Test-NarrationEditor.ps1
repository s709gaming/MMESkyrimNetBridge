$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build/diagnostics/lore-editor-tests'
New-Item -ItemType Directory -Force $out | Out-Null
$dev = 'E:/Visual Studio/Common7/Tools/VsDevCmd.bat'
$test = Join-Path $root 'tools/test_narration_store.cpp'
$source = Join-Path $root 'src/NarrationStore.cpp'
$include = Join-Path $root 'build/native-release/vcpkg_installed/x64-windows-static-md/include'
$exe = Join-Path $out 'test_narration_store.exe'
Push-Location $out
try {
    & cmd.exe /d /s /c "`"$dev`" -arch=x64 -host_arch=x64 >nul && cl.exe /nologo /std:c++latest /utf-8 /EHsc /W4 /WX /DNOMINMAX /I`"$include`" `"$test`" `"$source`" /Fe:`"$exe`" /link bcrypt.lib"
    if ($LASTEXITCODE) { throw 'Native narration store test compilation failed' }
    & $exe (Join-Path $out ([guid]::NewGuid().ToString('N')))
    if ($LASTEXITCODE) { throw 'Native narration store tests failed' }
} finally { Pop-Location }
& node (Join-Path $root 'tools/test_maid_roster_page.cjs') (Join-Path $root 'fomod/choices/maid-roster-ui/Magelight/mmeextensions/views/roster/index.html')
if ($LASTEXITCODE) { throw 'Roster/editor page tests failed' }
& node (Join-Path $root 'tools/test_narration_dashboard.cjs')
if ($LASTEXITCODE) { throw 'Narration dashboard tests failed' }
