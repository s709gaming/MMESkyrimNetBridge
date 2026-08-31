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
$scriptNames = @("MMEDebug", "MMEAlertsController", "MMEAlertsMCM", "MMEDiagnostics", "MMEThoughts", "MMEDrinkTracker", "MMEAlertsPlayerEffect", "MMEAlertsQuickTest", "MMEAlertsFlatRateDefaults", "MMEAlertsSkyrimNet", "MMESkyrimNetVoiceControls", "MMEMilkBoost", "MMEArousalBridge", "MMEMilkDrinkEffects", "MMEDrinkAnimation", "MMEAnimationSafety", "MMEReactionAnimation", "MMEArmorScript", "MMEBlacksmithDialogue", "MMENPCDialog", "MMEOStimIntegration", "MMEOStimBreastfeeding", "MMENewMilkMaid", "MMEExtensionsNative")
$quickStartSourceDir = Join-Path $projectRoot "fomod\choices\recommended-quickstart\Source\Scripts"
$quickStartOutputDir = Join-Path $projectRoot "fomod\choices\recommended-quickstart\Scripts"
$standardDefaultsSourceDir = Join-Path $projectRoot "fomod\choices\standard\Source\Scripts"
$standardDefaultsOutputDir = Join-Path $projectRoot "fomod\choices\standard\Scripts"

$nativeDll = Join-Path $projectRoot "build\native-release\package\SKSE\Plugins\MMEExtensions.dll"
$ostimBreastfeedingScene = Join-Path $projectRoot "SKSE\Plugins\OStim\scenes\MMEExtensions\2P\FF\MMEExt2PStandingNippleSuckingFF.json"

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
if (!(Test-Path -LiteralPath $ostimBreastfeedingScene)) {
    throw "OStim female/female breastfeeding scene is missing: $ostimBreastfeedingScene"
}
$ostimSceneData = Get-Content -LiteralPath $ostimBreastfeedingScene -Raw | ConvertFrom-Json
if ($ostimSceneData.actors.Count -ne 2 -or
    $ostimSceneData.actors[0].intendedSex -ne "female" -or
    $ostimSceneData.actors[1].intendedSex -ne "female" -or
    $ostimSceneData.actions.Count -ne 1 -or
    $ostimSceneData.actions[0].type -ne "suckingnipples" -or
    $ostimSceneData.actions[0].actor -ne 0 -or
    $ostimSceneData.actions[0].target -ne 1) {
    throw "OStim breastfeeding scene metadata no longer preserves FF drinker=0/milk-source=1 nipple-sucking roles."
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

# OStim Standalone currently ships nipple-sucking only as an MF scene. This
# additive descriptor reuses that exact animation for FF actors while keeping
# the semantic action and drinker/source roles visible to OLibrary.
$packageOStimScene = Join-Path $stageDir "SKSE\Plugins\OStim\scenes\MMEExtensions\2P\FF"
New-Item -ItemType Directory -Force -Path $packageOStimScene | Out-Null
Copy-Item -LiteralPath $ostimBreastfeedingScene -Destination $packageOStimScene

# Install editable PapyrusUtil JSON databases. Thoughts.json is the sole wording
# source for local notifications and optional Skyrim.Net Thought context.
$packageConfig = Join-Path $stageDir "SKSE\Plugins\StorageUtilData\MMEAlerts"
New-Item -ItemType Directory -Force -Path $packageConfig | Out-Null
foreach ($configName in @("SkyrimNet.json", "Thoughts.json")) {
    $configPath = Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\$configName"
    if (!(Test-Path -LiteralPath $configPath)) {
        throw "Required JSON configuration is missing: $configPath"
    }
    Copy-Item -LiteralPath $configPath -Destination $packageConfig
}

# Install the additive actor-bio prompt without replacing any SkyrimNet-owned template.
$milkmaidPrompt = Join-Path $projectRoot "SkyrimNetPrompts\0260_mme_extensions_milkmaid.prompt"
if (Test-Path -LiteralPath $milkmaidPrompt) {
    $promptDestination = Join-Path $stageDir "SKSE\Plugins\SkyrimNet\prompts\submodules\character_bio"
    New-Item -ItemType Directory -Force -Path $promptDestination | Out-Null
    Copy-Item -LiteralPath $milkmaidPrompt -Destination $promptDestination
}

# Skyrim.Net exposes explicit source-speaks and drinker-speaks contracts. Both
# normalize into the same two-actor bridge on MMEAlertDebugQuest.
$milkShareActions = @(
    (Join-Path $projectRoot "SkyrimNetActions\mme_breastfeeding_milk_share.yaml"),
    (Join-Path $projectRoot "SkyrimNetActions\mme_breastfeeding_drink_from_target.yaml")
)
$actionDestination = Join-Path $stageDir "SKSE\Plugins\SkyrimNet\config\actions"
New-Item -ItemType Directory -Force -Path $actionDestination | Out-Null
foreach ($milkShareAction in $milkShareActions) {
    if (!(Test-Path -LiteralPath $milkShareAction)) {
        throw "Required Skyrim.Net breastfeeding action is missing: $milkShareAction"
    }
    Copy-Item -LiteralPath $milkShareAction -Destination $actionDestination
}

# Install the late, actor-specific breastfeeding override after generic SexLab
# user-final-instruction modules without modifying SkyrimNet_SexLab itself.
$breastfeedingPrompt = Join-Path $projectRoot "SkyrimNetPrompts\0950_mme_extensions_breastfeeding.prompt"
if (!(Test-Path -LiteralPath $breastfeedingPrompt)) {
    throw "Required MME breastfeeding prompt is missing: $breastfeedingPrompt"
}
$breastfeedingPromptDestination = Join-Path $stageDir "SKSE\Plugins\SkyrimNet\prompts\submodules\user_final_instructions"
New-Item -ItemType Directory -Force -Path $breastfeedingPromptDestination | Out-Null
Copy-Item -LiteralPath $breastfeedingPrompt -Destination $breastfeedingPromptDestination

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
    # Dialogue response records are authored through xEdit. Refuse to ship an
    # older local ESP if the one-time response repair was not actually saved
    # back into the project after a successful SSEEdit run.
    $pluginText = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($pluginPath))
    $wantedMilkResponse = "Yes! I can't wait to be nice and heavy!"
    $staleMilkResponses = @(
        "I hope you will give me some good milking soon!",
        "I hope you will give me a good milking."
    )
    foreach ($staleMilkResponse in $staleMilkResponses) {
        if ($pluginText.Contains($staleMilkResponse)) {
            throw "MMEAlert.esp still contains the stale milk-dialogue response '$staleMilkResponse'. Run tools\RepairMMEExtensionsMilkDialogueResponses.pas in SSEEdit, save MMEAlert.esp, and copy that saved file into the project root before packaging."
        }
    }
    if (!$pluginText.Contains($wantedMilkResponse)) {
        throw "MMEAlert.esp is missing the intended milk-dialogue response '$wantedMilkResponse'. Repair the target INFO in SSEEdit before packaging."
    }
    if (!$pluginText.Contains("MMEExt_OStimDialogueAvailable") -or
        $pluginText.Contains("::OStimDialogueAvailable_var")) {
        throw "MMEAlert.esp still uses the unreliable OStim quest-variable dialogue gate. Run the updated tools\AddMMEExtensionsOStimBreastfeedingDialogue.pas in SSEEdit and save the plugin before packaging."
    }
    if (!$pluginText.Contains("MMEExt_OStimBreastfeeding_PlayerDrinksTopic") -or
        !$pluginText.Contains("MMEExt_OStimBreastfeeding_NPCDrinksTopic")) {
        throw "MMEAlert.esp still contains the obsolete same-DIAL OStim breastfeeding routes. Run the updated tools\AddMMEExtensionsOStimBreastfeedingDialogue.pas in SSEEdit and save the plugin before packaging."
    }
    if (!$pluginText.Contains("MMEExt_NewMilkMaidTopic") -or
        !$pluginText.Contains("MMEExt_NewMilkMaid") -or
        !$pluginText.Contains("MMEExt_SexLabNewMilkMaidTopic") -or
        !$pluginText.Contains("MMEExt_SexLabNewMilkMaid") -or
        !$pluginText.Contains("MMEExt_SexLabNewMilkMaidDialogueAvailable")) {
        throw "MMEAlert.esp is missing the separate OStim/SexLab New Milk Maid dialogue entrances. Run tools\AddMMEExtensionsSexLabNewMilkMaidDialogue.pas in SSEEdit and save the plugin before packaging."
    }
    if (!$pluginText.Contains("HearthFires.esm")) {
        throw "MMEAlert.esp is missing the supported-milk dialogue eligibility update. Run the updated tools\AddMMEExtensionsMilkDialogue.pas in SSEEdit and save the plugin before packaging."
    }
    if (!$pluginText.Contains("MMEExt_BlacksmithArmorState") -or
        !$pluginText.Contains("MMEExt_BlacksmithAddMilkArmorTopic") -or
        !$pluginText.Contains("MMEExt_BlacksmithRemoveMilkArmorTopic") -or
        !$pluginText.Contains("MMEBlacksmithDialogue") -or
        !$pluginText.Contains("Fragment_RefreshBlacksmithArmorState")) {
        throw "MMEAlert.esp is missing the Blacksmith armor-service records or opening wrapper. Run tools\AddMMEExtensionsBlacksmithDialogue.pas in SSEEdit, save MMEAlert.esp, and copy the Vortex-deployed saved plugin into the project root before packaging."
    }
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
