$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$service = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEMaidWeightScaling.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "Maid weight contract failed: $message" }
    Write-Host "PASS: $message"
}

Assert-Contract ($service -match 'BaselineKey' -and $service -match 'LastAppliedKey' -and $service -match 'RestoreActor') "weight ownership has symmetric baseline restoration"
Assert-Contract ($service -match 'MMEArmorScript\.IsMMEMilkMaid' -and $service -notmatch 'controller\.MilkMaid' -and $service -notmatch 'RegisterForUpdate') "service uses compatibility-safe MME authority without external array access or polling"
Assert-Contract ($service -match 'SetWeight\(' -and $service -match 'UpdateWeight\(') "weight writes include the required visual refresh"
Assert-Contract ($service -match 'external weight change rebased') "later appearance changes are preserved by delta rebasing"
Assert-Contract ($controller -match 'OnMenuClose\(String menuName\)[\s\S]*Journal Menu[\s\S]*MMEMaidWeightScaling\.ReconcileAll') "closing either MCM reconciles original MME level edits"
Assert-Contract ($controller -match 'MME milk cycle completed' -and $controller -match 'MME milking completed' -and $controller -match 'Milk Maid created') "authoritative gameplay transitions reconcile weight"
Assert-Contract ($controller -match 'ModEvent\.Send\(handle\)[\s\S]*MMEMaidWeightScaling\.ReconcileActor\(candidate, "Milk Maid created"\)') "cosmetic weight work cannot interrupt conversion feedback or its public event"
Assert-Contract ($mcm -match 'Return 143' -and $mcm -match 'Scale Weight with Maid Level' -and $mcm -match 'SetSliderDialogRange\(0\.0, 10\.0\)' -and $mcm -match 'SetSliderDialogInterval\(1\.0\)') "MCM migration, default-on toggle and 0-10 step-1 slider exist"
Assert-Contract ($build -match '"MMEMaidWeightScaling"') "release build compiles and packages the service"
