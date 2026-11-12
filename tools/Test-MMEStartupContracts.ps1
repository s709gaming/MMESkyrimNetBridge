param([string]$CompiledDirectory = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (!$CompiledDirectory) { $CompiledDirectory = Join-Path $root 'Scripts' }
$game = 'E:/Steam/steamapps/common/Skyrim Special Edition'
$compiler = Join-Path $game 'Papyrus Compiler/PapyrusCompiler.exe'
$flags = Join-Path $game 'Data/Source/Scripts/TESV_Papyrus_Flags.flg'
$stubSource = Join-Path $root 'tools/pplus-hook-sdk'
$stubOutput = Join-Path $root ('build/diagnostics/startup-negative-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $stubOutput | Out-Null
$stubImports = "$stubSource;$game/Data/Scripts/Source;$game/Data/Source/Scripts"
& $compiler (Join-Path $stubSource 'MilkPlayerLoadGame.psc') "-f=$flags" "-i=$stubImports" "-o=$stubOutput"
if ($LASTEXITCODE) { throw 'Startup negative-control compile failed' }
$artifacts = @(
    (Join-Path $CompiledDirectory 'MilkPlayerLoadGame.pex'),
    (Join-Path $root 'fomod/choices/sexlab-pplus/Scripts/MilkPlayerLoadGame.pex'),
    (Join-Path $root 'fomod/choices/ostim-only/Scripts/MilkPlayerLoadGame.pex')
)
& python -B (Join-Path $root 'tools/check_mme_startup.py') @artifacts --reject-stub (Join-Path $stubOutput 'MilkPlayerLoadGame.pex')
if ($LASTEXITCODE) { throw 'MME startup-script contracts failed' }
