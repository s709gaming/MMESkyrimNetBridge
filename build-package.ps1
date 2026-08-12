$ErrorActionPreference = "Stop"

# Resolve every path from this script so it works when launched by double-click.
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$gameRoot = "E:\Steam\steamapps\common\Skyrim Special Edition"
$compiler = Join-Path $gameRoot "Papyrus Compiler\PapyrusCompiler.exe"
$flags = Join-Path $gameRoot "Data\Source\Scripts\TESV_Papyrus_Flags.flg"
$skseSource = Join-Path $gameRoot "Data\Scripts\Source"
$vanillaSource = Join-Path $gameRoot "Data\Source\Scripts"
$sourceDir = Join-Path $projectRoot "Source\Scripts"
$compiledDir = Join-Path $projectRoot "Scripts"
$distDir = Join-Path $projectRoot "dist"
$stageDir = Join-Path $distDir "MMEAlert"
$zipPath = Join-Path $distDir "MMEAlert.zip"
$pluginPath = Join-Path $projectRoot "MMEAlert.esp"
$seqPath = Join-Path $gameRoot "Data\SEQ\MMEAlert.seq"
$scriptNames = @("MMEDebug", "MMEAlertLeakEffect")

# Fail early with a useful explanation if the local toolchain is incomplete.
if (!(Test-Path -LiteralPath $compiler)) {
    throw "Papyrus compiler not found: $compiler"
}
if (!(Test-Path -LiteralPath $flags)) {
    throw "Papyrus flags file not found: $flags"
}
foreach ($scriptName in $scriptNames) {
    $sourcePath = Join-Path $sourceDir "$scriptName.psc"
    if (!(Test-Path -LiteralPath $sourcePath)) {
        throw "Required source script not found: $sourcePath"
    }
}

# Compile the debug scripts against the installed SKSE and Skyrim sources.
New-Item -ItemType Directory -Force -Path $compiledDir | Out-Null
$imports = "$sourceDir;$skseSource;$vanillaSource"
foreach ($scriptName in $scriptNames) {
    Write-Host "Compiling $scriptName.psc..." -ForegroundColor Cyan
    & $compiler "$scriptName.psc" "-f=$flags" "-i=$imports" "-o=$compiledDir"
    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed for $scriptName.psc"
    }
}

# Recreate a clean staging directory with Skyrim/Vortex-compatible paths.
if (Test-Path -LiteralPath $stageDir) {
    Remove-Item -LiteralPath $stageDir -Recurse -Force
}
$packageScripts = Join-Path $stageDir "Scripts"
$packageSources = Join-Path $stageDir "Source\Scripts"
New-Item -ItemType Directory -Force -Path $packageScripts, $packageSources | Out-Null

# Copy only the two debug scripts needed by this test mod.
foreach ($scriptName in $scriptNames) {
    Copy-Item -LiteralPath (Join-Path $compiledDir "$scriptName.pex") -Destination $packageScripts
    Copy-Item -LiteralPath (Join-Path $sourceDir "$scriptName.psc") -Destination $packageSources
}

# Ship the project overview and permission terms with every archive.
Copy-Item -LiteralPath (Join-Path $projectRoot "README.md") -Destination $stageDir
Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") -Destination $stageDir

# Include the xEdit-created plugin and its Start Game Enabled quest index.
if (Test-Path -LiteralPath $pluginPath) {
    Copy-Item -LiteralPath $pluginPath -Destination $stageDir
} else {
    Write-Warning "MMEAlert.esp is not present yet. Building a scripts-only package."
}

if (Test-Path -LiteralPath $seqPath) {
    $packageSeq = Join-Path $stageDir "SEQ"
    New-Item -ItemType Directory -Force -Path $packageSeq | Out-Null
    Copy-Item -LiteralPath $seqPath -Destination $packageSeq
} else {
    Write-Warning "MMEAlert.seq is missing. Generate it in xEdit before testing the startup quest."
}

# Replace the previous archive with the newly staged package.
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $stageDir "*") -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host ""
Write-Host "Package created successfully:" -ForegroundColor Green
Write-Host $zipPath
