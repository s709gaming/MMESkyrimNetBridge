$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root 'build/diagnostics/movement-responsive'
New-Item -ItemType Directory -Force $output | Out-Null
$batch = Join-Path $output 'test-native.cmd'
@"
@echo off
call "E:\Visual Studio\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64 >nul
if errorlevel 1 exit /b 1
cl /nologo /std:c++20 /EHsc /W4 /WX "$root\tools\test_movement_playback.cpp" /Fo"$output\policy.obj" /Fe"$output\policy.exe"
if errorlevel 1 exit /b 1
"$output\policy.exe"
"@ | Set-Content -LiteralPath $batch -Encoding ascii
& cmd /c $batch
if ($LASTEXITCODE) { throw 'Native movement policy regression failed' }
& python -B (Join-Path $PSScriptRoot 'test_movement_audio_gain.py')
if ($LASTEXITCODE) { throw 'Base flop gain verification failed' }
