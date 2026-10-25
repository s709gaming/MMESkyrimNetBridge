param([string]$Assembler = 'E:\Steam\steamapps\common\Skyrim Special Edition\Papyrus Compiler\PapyrusAssembler.exe',
    [string]$OriginalMME = "$env:LOCALAPPDATA\ModOrganizer\VortexToMO2\mods\Milk-Mod-Economy-Scripts-20220522.7z")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$choice = Join-Path $root 'fomod\choices\ostim-only'
[xml]$xml = Get-Content (Join-Path $root 'fomod\ModuleConfig.xml') -Raw
$backend = @($xml.SelectNodes('//group') | Where-Object { $_.name -eq 'Animation backend' })
if ($backend.Count -ne 1 -or $backend[0].type -ne 'SelectExactlyOne' -or $backend[0].plugins.plugin.Count -ne 3) { throw 'Backend selection is not exclusive' }
$ostim = $backend[0].plugins.plugin | Where-Object { $_.name.StartsWith('OStim-only') }
$pplus = $backend[0].plugins.plugin | Where-Object { $_.name.StartsWith('All-in-One SexLab P+') }
if (!$ostim -or !$pplus) { throw 'Missing backend choices' }
foreach ($plugin in @($ostim,$pplus)) {
    foreach ($file in $plugin.files.file) {
        if (!(Test-Path -LiteralPath (Join-Path $root $file.source))) { throw "Missing FOMOD file: $($file.source)" }
    }
    foreach ($folder in $plugin.files.folder) {
        if (!(Test-Path -LiteralPath (Join-Path $root $folder.source))) { throw "Missing FOMOD folder: $($folder.source)" }
    }
}
$deps = $ostim.SelectSingleNode('typeDescriptor/dependencyType/patterns/pattern/dependencies')
if (!$deps.SelectSingleNode('fileDependency[@file="OStim.esp" and @state="Active"]')) { throw 'Missing OStim prerequisite' }
foreach ($name in @('CP_Elsie.esp','Jugs.esp','SLAnimLoader.esp','MME Extensions - Elsie LaVache Fix.esp','SexLab.esm','Devious Devices - Assets.esm','Devious Devices - Integration.esm')) {
    if (!$deps.SelectSingleNode("dependencies/fileDependency[@file=`"$name`" and @state=`"Inactive`"]")) { throw "Missing unsupported-plugin guard: $name" }
}
foreach ($plugin in ($xml.SelectNodes('//plugin') | Where-Object { $_.name.StartsWith('Elsie') -or $_.name.StartsWith('JUGS') })) {
    if (!$plugin.SelectSingleNode('typeDescriptor/dependencyType/patterns/pattern/dependencies/flagDependency[@flag="mmeNoSexLab" and @value="false"]')) { throw 'Legacy compatibility choice can leak into OStim-only' }
}
$manifest = Get-Content (Join-Path $choice 'BuildManifest.json') -Raw | ConvertFrom-Json
$sources = @(Get-ChildItem (Join-Path $choice 'Source\Scripts') -Filter '*.psc')
if ($manifest.pairs.Count -ne $sources.Count) { throw 'Variant manifest is stale' }
foreach ($pair in $manifest.pairs) {
    if ((Get-FileHash (Join-Path $choice "Source\Scripts\$($pair.script).psc")).Hash -ne $pair.sourceSHA256 -or
        (Get-FileHash (Join-Path $choice "Scripts\$($pair.script).pex")).Hash -ne $pair.compiledSHA256) { throw "Source/compiled revision mismatch: $($pair.script)" }
}
if ((Get-FileHash (Join-Path $choice 'MilkModNEW.esp')).Hash -ne $manifest.pluginSHA256) { throw 'Plugin revision mismatch' }
if ((Get-FileHash (Join-Path $root 'MMEAlert.esp')).Hash -ne $manifest.dialoguePluginSHA256) { throw 'Dialogue plugin revision mismatch' }
$testDir = Join-Path $root ('build\diagnostics\ostim-only-bytecode-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDir | Out-Null
Push-Location $testDir
try {
    # Inspect the effective MME script set as well as our selected overrides.
    # This catches a compile-only shim concealing an original runtime dependency.
    $effective = @{}
    foreach ($file in Get-ChildItem (Join-Path $OriginalMME 'Scripts') -Filter '*.pex') { $effective[$file.BaseName] = $file.FullName }
    foreach ($source in Get-ChildItem (Join-Path $choice 'Source\Scripts') -Filter '*.psc') {
        $compiled = Join-Path $choice "Scripts\$($source.BaseName).pex"
        if (!(Test-Path $compiled)) { throw "Source-only variant: $($source.Name)" }
        $effective[$source.BaseName] = $compiled
    }
    if ($effective.Count -le $sources.Count) { throw 'Original MME dependency inventory is missing' }
    foreach ($name in $effective.Keys) {
        Copy-Item -LiteralPath $effective[$name] -Destination (Join-Path $testDir ($name + '.pex'))
        & $Assembler $name -D -Q
        if ($LASTEXITCODE) { throw "Cannot inspect effective script: $name" }
        $assembly = Get-Content "$name.disassemble.pas" -Raw
        $forbiddenType = '(?:SexLabFramework|ssl\w+|SexLabThread)'
        if ($assembly -match "(?im)^\s*\.(?:local|variable|param|property)\s+\S+\s+$forbiddenType\b" -or
            $assembly -match "(?im)^\s*\.return\s+$forbiddenType\b" -or
            $assembly -match '(?im)^\s*CallStatic\s+(?:SexLabUtil|SexlabRegistry|ssl\w+)\b' -or
            $assembly -match '(?im)^\s*PropGet\s+SexLab\s') { throw "Compiled SexLab dependency survives in $name" }
        if ($name -in @('MME_zbf','MME_DDi') -and $assembly -match '(?i)\b(?:zbfBondageShell|zadlibs)\b') { throw "Third-party typed bridge survives in $name" }
    }
    Write-Host "Effective MME bytecode inventory inspected: $($effective.Count) scripts (originals plus selected overrides). External framework internals remain separately scoped."
} finally { Pop-Location }
Write-Host 'PASS: exclusive backend choices, dependency guards, installed asset pairs, and compiled variants without SexLab types/native calls.'
