$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$story = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEStoryPopup.psc") -Raw
$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
$dwemer = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDwemerArmor.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$stories = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\DwemerArmorStories.json") -Raw | ConvertFrom-Json

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($api -match 'Return 8' -and $api -match 'Bool Function ShowStoryPopup\(' -and $api -match 'Bool Function ShowRandomStoryPopup\(') "public API version 8 exposes direct and pooled story calls"
Assert-Contract ($story -match 'Debug\.MessageBox\(renderedStory\)' -and $story -match 'Return True') "valid story text reaches Skyrim's game-pausing message box"
Assert-Contract ($story -match 'JsonUtil\.JsonExists\(configFile\)' -and $story -match 'JsonUtil\.IsGood\(configFile\)') "pooled stories validate JSON existence and parsing"
Assert-Contract ($story -match 'JsonUtil\.StringListCount\(configFile, poolName\)' -and $story -match 'JsonUtil\.StringListGet\(configFile, poolName') "pooled stories use MME-compatible typed stringList access"
Assert-Contract ($story -match 'Return ShowFallback\(subject, fallbackText, sourceLabel, poolName\)') "missing, malformed, empty, and blank selections share fallback handling"
Assert-Contract ($story -match '"\{actor\}"' -and $story -match '"\{ActorName\}"') "both supported actor-name tokens are rendered"
Assert-Contract ($story -match 'MMELog\.MasterDiagnostic\(' -and $story -match 'MMELog\.Alarm\(') "ordinary footprints and smoke-alarm failures use established logging"
Assert-Contract ($story -notmatch 'RegisterForUpdate|RegisterForSingleUpdate|Event OnUpdate|StorageUtil\.Set') "story facade adds no polling, registrations, or persistent state"
Assert-Contract ($dwemer -match 'MMEStoryPopup\.ShowRandomStoryPopup' -and $dwemer -notmatch 'Debug\.MessageBox') "Dwemer stories delegate presentation to the shared facade"
Assert-Contract ($stories.stringList.dwemerarmorstart.Count -gt 0 -and $stories.stringList.dwemerarmorend.Count -gt 0) "Dwemer story data follows original MME stringList structure"
Assert-Contract ($build -match '"MMEStoryPopup"' -and $build -match 'Test-StoryPopupContracts\.ps1') "release build compiles the facade and runs its contracts"
