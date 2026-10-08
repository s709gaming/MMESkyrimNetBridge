$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$service = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEMilkingEquipmentRefit.psc") -Raw
$armor = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorScript.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$dialogue = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEBlacksmithDialogue.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "Milking refit contract failed: $message" }
    Write-Host "PASS: $message"
}

Assert-Contract ($service -match 'LastObservedLevelKey' -and $service -match 'FittedLevelKey' -and $service -match 'NeedsRefitKey') "service owns persistent level and refit state"
Assert-Contract ($service -match 'currentLevel > previousLevel' -and $service -match 'currentLevel < previousLevel && currentLevel <= fittedLevel') "level increases arm and compatible decreases clear the refit"
Assert-Contract ($service.Contains('Your chests have gotten too big! Visit the blacksmith!')) "approved short equip reminder is exact"
Assert-Contract ($service -match 'now - last < 5\.0') "equip reminder is rate-limited"
Assert-Contract ($service -match 'wearer != Game\.GetPlayer\(\)') "refit stripping exception is player-only"
Assert-Contract ($service -match 'wornArmor == milkController\.MilkCuirass' -and $service -match 'wornArmor == milkController\.MilkCuirassFuta') "original MME cuirasses are always excluded"
Assert-Contract ($service -match 'FindBasicLivingArmorNameDirect' -and $service -match 'FindParasiteLivingArmorNameDirect' -and $service -match 'ClassifyCustomArmor') "special armor categories are excluded"
Assert-Contract ($service -match 'CountMilkingEquipmentMatchesDirect\(milkController, armorName\) == 1') "only an exact ordinary MilkingEquipment registration qualifies"
Assert-Contract ($armor -match 'MMEMilkingEquipmentRefit\.ShouldBypassMilkingEquipmentProtection' -and $armor -match 'IsMilkingBlocked_Suit' -and $armor -match 'IsStripSafeByFramework') "narrow exception retains framework safety gates"
Assert-Contract ($controller -match 'HandleArmorEquipped\(wearer, equippedArmor\)' -and $controller -match 'MMEMilkingEquipmentRefit\.Reconcile\("MME milk cycle completed"\)') "native equip and authoritative MME cycle routes feed the service"
Assert-Contract ($mcm -match 'Return 144' -and $mcm -match 'Require Milking Equipment Refits' -and $mcm -match 'enableMilkingEquipmentRefits", 1') "MCM migration and default-on dependent toggle exist"
Assert-Contract ($dialogue -match 'MMEExt_MilkingEquipmentRefitState' -and $dialogue -match 'Fragment_RefitMilkingEquipment') "blacksmith wrapper exposes state and completion fragment"
Assert-Contract ($service -match 'MMELog\.MasterDiagnostic' -and $service -match 'MMELog\.Alarm') "master footprints and smoke alarms are present"
Assert-Contract ($build -match '"MMEMilkingEquipmentRefit"' -and $build -match 'Test-MilkingEquipmentRefitContracts') "release build compiles and tests the service"
