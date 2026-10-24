$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "Breast bounce contract failed: $message" }
}

$effect = Get-Content -LiteralPath (Join-Path $projectRoot 'Source\Scripts\MMEBreastBounceEffects.psc') -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot 'Source\Scripts\MMEAlertsController.psc') -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot 'Source\Scripts\MMEAlertsMCM.psc') -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot 'build-package.ps1') -Raw
$soundPatch = Get-Content -LiteralPath (Join-Path $projectRoot 'tools\AddMMEBreastBounceSound.pas') -Raw
$jsonPath = Join-Path $projectRoot 'SKSE\Plugins\StorageUtilData\MMEAlerts\BreastBounceNotifications.json'
$json = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$wav = Join-Path $projectRoot 'assets\sounds\Tit Slap Sounds\tit slap sound loop.wav'

Assert-Contract ($effect.Contains('Scriptname MMEBreastBounceEffects Hidden')) 'isolated effect facade is missing'
Assert-Contract ($effect.Contains('Utility.RandomInt(1, eligibleCount)')) 'uniform reservoir selection is missing'
Assert-Contract ($effect.Contains('(current / maximum) >= 0.5')) '50-percent fullness split is missing'
Assert-Contract ($effect.Contains('0x0008B1') -and !$effect.Contains('MME Extensions - Breast Bounce Sounds.esp')) 'MMEAlert breast-slap SOUN marker is missing'
Assert-Contract ($controller.Contains('NextBreastBounceGameTime')) 'game-time schedule is missing'
Assert-Contract ($controller.Contains('NextBreastBouncePresentation')) 'real-time delayed presentation is missing'
Assert-Contract ($mcm -match 'Return 15[3-9]') 'MCM migration version is older than 153'
Assert-Contract ($mcm.Contains('Breast Bounce Notifications') -and $mcm.Contains('Breast Bounce Sounds')) 'MCM toggles are missing'
Assert-Contract ($json.low.Count -ge 5 -and $json.high.Count -ge 5) 'notification pools are incomplete'
Assert-Contract (Test-Path -LiteralPath $wav) 'converted slap WAV is missing'
Assert-Contract (!$build.Contains('sound-record-builder') -and !$build.Contains('MME Extensions - Breast Bounce Sounds.esp')) 'obsolete companion sound plugin is still packaged'
Assert-Contract ($soundPatch.Contains("DescriptorLocalID = `$0008B0") -and $soundPatch.Contains("MarkerLocalID = `$0008B1") -and $soundPatch.Contains('MMEAlerts_SOUN_BreastSlap')) 'single-ESP sound record patch is incomplete'
Assert-Contract ($build.Contains('MMEBreastBounceEffects') -and $build.Contains('BreastBounceNotifications.json')) 'build packaging is incomplete'

Write-Host 'Breast bounce contracts passed.'
