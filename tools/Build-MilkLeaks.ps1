$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$choice = Join-Path $root 'fomod\choices\milk-leaks'
$original = Join-Path $root 'Reference mods\oninus lactis ng'
& dotnet run --project (Join-Path $root 'tools\milk-leak-builder') -- (Join-Path $original 'OninusLactis.esp') (Join-Path $choice 'MME Extensions - Milk Leaks.esp')
if ($LASTEXITCODE) { throw 'Milk leak records failed verification' }
$gameRoot = 'E:\Steam\steamapps\common\Skyrim Special Edition'
$compiler = Join-Path $gameRoot 'Papyrus Compiler\PapyrusCompiler.exe'
$flags = Join-Path $gameRoot 'Data\Source\Scripts\TESV_Papyrus_Flags.flg'
$imports = @((Join-Path $choice 'Source\Scripts'),(Join-Path $root 'Source\Scripts'),(Join-Path $original 'Scripts\Source'),(Join-Path $root 'tools\skyui-sdk'),(Join-Path $root 'tools\mme-sdk'),(Join-Path $root 'tools\ostim-sdk'),(Join-Path $root 'tools\omania-sdk'),(Join-Path $root 'tools\arousal-sdk'),(Join-Path $root 'tools\skyrimnet-sdk'),(Join-Path $gameRoot 'Data\Scripts\Source'),(Join-Path $gameRoot 'Data\Source\Scripts')) -join ';'
$out = Join-Path $root ('build\diagnostics\milk-leaks-compiled-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $out, (Join-Path $choice 'Scripts') | Out-Null
foreach ($name in @('MMEMilkLeaks','MMEMilkLeakAPI','MMELeakVisual','MMELeakPlayerAlias')) {
    & $compiler "$name.psc" "-f=$flags" "-i=$imports" "-o=$out"
    if ($LASTEXITCODE) { throw "Milk leak compilation failed: $name" }
    $destination = Join-Path $choice "Scripts\$name.pex"
    if ($name -in @('MMEMilkLeaks','MMEMilkLeakAPI')) { $destination = Join-Path $root "Scripts\$name.pex" }
    $previous = Join-Path $out "$name.previous.pex"
    if (Test-Path -LiteralPath $destination) { Move-Item -LiteralPath $destination -Destination $previous }
    try { Copy-Item -LiteralPath (Join-Path $out "$name.pex") -Destination $destination }
    catch {
        if (Test-Path -LiteralPath $previous) { Move-Item -LiteralPath $previous -Destination $destination -Force }
        throw
    }
}
# Start-game quest bootstrap, including existing saves that install this option.
$plugin = Join-Path $choice 'MME Extensions - Milk Leaks.esp'
# Builder emits one quest after 3 * (armor + two addons), starting at 0x800.
$seqDir = Join-Path $choice 'SEQ'
New-Item -ItemType Directory -Force $seqDir | Out-Null
[IO.File]::WriteAllBytes((Join-Path $seqDir 'MME Extensions - Milk Leaks.seq'), [BitConverter]::GetBytes([uint32]0x809))
$pairs = @(Get-ChildItem (Join-Path $choice 'Source\Scripts') -Filter '*.psc' | ForEach-Object {
    [ordered]@{script=$_.BaseName;sourceSHA256=(Get-FileHash $_.FullName).Hash;compiledSHA256=(Get-FileHash (Join-Path $choice "Scripts\$($_.BaseName).pex")).Hash}
})
[ordered]@{runtimeValidated=$false;pluginSHA256=(Get-FileHash $plugin).Hash;pairs=$pairs} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $choice 'BuildManifest.json')
