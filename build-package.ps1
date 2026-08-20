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
$ostimSdkSource = Join-Path $projectRoot "tools\ostim-sdk"
$sourceDir = Join-Path $projectRoot "Source\Scripts"
$compiledDir = Join-Path $projectRoot "Scripts"
$distDir = Join-Path $projectRoot "dist"
$stageDir = Join-Path $distDir "MME Extensions"
$zipPath = Join-Path $distDir "MME Extensions.zip"
$pluginPath = Join-Path $projectRoot "MMEAlert.esp"
$seqPath = Join-Path $gameRoot "Data\SEQ\MMEAlert.seq"
$scriptNames = @("MMEDebug", "MMEAlertsController", "MMEAlertsMCM", "MMEDrinkTracker", "MMEAlertsPlayerEffect", "MMEAlertsQuickTest", "MMEAlertsFlatRateDefaults", "MMEAlertsSkyrimNet", "MMESkyrimNetVoiceControls", "MMEMilkBoost", "MMEArousalBridge", "MMEMilkDrinkEffects", "MMEDrinkAnimation", "MMEAnimationSafety", "MMEArmorScript", "MMENPCDialog", "MMEOStimIntegration", "MMEOStimBreastfeeding", "MMEExtensionsNative")
$quickStartSourceDir = Join-Path $projectRoot "fomod\choices\recommended-quickstart\Source\Scripts"
$quickStartOutputDir = Join-Path $projectRoot "fomod\choices\recommended-quickstart\Scripts"
$standardDefaultsSourceDir = Join-Path $projectRoot "fomod\choices\standard\Source\Scripts"
$standardDefaultsOutputDir = Join-Path $projectRoot "fomod\choices\standard\Scripts"

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
if (!(Test-Path -LiteralPath (Join-Path $quickStartSourceDir "MMEAlertsQuickTest.psc"))) {
    throw "QuickStart source script not found: $quickStartSourceDir\MMEAlertsQuickTest.psc"
}
if (!(Test-Path -LiteralPath (Join-Path $standardDefaultsSourceDir "MMEAlertsFlatRateDefaults.psc"))) {
    throw "Vanilla defaults source script not found: $standardDefaultsSourceDir\MMEAlertsFlatRateDefaults.psc"
}

# Compile the debug scripts against the installed SKSE and Skyrim sources.
New-Item -ItemType Directory -Force -Path $compiledDir | Out-Null
$imports = "$sourceDir;$skyUiSdkSource;$mmeSdkSource;$ostimSdkSource;$skseSource;$vanillaSource"
foreach ($scriptName in $scriptNames) {
    Write-Host "Compiling $scriptName.psc..." -ForegroundColor Cyan
    & $compiler "$scriptName.psc" "-f=$flags" "-i=$imports" "-o=$compiledDir"
    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed for $scriptName.psc"
    }
}

# The base package is inert; compile the Recommended-only QuickStart override
# into its FOMOD choice folder with the same script name.
New-Item -ItemType Directory -Force -Path $quickStartOutputDir | Out-Null
Push-Location $quickStartSourceDir
try {
    Write-Host "Compiling Recommended QuickStart override..." -ForegroundColor Cyan
    & $compiler "MMEAlertsQuickTest.psc" "-f=$flags" "-i=$quickStartSourceDir;$imports" "-o=$quickStartOutputDir"
    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed for Recommended QuickStart override"
    }
}
finally {
    Pop-Location
}

# The Vanilla profile replaces the real defaults quest script with an inert
# compatible implementation, so it can never change MME settings.
New-Item -ItemType Directory -Force -Path $standardDefaultsOutputDir | Out-Null
Push-Location $standardDefaultsSourceDir
try {
    Write-Host "Compiling Vanilla no-op defaults override..." -ForegroundColor Cyan
    & $compiler "MMEAlertsFlatRateDefaults.psc" "-f=$flags" "-i=$standardDefaultsSourceDir;$imports" "-o=$standardDefaultsOutputDir"
    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed for Vanilla defaults override"
    }
}
finally {
    Pop-Location
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

# Include the FOMOD startup-profile choices and their Recommended QuickStart override.
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

# Skyrim.Net YAML maps its conversational speaker and dynamic target directly
# to the two-actor milk-sharing bridge on MMEAlertDebugQuest.
$milkShareAction = Join-Path $projectRoot "SkyrimNetActions\mme_breastfeeding_milk_share.yaml"
if (Test-Path -LiteralPath $milkShareAction) {
    $actionDestination = Join-Path $stageDir "SKSE\Plugins\SkyrimNet\config\actions"
    New-Item -ItemType Directory -Force -Path $actionDestination | Out-Null
    Copy-Item -LiteralPath $milkShareAction -Destination $actionDestination
}

# Package the SSEEdit-built randomized voice pools and the two legacy test files.
$testSoundRoot = Join-Path $projectRoot "assets\sounds"
if (Test-Path -LiteralPath $testSoundRoot) {
    Get-ChildItem -LiteralPath $testSoundRoot | Copy-Item -Destination $packageSounds -Recurse
}

# Ship the project overview. Keep the generically named LICENSE file out of the
# game Data package because unrelated mods commonly use the same root filename.
Copy-Item -LiteralPath (Join-Path $projectRoot "README.md") -Destination $stageDir

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
