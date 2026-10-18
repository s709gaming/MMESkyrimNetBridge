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
Assert-Contract ($service.Contains('Your chests have gotten too big! Visit the blacksmith!')) "approved successful-removal reminder is exact"
Assert-Contract ($service -match 'RemovalNoticeShownKey' -and $service -match 'successful removal reminder already shown') "successful-removal reminder is once per pending refit episode"
Assert-Contract ($service -notmatch 'ShowReminder\(playerActor' -and $service -match 'Function HandleSuccessfulRemoval') "level-up and equip observation remain silent until verified removal"
Assert-Contract ($service -match 'wearer != Game\.GetPlayer\(\)') "refit stripping exception is player-only"
Assert-Contract ($service -match 'wornArmor == milkController\.MilkCuirass' -and $service -match 'wornArmor == milkController\.MilkCuirassFuta') "original MME cuirasses are always excluded"
Assert-Contract ($service -match 'FindBasicLivingArmorNameDirect' -and $service -match 'FindParasiteLivingArmorNameDirect') "Living and Parasite armor remain excluded"
Assert-Contract ($service -match 'customClass == 4[\s\S]*Return True' -and $service -match 'unlocked Dwemer Armor protection bypass permitted') "independent Dwemer Armor joins refit eligibility"
Assert-Contract ($service -match 'CountMilkingEquipmentMatchesDirect\(milkController, armorName\) == 1') "only an exact ordinary MilkingEquipment registration qualifies"
Assert-Contract ($service -match 'The pending fit state is the service ticket' -and $service -match 'String refitContext = "off-body"') "pending refit can be serviced without wearing the undersized equipment"
Assert-Contract ($service -notmatch 'eligible registered Milking Equipment is no longer worn') "refit completion has no circular worn-armor requirement"
Assert-Contract ($armor -match 'MMEMilkingEquipmentRefit\.ShouldBypassMilkingEquipmentProtection' -and $armor -match 'IsMilkingBlocked_Suit' -and $armor -match 'IsStripSafeByFramework') "narrow exception retains framework safety gates"
Assert-Contract ($armor.IndexOf('MMETimedArmorLock.IsLocked(target)') -lt $armor.IndexOf('MMEMilkingEquipmentRefit.ShouldBypassMilkingEquipmentProtection')) "active timed armor lock is rejected before the refit bypass"
Assert-Contract ($armor -match 'Bool refitProtectionBypassed = False' -and $armor -match 'HandleSuccessfulArmorStrip\(target, slotArmor, fullnessPct, threshold, sourceLabel, refitProtectionBypassed\)') "verified stripping carries refit provenance into presentation"
Assert-Contract ($armor -match 'If refitRemoval[\s\S]*MMEMilkingEquipmentRefit\.HandleSuccessfulRemoval[\s\S]*Else[\s\S]*HandleArmorStripNotification') "refit removal substitutes its actionable reminder for the generic strip notification"
Assert-Contract ($controller -match 'HandleArmorEquipped\(wearer, equippedArmor\)' -and $controller -match 'MMEMilkingEquipmentRefit\.Reconcile\("MME milk cycle completed"\)') "native equip and authoritative MME cycle routes feed the service"
Assert-Contract ($mcm -match 'Return (14[4-9]|1[5-9][0-9])' -and $mcm -match 'Require Milking Equipment Refits' -and $mcm -match 'enableMilkingEquipmentRefits", 1') "MCM migration and default-on dependent toggle exist"
Assert-Contract ($mcm -match 'ordinary Milking Equipment and unlocked Dwemer Armor' -and $mcm -match 'Timed locks, Devious Devices, Living Armor, Parasite Armor') "MCM explains Dwemer eligibility and retained lock protections"
Assert-Contract ($dialogue -match 'MMEExt_MilkingEquipmentRefitState' -and $dialogue -match 'Fragment_RefitMilkingEquipment') "blacksmith wrapper exposes state and completion fragment"
Assert-Contract ($dialogue -match 'Game\.GetFormFromFile\(0x[0-9A-Fa-f]+, "MMEAlert\.esp"\) as GlobalVariable') "existing saves can recover a stale unbound refit dialogue Global"
Assert-Contract ($service -match 'MMELog\.MasterDiagnostic' -and $service -match 'MMELog\.Alarm') "master footprints and smoke alarms are present"
Assert-Contract ($build -match '"MMEMilkingEquipmentRefit"' -and $build -match 'Test-MilkingEquipmentRefitContracts') "release build compiles and tests the service"
