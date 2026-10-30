param(
    [string]$InstancePath = "$env:LOCALAPPDATA\ModOrganizer\VortexToMO2",
    [string]$GamePath = 'E:\Steam\steamapps\common\Skyrim Special Edition',
    [switch]$ReuseImports
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$originalMod = Join-Path $InstancePath 'mods\Milk-Mod-Economy-Scripts-20220522.7z'
$originalSource = Join-Path $originalMod 'scripts\source'
$variantRoot = Join-Path $projectRoot 'fomod\choices\ostim-only'
$variantSource = Join-Path $variantRoot 'Source\Scripts'
$variantOutput = Join-Path $variantRoot 'Scripts'
$compiler = Join-Path $GamePath 'Papyrus Compiler\PapyrusCompiler.exe'
$flags = Join-Path $GamePath 'Data\Source\Scripts\TESV_Papyrus_Flags.flg'
$library = Join-Path $projectRoot ('build\diagnostics\ostim-only-imports-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $library, $variantOutput | Out-Null
& python (Join-Path $PSScriptRoot 'generate_ostim_only.py') --mme-source $originalSource
if ($LASTEXITCODE) { throw 'OStim-only source generation failed' }
& dotnet run --project (Join-Path $PSScriptRoot 'ostim-only-builder') -- (Join-Path $originalMod 'MilkModNEW.esp') (Join-Path $variantRoot 'MilkModNEW.esp')
if ($LASTEXITCODE) { throw 'OStim-only plugin build failed' }
& dotnet run --project (Join-Path $PSScriptRoot 'ostim-only-builder') -- --check-dialogue (Join-Path $projectRoot 'MMEAlert.esp') (Join-Path $originalMod 'MilkModNEW.esp')
if ($LASTEXITCODE) { throw 'Conversion dialogue validation failed' }

# Import only explicit SDKs, vanilla/SKSE, and PapyrusUtil; no SexLab framework
# sources may satisfy the OStim-only compile. Full sources remain isolated in MO2.
$folders = @(
    (Join-Path $projectRoot 'tools\mme-diagnostic-sdk'),
    (Join-Path $projectRoot 'tools\mme-sdk'),
    (Join-Path $projectRoot 'tools\skyui-sdk'),
    (Join-Path $projectRoot 'tools\ostim-sdk'),
    (Join-Path $projectRoot 'tools\omania-sdk'),
    (Join-Path $projectRoot 'tools\arousal-sdk'),
    (Join-Path $projectRoot 'tools\skyrimnet-sdk'),
    (Join-Path $GamePath 'Data\Scripts\Source'),
    (Join-Path $GamePath 'Data\Source\Scripts'),
    (Join-Path $InstancePath 'mods\PapyrusUtil AE SE - Scripting Utility Functions\Scripts\Source'),
    (Join-Path $InstancePath 'mods\PapyrusUtil AE SE - Scripting Utility Functions\Source\Scripts')
)
if ($ReuseImports) {
    $library = (Get-ChildItem (Join-Path $projectRoot 'build\diagnostics') -Directory -Filter 'ostim-only-imports-*' | Where-Object { Test-Path (Join-Path $_.FullName 'Actor.psc') } | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    if (!$library) { throw 'No prepared isolated imports' }
} else {
$folderManifest = Join-Path $library 'folders.json'
ConvertTo-Json -InputObject @($folders) | Set-Content -LiteralPath $folderManifest
& python (Join-Path $PSScriptRoot 'prepare_ostim_imports.py') $folderManifest $variantSource $library
if ($LASTEXITCODE) { throw 'Isolated import preparation failed' }
}
Copy-Item -Path (Join-Path $projectRoot 'tools\ostim-sdk\*.psc') -Destination $library -Force
# These common facades must match this repository's DLL, not an older installed
# copy picked up from physical Data while preparing the isolated dependency set.
foreach ($commonFacade in @('MMEExtensionsNative')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "Source\Scripts\$commonFacade.psc") -Destination $library -Force
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'Source\Scripts\MMENarrationOverrides.psc') -Destination $library -Force
$imports = "$variantSource;$library;$(Join-Path $projectRoot 'Source\Scripts')"
# Compile into a fresh folder so the assembler never reopens a previously built PEX.
$variantCompile = Join-Path $projectRoot ('build\diagnostics\ostim-compiled-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $variantCompile | Out-Null
foreach ($file in (Get-ChildItem -LiteralPath $variantSource -Filter '*.psc' | Sort-Object Name)) {
    Write-Host "OStim-only compile: $($file.Name)"
    $ErrorActionPreference = "Continue"
    & $compiler $file.FullName "-f=$flags" "-i=$imports" "-o=$variantCompile" 2>&1 | ForEach-Object { Write-Host "$_" }
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE) { throw "OStim-only compilation failed: $($file.Name)" }
}
Get-ChildItem -LiteralPath $variantCompile -Filter "*.pex" | Copy-Item -Destination $variantOutput -Force
$pairs = @(Get-ChildItem -LiteralPath $variantSource -Filter '*.psc' | ForEach-Object {
    [ordered]@{ script = $_.BaseName; sourceSHA256 = (Get-FileHash $_.FullName).Hash; compiledSHA256 = (Get-FileHash (Join-Path $variantOutput ($_.BaseName + '.pex'))).Hash }
})
[ordered]@{ backend = 'OStim-only'; runtimeValidated = $false; pairs = $pairs; pluginSHA256 = (Get-FileHash (Join-Path $variantRoot 'MilkModNEW.esp')).Hash; dialoguePluginSHA256 = (Get-FileHash (Join-Path $projectRoot 'MMEAlert.esp')).Hash } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $variantRoot 'BuildManifest.json')
Write-Host 'OStim-only variants compiled without SexLab framework SDK sources.' 
