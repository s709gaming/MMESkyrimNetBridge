$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$service = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMESelfMilking.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$voice = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMESkyrimNetVoiceControls.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) {
        throw "FAIL: $message"
    }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($service -notmatch 'RegisterFor(Update|SingleUpdate|UpdateGameTime|SingleUpdateGameTime)') "self-milking facade owns no polling registration"
Assert-Contract ($service -match 'milkController\.MilkSelf\.Cast\(candidate\)') "facade dispatches MME's existing MilkSelf spell"
Assert-Contract ($service -match 'BeingMilkedPassive' -and $service -match 'MMEAlerts\.IsMilking') "facade rejects both MME and bridge active-milking states"
Assert-Contract ($controller -match 'If crossing == 2\s+QueueAutoSelfMilking\(candidate\)') "Milk Full crossing queues auto self-milking"
Assert-Contract ($controller -match 'StorageUtil\.FormListAdd\(None, AutoSelfMilkingPendingKey, candidate, False\)') "controller keeps a duplicate-safe persistent actor queue"
Assert-Contract ($controller -match 'NextAutoSelfMilkingGameTime > 0\.0.*nextDeadline') "auto self-milking shares the controller game-time scheduler"
Assert-Contract ($controller -match 'ConfirmOrCancelAutoSelfMilking\(milkMaid\)') "authoritative MME start event clears or confirms pending work"
Assert-Contract ($controller -match 'MMELog\.MasterDiagnostic\("\[MME Extensions Auto Self-Milking\]') "normal footprints use master Papyrus logging"
Assert-Contract ($controller -match 'MMELog\.Alarm\("\[MME Extensions Auto Self-Milking\] FAILURE:') "dependency and dispatch failures use smoke alarms"
Assert-Contract ($mcm -match 'Return 13[5-9]|Return 1[4-9][0-9]') "MCM version retains auto self-milking migration 134 or later"
Assert-Contract ($mcm -match '"enableAutoSelfMilking", 1') "Auto Self-Milking defaults on"
Assert-Contract ($mcm -match '"autoSelfMilkingDelayHours", 1\.0') "self-milking delay defaults to one game hour"
Assert-Contract ($mcm -match 'autoSelfMilkingDelayOption[\s\S]*SetSliderDialogRange\(0\.0, 24\.0\)') "MCM delay spans zero to 24 game hours"
Assert-Contract ($voice -match 'MMESelfMilking\.StartExisting\(candidate, False, False, False\)') "Skyrim.Net action delegates to the shared facade"
Assert-Contract ($build -match '"MMESelfMilking"') "build compiles and packages the facade"
