$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$implementation = Get-Content -LiteralPath (Join-Path $root 'Source/Scripts/MMELockProtection.psc') -Raw
$lock = Get-Content -LiteralPath (Join-Path $root 'Source/Scripts/MMETimedArmorLock.psc') -Raw
foreach ($suffix in @('Locked', 'Armor', 'Deadline')) {
    $savedKey = '"MMEExtensions.TimedArmor.' + $suffix + '"'
    if (!$implementation.Contains($savedKey) -or !$lock.Contains($savedKey)) {
        throw "Lock protection saved-state contract drifted: $suffix"
    }
}
$out = Join-Path $root 'build/diagnostics/lock-protection/native-test'
New-Item -ItemType Directory -Force $out | Out-Null
$dev = 'E:\Visual Studio\Common7\Tools\VsDevCmd.bat'
$test = Join-Path $root 'tools/test_lock_protection.cpp'
$exe = Join-Path $out 'test_lock_protection.exe'
Push-Location $out
try {
    & cmd.exe /d /s /c "`"$dev`" -arch=x64 -host_arch=x64 >nul && cl.exe /nologo /std:c++20 /EHsc /W4 /WX `"$test`" /Fe:`"$exe`""
    if ($LASTEXITCODE) { throw 'Lock protection native regression compilation failed' }
    & $exe
    if ($LASTEXITCODE) { throw 'Lock protection native ownership matrix failed' }
} finally { Pop-Location }
