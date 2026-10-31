param([switch]$CompileNativeTests)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$canonical = Get-Content (Join-Path $root 'Source\MMECompatibilityOverrides\MilkQUEST.psc') -Raw
$ostim = Get-Content (Join-Path $root 'fomod\choices\ostim-only\Source\Scripts\MilkQUEST.psc') -Raw
$helper = Get-Content (Join-Path $root 'Source\Scripts\MMEEstrusUnified.psc') -Raw
$native = Get-Content (Join-Path $root 'src\EstrusUnified.h') -Raw
$ostimBuild = Get-Content (Join-Path $root 'tools\Build-OStimOnly.ps1') -Raw
if ($ostimBuild -notmatch "@\('MMEExtensionsNative', 'MMEEstrusUnified'\)") { throw 'OStim imports may bind stale installed common facades' }
foreach ($source in @($canonical, $ostim)) {
    if ($source -notmatch 'bool Function isPregnant\(Actor akActor\)\s+if !akActor[\s\S]*?if MMEEstrusUnified.IsPregnant\(akActor\)\s+return true\s+endif\s+String akActorName') { throw 'Pregnancy entry/fallback changed or OStim generator lost integration' }
    foreach ($legacy in @('EstrusChaurus.esp','EstrusSpider.esp','EstrusDwemer.esp')) {
        if (!$source.Contains($legacy)) { throw "Legacy Estrus detection lost: $legacy" }
    }
    if ($source -match 'EstrusUnifiedAPI\.|HasEstrusUnified\(') { throw 'Direct optional script dependency leaked into MilkQUEST' }
}
if ($helper -match 'EstrusUnifiedAPI\.|Debug\.(Trace|Notification|MessageBox)|Utility.Wait|RegisterForUpdate') { throw 'Optional dependency, ungated logging, or new polling in facade' }
if ($helper -notmatch 'MMELog.MasterDiagnostic' -or $helper -notmatch 'MMELog.Alarm' -or $helper -notmatch 'enablePapyrusTrace') { throw 'Unified logging contract missing' }
foreach ($guard in @('LookupLoadedModByName','GetPluginInfo','GetIsNative','GetIsStatic','GetParamCount','GetReturnType','GetIsLatent','HasStub','parameterType.GetTypeInfo()','result.IsBool()','result.IsInt()')) {
    if (!$native.Contains($guard)) { throw "Native dispatch guard missing: $guard" }
}
if ($native -match 'DispatchStaticCall|RegisterLatentFunction|ReturnLatentResult|GetProcAddress|reinterpret_cast') { throw 'Unsafe asynchronous or raw-ABI query route introduced' }

if ($CompileNativeTests) {
    $out = Join-Path $root 'build\diagnostics\estrus-tests'
    New-Item -ItemType Directory -Force $out | Out-Null
    $dev = 'E:\Visual Studio\Common7\Tools\VsDevCmd.bat'
    $source = Join-Path $root 'tools\test_estrus_unified.cpp'
    $exe = Join-Path $out 'test_estrus_unified.exe'
    $obj = Join-Path $out 'test_estrus_unified.obj'
    & cmd.exe /d /s /c "`"$dev`" -arch=x64 -host_arch=x64 >nul && cl.exe /nologo /std:c++20 /EHsc /W4 /WX `"$source`" /Fe:`"$exe`" /Fo:`"$obj`""
    if ($LASTEXITCODE) { throw 'Unified native policy test compilation failed' }
    & $exe
    if ($LASTEXITCODE) { throw 'Unified native policy tests failed' }
}
Write-Host 'PASS: Unified facade, legacy fallback, generated OStim integration and optional API guards'
