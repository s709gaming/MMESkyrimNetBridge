$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$effect = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDwemerEffects.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$net = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsSkyrimNet.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$notifications = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\DwemerEffectNotifications.json") -Raw | ConvertFrom-Json
$narration = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\Narration\DwemerArmor.json") -Raw | ConvertFrom-Json

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($effect -match 'armorClass == 4' -and $effect -notmatch 'armorClass == 2 \|\| armorClass == 3') "Dwemer effects accept only independent armor class 4"
Assert-Contract ($effect -match 'ApplyMilkDrinkBonusForActor' -and $effect -match 'ApplyConfiguredMilkArousalForActor') "Dwemer effects reuse the proven milk and arousal helpers"
Assert-Contract ($effect -notmatch 'RegisterForUpdate|RegisterForSingleUpdate|Event OnUpdate') "new feature creates no independent polling loop"
Assert-Contract ($controller -match 'NextDwemerEffectGameTime' -and $controller -match 'dwemerEffectDue' -and $controller -match 'MMEDwemerEffects\.RunEffectCheck\(nearbyActors') "controller owns the independent Dwemer deadline and shared scan"
Assert-Contract ($mcm -match 'Return 13[6-9]|Return 1[4-9][0-9]' -and $mcm -match 'dwemerEffectMigration135' -and $mcm -match 'AddHeaderOption\("Dwemer Armor"\)') "MCM retains the parallel Dwemer section and migration"
Assert-Contract ($mcm -match 'dwemerEffectInterval", 12\.0' -and $mcm -match 'dwemerEffectVariation", 4\.0' -and $mcm -match 'dwemerEffectChance", 100') "Dwemer cadence defaults mirror Tentacle Effects"
Assert-Contract ($net -match 'NarrateDwemerEffect' -and $net -match 'OnDwemerEffectPlayerLine' -and $net -match 'TriggerPlayerTTS') "Skyrim.Net supports affected NPC speech and player-only TTS"
Assert-Contract ($narration.routes.build_dwemer_effect_narration_1.template -match "Dwemer machinery's mechanical teasing as pleasurable, silly, playful, positive, and suggestive" -and (Get-Content (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\Narration\TentacleArmor.json") -Raw) -match "living or parasite armor's teasing as pleasurable, silly, playful, positive, and suggestive") "periodic Dwemer and Tentacle narration enforce the upbeat teasing tone"
Assert-Contract ($effect -match 'MMELog\.MasterDiagnostic' -and $effect -match 'MMELog\.Alarm') "normal footprints use the master toggle and real failures use smoke alarms"
Assert-Contract ($notifications.lines.Count -eq 5) "notification JSON contains the five supplied base lines"
Assert-Contract ($narration.routes.effects_arousal.template.Count -gt 0 -and $narration.routes.effects_milk.template.Count -gt 0 -and $narration.routes.effects_milkAndArousal.template.Count -gt 0) "narration JSON covers all verified gameplay outcomes"
Assert-Contract ($build -match '"MMEDwemerEffects"' -and $build -match 'DwemerEffectNotifications\.json' -and $build -match 'DwemerEffectNarration\.json') "release build compiles and packages the feature"
