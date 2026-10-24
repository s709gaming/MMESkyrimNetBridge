$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $projectRoot "fomod\choices\jugs-compatibility\Source\Scripts"
$fomod = Get-Content -LiteralPath (Join-Path $projectRoot "fomod\ModuleConfig.xml") -Raw

$sceneSources = @(Get-ChildItem -LiteralPath $sourceDir -Filter "*.psc" | Where-Object {
    (Get-Content -LiteralPath $_.FullName -Raw) -match 'MMEJugsSafety\.TryStart'
})
if ($sceneSources.Count -ne 39) {
    throw "Expected 39 guarded JUGS scene fragments; found $($sceneSources.Count)"
}
foreach ($sceneSource in $sceneSources) {
    $content = Get-Content -LiteralPath $sceneSource.FullName -Raw
    if ($content -match 'SexLab\.StartSex\(') {
        throw "Direct SexLab.StartSex remains in $($sceneSource.Name)"
    }
}

$safety = Get-Content -LiteralPath (Join-Path $sourceDir "MMEJugsSafety.psc") -Raw
foreach ($required in @('GetState\(\) != "Enabled"', 'IsValidActor', 'animations\.Length < 1', 'threadID < 0', 'MMELog\.MasterDiagnostic', 'MMELog\.Alarm')) {
    if ($safety -notmatch $required) { throw "JUGS safe starter is missing contract: $required" }
}

$listener = Get-Content -LiteralPath (Join-Path $sourceDir "JugsPlayerAlias.psc") -Raw
$lengthGuard = $listener.IndexOf('participants.Length < 2')
$firstIndexRead = $listener.IndexOf('participants[0]')
if ($lengthGuard -lt 0 -or $firstIndexRead -lt 0 -or $lengthGuard -gt $firstIndexRead) {
    throw "JUGS listener reads participants before validating the array length"
}
foreach ($required in @('raw0=', 'unresolved milk-source role', 'AnimationEnding', 'MMEJugsSafety\.IsOwnedParticipant', 'MMEExtensionsAPI\.CompleteBreastfeedingMilkShare')) {
    if ($listener -notmatch $required) { throw "JUGS listener is missing P+ role recovery contract: $required" }
}
if ($listener -match 'MMEExtensionsAPI\.(ForceMilkDrink|DrinkNormalMilk|GiveAvailableMilk)') {
    throw "JUGS breastfeeding completion must not invoke an inventory/cup-drinking API"
}

$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
foreach ($required in @('CompleteBreastfeedingMilkShare', 'service\.CompleteBreastfeedingDrink', 'IsMilkMaid\(milkSource\)', 'persistent breastfeeding service unavailable')) {
    if ($api -notmatch $required) { throw "Public breastfeeding completion API is missing contract: $required" }
}

foreach ($required in @('MME\.Extensions\.JUGS\.Thread', 'MME\.Extensions\.JUGS\.Role', 'StorageUtil\.SetIntValue', 'ClearOwnedParticipant')) {
    if ($safety -notmatch $required) { throw "JUGS ownership marker is missing contract: $required" }
}

$main = Get-Content -LiteralPath (Join-Path $sourceDir "JugsMain.psc") -Raw
foreach ($required in @('duplicate SGO pair ignored', 'SGO queue full', 'If !removed\s+i \+= 1', 'Int lastActive = numParticipants - 1')) {
    if ($main -notmatch $required) { throw "JUGS queue repair is missing contract: $required" }
}

$makeMaid = Get-Content -LiteralPath (Join-Path $sourceDir "JUGs_MakeAMaid1C024.psc") -Raw
if ($makeMaid -notmatch 'MMEExtensionsAPI\.TryCreateMilkMaidForcedAnimated' -or $makeMaid -match 'GetFormFromFile') {
    throw "JUGS make-a-maid route must use the public animated API without hard-coded armor"
}

if ($fomod -notmatch 'JUGS — Stability and MME Compatibility Patch' -or
    $fomod -notmatch '<fileDependency file="Jugs\.esp" state="Active"' -or
    $fomod -notmatch 'fomod\\choices\\jugs-compatibility\\Scripts') {
    throw "JUGS optional FOMOD component or automatic detection is incomplete"
}

Write-Host "JUGS compatibility contracts passed." -ForegroundColor Green
