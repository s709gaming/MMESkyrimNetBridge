$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$facade = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEElsieBreastfeeding.psc") -Raw
$debug = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDebug.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$fomod = Get-Content -LiteralPath (Join-Path $projectRoot "FOMOD\ModuleConfig.xml") -Raw
$markerPath = Join-Path $projectRoot "fomod\choices\elsie-compatibility\ElsieCompatibility.json"

foreach ($required in @(
    'GetbyRegistrar("ELV_Taste")',
    'StartAutonomousFeed',
    'SexLab.StartSex(participants, animations)',
    'RunNearbyTest',
    'MMEExtensionsNative.GetNearbyActors',
    'enableElsieBreastfeedingMilkEffects',
    'ElsieCompatibility'
)) {
    if ($facade -notmatch [regex]::Escape($required)) { throw "Elsie facade is missing: $required" }
}
if ($debug -notmatch 'MMEElsieBreastfeeding\.IsTasteAnimation' -or $debug -notmatch 'CompleteBreastfeedingDrink\(completedSource, completedDrinker, "SexLab"') {
    throw "SexLab completion listener no longer routes Elsie through the shared breastfeeding transaction"
}
if ($mcm -notmatch 'Elsie LaVache Detected' -or $mcm -notmatch 'Elsie Breastfeeding Gives Milk' -or $mcm -notmatch 'Test Elsie Auto Breastfeeding' -or $mcm -notmatch 'MMEElsieBreastfeeding\.RunNearbyTest' -or $mcm -notmatch 'elsieBreastfeedingMigration145') {
    throw "Elsie MCM controls or existing-save migration are incomplete"
}
foreach ($overrideName in @('ELV_MMNPC_Scene_milk', 'ELV_MMNPC_Scene_milkingTime')) {
    $overridePath = Join-Path $projectRoot "fomod\choices\elsie-compatibility\Source\Scripts\$overrideName.psc"
    if (!(Test-Path -LiteralPath $overridePath)) { throw "Elsie autonomous override is missing: $overrideName" }
    $override = Get-Content -LiteralPath $overridePath -Raw
    if ($override -notmatch 'MMEElsieBreastfeeding\.StartAutonomousFeed') { throw "Elsie autonomous override bypasses the checked starter: $overrideName" }
}
if (!(Test-Path -LiteralPath $markerPath) -or $fomod -notmatch 'ElsieCompatibility\.json' -or $fomod -notmatch 'Recommended Compatibility Patch') {
    throw "Elsie FOMOD marker or presentation is incomplete"
}
Write-Host "Elsie breastfeeding contracts passed." -ForegroundColor Green
