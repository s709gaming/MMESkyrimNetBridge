param([string]$GamePath = 'E:\Steam\steamapps\common\Skyrim Special Edition')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$choice = Join-Path $root 'fomod\choices\maid-roster-ui'
$compiler = Join-Path $GamePath 'Papyrus Compiler\PapyrusCompiler.exe'
$flags = Join-Path $GamePath 'Data\Source\Scripts\TESV_Papyrus_Flags.flg'
& dotnet run --project (Join-Path $root 'tools\maid-roster-builder') -- (Join-Path $root 'MMEAlert.esp') (Join-Path $choice 'MME Extensions - Maid Roster.esp')
if ($LASTEXITCODE) { throw 'Roster quest build/round-trip checks failed' }
$imports = @((Join-Path $choice 'Source\Scripts'),(Join-Path $root 'tools\maid-roster-sdk'),(Join-Path $root 'tools\magelight-sdk'),(Join-Path $root 'Source\Scripts'),(Join-Path $GamePath 'Data\Scripts\Source'),(Join-Path $GamePath 'Data\Source\Scripts')) -join ';'
New-Item -ItemType Directory -Force (Join-Path $choice 'Scripts') | Out-Null
foreach ($name in @('MMEMaidRosterUI','MMEMaidRosterPlayerAlias')) {
    & $compiler "$name.psc" "-f=$flags" "-i=$imports" "-o=$(Join-Path $choice 'Scripts')"
    if ($LASTEXITCODE) { throw "Roster compilation failed: $name" }
}
$pairs = @(Get-ChildItem (Join-Path $choice 'Source\Scripts') -Filter '*.psc' | ForEach-Object {
    [ordered]@{ script=$_.BaseName; sourceSHA256=(Get-FileHash $_.FullName).Hash; compiledSHA256=(Get-FileHash (Join-Path $choice "Scripts\$($_.BaseName).pex")).Hash }
})
[ordered]@{ runtimeValidated=$false; requiredHost='Magelight UI 1.5.0+'; pairs=$pairs; pluginSHA256=(Get-FileHash (Join-Path $choice 'MME Extensions - Maid Roster.esp')).Hash; dashboardSHA256=(Get-FileHash (Join-Path $choice 'Magelight\mmeextensions\views\roster\dashboard.js')).Hash; pageSHA256=(Get-FileHash (Join-Path $choice 'Magelight\mmeextensions\views\roster\index.html')).Hash } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $choice 'BuildManifest.json')
