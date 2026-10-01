$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$service = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEMilkCravings.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$skyrimNet = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsSkyrimNet.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$jsonPath = Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\MilkCravings.json"
$messages = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) {
        throw "FAIL: $message"
    }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($messages.craving.Count -gt 0) "craving JSON pool is populated"
Assert-Contract ($messages.give_in.Count -gt 0) "give-in JSON pool is populated"
foreach ($entry in @($messages.craving) + @($messages.give_in)) {
    Assert-Contract (![string]::IsNullOrWhiteSpace($entry)) "craving JSON entry is nonempty"
    Assert-Contract ($entry -match '\{ActorName\}|\{actor\}') "craving JSON entry has a supported actor token"
}

Assert-Contract ($service -notmatch 'RegisterFor(Update|SingleUpdate|UpdateGameTime|SingleUpdateGameTime)') "craving helper owns no polling registration"
Assert-Contract ($service -match 'MMEExtensionsAPI\.DrinkNormalMilk\(cravingActor\)') "give-in uses the public normal-milk API"
Assert-Contract ($service -match 'MMELog\.Alarm\("\[MME Extensions Milk Craving\] FAILURE:') "craving failures use the smoke-alarm channel"
Assert-Contract ($service -match 'MMELog\.MasterDiagnostic\("\[MME Extensions Milk Craving\]') "normal craving breadcrumbs use master logging"
Assert-Contract ($controller -match 'Float NextMilkCravingGameTime') "controller owns the craving-cycle deadline"
Assert-Contract ($controller -match 'Float NextMilkCravingGiveInGameTime') "controller owns the give-in deadline"
Assert-Contract ($controller -match 'MMEMilkCravings\.BeginCraving\(nearbyActors\)') "controller reuses the shared nearby scan"
Assert-Contract ($controller -match 'NextMilkCravingGameTime > 0\.0.*nextDeadline' -and $controller -match 'NextMilkCravingGiveInGameTime > 0\.0.*nextDeadline') "both craving deadlines participate in the shared scheduler"

Assert-Contract ($mcm -match 'Return 13[4-9]|Return 1[4-9][0-9]') "MCM version includes craving migration 133 or later"
Assert-Contract ($mcm -match '"enableMilkCravings", 1') "Milk Cravings default on"
Assert-Contract ($mcm -match '"milkCravingIntervalHours", 48\.0') "craving interval defaults to 48 game hours"
Assert-Contract ($mcm -match '"milkCravingIntervalVariation", 24\.0') "craving variation defaults to 24 game hours"
Assert-Contract ($mcm -match 'SetSliderDialogInterval\(5\.0\)') "MCM exposes five-percent slider steps"
Assert-Contract ($skyrimNet -match 'DirectNarration\(content, cravingActor, listener\)') "NPC craving narration selects the affected actor as speaker"
Assert-Contract ($skyrimNet -match 'OnMilkCravingPlayerLine' -and $skyrimNet -match 'TriggerPlayerTTS\(response\)') "player craving narration has a player-only TTS callback"
Assert-Contract ($skyrimNet -match 'RenderToken\(rendered, "\{ActorName\}"') "message renderer supports the supplied ActorName token"
Assert-Contract ($build -match '"MMEMilkCravings"') "build compiles and packages the craving script"
Assert-Contract ($build -match '"MilkCravings\.json"') "build packages the craving JSON"
