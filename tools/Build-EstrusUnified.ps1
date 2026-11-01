$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = 'E:\Steam\steamapps\common\Skyrim Special Edition'
$compiler = Join-Path $game 'Papyrus Compiler\PapyrusCompiler.exe'
$flags = Join-Path $game 'Data\Source\Scripts\TESV_Papyrus_Flags.flg'
$choice = Join-Path $root 'fomod\choices\estrus-unified'
& python (Join-Path $PSScriptRoot 'generate_estrus_unified.py')
if ($LASTEXITCODE) { throw 'Unified source generation failed' }
$common = @('tools\mme-diagnostic-sdk', 'Source\Scripts', 'tools\skyui-sdk', 'tools\mme-sdk', 'tools\ostim-sdk', 'tools\omania-sdk', 'tools\arousal-sdk', 'tools\skyrimnet-sdk') | ForEach-Object { Join-Path $root $_ }
$baseImports = @((Join-Path $PSScriptRoot 'estrus-unified-sdk')) + $common + @((Join-Path $game 'Data\Scripts\Source'), (Join-Path $game 'Data\Source\Scripts'))
if ($env:MME_PAPYRUS_EXTRA_IMPORTS) { $baseImports += $env:MME_PAPYRUS_EXTRA_IMPORTS }
$pairs = @()
foreach ($backend in @('standard', 'ostim-only')) {
    $source = Join-Path $choice "$backend\Source\Scripts"
    $output = Join-Path $choice "$backend\Scripts"
    $imports = @($source)
    if ($backend -eq 'ostim-only') {
        $library = Get-ChildItem (Join-Path $root 'build\diagnostics') -Directory -Filter 'ostim-only-imports-*' |
            Where-Object { Test-Path (Join-Path $_.FullName 'Actor.psc') } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (!$library) { throw 'Build the isolated OStim backend first' }
        $imports += (Join-Path $root 'fomod\choices\ostim-only\Source\Scripts')
        # Current common facades must precede older installed copies in the SDK.
        $imports += (Join-Path $root 'Source\Scripts')
        $imports += $library.FullName
    }
    $imports += $baseImports
    # Fresh compiler output avoids assembler locks and stale PEX reuse.
    $scratch = Join-Path $root ('build\diagnostics\estrus-compile-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $output, $scratch | Out-Null
    $ErrorActionPreference = 'Continue'
    & $compiler (Join-Path $source 'MilkQUEST.psc') "-f=$flags" "-i=$($imports -join ';')" "-o=$scratch" 2>&1 | ForEach-Object { Write-Host "$_" }
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE) { throw "Unified $backend compilation failed" }
    Copy-Item -LiteralPath (Join-Path $scratch 'MilkQUEST.pex') -Destination $output -Force
    $pairs += [ordered]@{ backend = $backend; sourceSHA256 = (Get-FileHash (Join-Path $source 'MilkQUEST.psc')).Hash; compiledSHA256 = (Get-FileHash (Join-Path $output 'MilkQUEST.pex')).Hash }
}
[ordered]@{ runtimeValidated = $false; pairs = $pairs } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $choice 'BuildManifest.json')
