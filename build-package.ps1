$ErrorActionPreference = "Stop"

# Resolve every path from this script so it works when launched by double-click.
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$gameRoot = "E:\Steam\steamapps\common\Skyrim Special Edition"
$compiler = Join-Path $gameRoot "Papyrus Compiler\PapyrusCompiler.exe"
$flags = Join-Path $gameRoot "Data\Source\Scripts\TESV_Papyrus_Flags.flg"
$skseSource = Join-Path $gameRoot "Data\Scripts\Source"
$vanillaSource = Join-Path $gameRoot "Data\Source\Scripts"
$skyUiSdkSource = Join-Path $projectRoot "tools\skyui-sdk"
$mmeSdkSource = Join-Path $projectRoot "tools\mme-sdk"
$sourceDir = Join-Path $projectRoot "Source\Scripts"
$compiledDir = Join-Path $projectRoot "Scripts"
$distDir = Join-Path $projectRoot "dist"
$stageDir = Join-Path $distDir "MME Extensions"
$zipPath = Join-Path $distDir "MME Extensions.zip"
$pluginPath = Join-Path $projectRoot "MMEAlert.esp"
$seqPath = Join-Path $gameRoot "Data\SEQ\MMEAlert.seq"
$scriptNames = @("MMEDebug", "MMEAlertsController", "MMEAlertsMCM", "MMEDrinkTracker", "MMEAlertsPlayerEffect", "MMEAlertsQuickTest", "MMEAlertsFlatRateDefaults", "MMEAlertsSkyrimNet", "MMEMilkBoost", "MMEArousalBridge", "MMEMilkDrinkEffects", "MMENPCDialog", "MMEExtensionsNative")

$nativeDll = Join-Path $projectRoot "build\native-release\package\SKSE\Plugins\MMEExtensions.dll"

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
$imports = "$sourceDir;$skyUiSdkSource;$mmeSdkSource;$skseSource;$vanillaSource"
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
$packageSounds = Join-Path $stageDir "Sound\fx\MMESkyrimNetBridge"
$packageSKSEPlugins = Join-Path $stageDir "SKSE\Plugins"
New-Item -ItemType Directory -Force -Path $packageScripts, $packageSources, $packageSounds, $packageSKSEPlugins | Out-Null

# Include the simple FOMOD choice for the optional personal MME defaults profile.
$fomodSource = Join-Path $projectRoot "fomod"
If (Test-Path -LiteralPath $fomodSource) {
    Copy-Item -LiteralPath $fomodSource -Destination $stageDir -Recurse
}

# Copy the active compiled scripts and matching sources.
foreach ($scriptName in $scriptNames) {
    Copy-Item -LiteralPath (Join-Path $compiledDir "$scriptName.pex") -Destination $packageScripts
    Copy-Item -LiteralPath (Join-Path $sourceDir "$scriptName.psc") -Destination $packageSources
}

# The lifecycle feature requires the CommonLibSSE-NG SE/AE/VR bridge.
if (!(Test-Path -LiteralPath $nativeDll)) {
    throw "Native lifecycle DLL missing. Run build-native.ps1 first: $nativeDll"
}
Copy-Item -LiteralPath $nativeDll -Destination $packageSKSEPlugins

# Install the editable SkyrimNet message configuration at PapyrusUtil's JSON path.
$skyrimNetConfig = Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\SkyrimNet.json"
if (Test-Path -LiteralPath $skyrimNetConfig) {
    $packageConfig = Join-Path $stageDir "SKSE\Plugins\StorageUtilData\MMEAlerts"
    New-Item -ItemType Directory -Force -Path $packageConfig | Out-Null
    Copy-Item -LiteralPath $skyrimNetConfig -Destination $packageConfig
}

# Install the additive actor-bio prompt without replacing any SkyrimNet-owned template.
$milkmaidPrompt = Join-Path $projectRoot "SkyrimNetPrompts\0260_mme_extensions_milkmaid.prompt"
if (Test-Path -LiteralPath $milkmaidPrompt) {
    $promptDestination = Join-Path $stageDir "SKSE\Plugins\SkyrimNet\prompts\submodules\character_bio"
    New-Item -ItemType Directory -Force -Path $promptDestination | Out-Null
    Copy-Item -LiteralPath $milkmaidPrompt -Destination $promptDestination
}

# Package the SSEEdit-built randomized voice pools and the two legacy test files.
$testSoundRoot = Join-Path $projectRoot "assets\sounds"
if (Test-Path -LiteralPath $testSoundRoot) {
    Get-ChildItem -LiteralPath $testSoundRoot | Copy-Item -Destination $packageSounds -Recurse
}

# Ship the project overview and permission terms with every archive.
Copy-Item -LiteralPath (Join-Path $projectRoot "README.md") -Destination $stageDir
Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") -Destination $stageDir

$spidConfig = Join-Path $projectRoot "MMEAlert_DISTR.ini"
If (Test-Path -LiteralPath $spidConfig) {
    Copy-Item -LiteralPath $spidConfig -Destination $stageDir
}

# Include the xEdit-created plugin and its Start Game Enabled quest index.
if (Test-Path -LiteralPath $pluginPath) {
    Copy-Item -LiteralPath $pluginPath -Destination $stageDir
} else {
    Write-Warning "MMEAlert.esp is not present yet. Building a scripts-only MME Extensions package."
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
