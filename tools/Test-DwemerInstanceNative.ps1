$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$out=Join-Path $root 'build/diagnostics/dwemer-instance-tests'
New-Item -ItemType Directory -Force $out | Out-Null
$include=Join-Path $root 'build/native-release/vcpkg_installed/x64-windows-static-md/include'
Push-Location $out
try {
 & cmd.exe /d /s /c "`"E:/Visual Studio/Common7/Tools/VsDevCmd.bat`" -arch=x64 -host_arch=x64 >nul && cl.exe /nologo /std:c++20 /utf-8 /EHsc /I`"$include`" /I`"$root/include`" `"$root/tools/test_dwemer_instance_state.cpp`" /Fe:test.exe"
 if($LASTEXITCODE){throw 'Instance state test compile failed'}
 & ./test.exe
 if($LASTEXITCODE){throw 'Instance state tests failed'}
} finally {Pop-Location}
