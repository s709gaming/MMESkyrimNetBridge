$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$lockScript = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMETimedArmorLock.psc") -Raw
$trapScript = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEChestArmorTrap.psc") -Raw
$nativeSource = Get-Content -LiteralPath (Join-Path $projectRoot "src\Plugin.cpp") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$fomod = Get-Content -LiteralPath (Join-Path $projectRoot "fomod\ModuleConfig.xml") -Raw
$c5 = Get-Content -LiteralPath (Join-Path $projectRoot "fomod\choices\timed-armor-c5kev\TimedArmor_C5Kev.json") -Raw | ConvertFrom-Json
$dwemer = Get-Content -LiteralPath (Join-Path $projectRoot "fomod\choices\timed-armor-dwemer\TimedArmor_Dwemer.json") -Raw | ConvertFrom-Json
$notifications = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\TimedArmorNotifications.json") -Raw | ConvertFrom-Json
$dialogue = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMETrapArmorDialogue.psc") -Raw
$dialogueFragments = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEBlacksmithDialogue.psc") -Raw

function Assert-Match([string]$Text, [string]$Pattern, [string]$Message) {
    if ($Text -notmatch $Pattern) { throw $Message }
}

if ($c5.timed_armor_forms.Count -ne 6) { throw "C5Kev provider must contain exactly six cuirasses." }
foreach ($id in 3427, 4848, 4851, 4874, 4877, 4895) {
    if (-not ($c5.timed_armor_forms -match "\|$id\|")) { throw "Missing C5Kev cuirass local FormID $id." }
}
if ($dwemer.timed_armor_forms.Count -ne 1 -or $dwemer.timed_armor_forms[0] -notmatch "DwarvenDeviousCuirass\.esp\|2048\|4\|") {
    throw "Dwemer provider must contain only the unenchanted cuirass 0x800."
}

Assert-Match $lockScript 'Armor\.GetMaskForSlot\(32\)' "Timed armor registration must enforce slot 32."
if ($lockScript -match 'EquipItem\(targetArmor, True, True\)') { throw "Timed armor must not invoke Skyrim's generic hard-lock rejection." }
Assert-Match $lockScript 'EquipItem\(targetArmor, False, True\)' "Timed armor must silently restore the removed armor through the native event path."
Assert-Match $lockScript 'ShowUnequipResistedNotification\(target\)' "A resisted removal must show the playful JSON notification."
Assert-Match $lockScript 'The armor magically wraps around you\. Enjoy it for the next ' "Initial trapped-armor notification is missing."
Assert-Match $lockScript 'MMELog\.MasterDiagnostic' "Timed armor footprints must use the master trace gate."
Assert-Match $lockScript 'MMELog\.Alarm' "Timed armor needs smoke alarms for material failures."
Assert-Match $controller 'MMETimedArmorLock\.GetNextDeadline\(\)' "Controller shared scheduler is missing the timed armor deadline."
Assert-Match $controller 'MMETimedArmorLock\.ResolveDue\(now\)' "Controller does not resolve expired timed armor."
Assert-Match $mcm '"timedArmorLockDays", 3\.0' "MCM default must be three game days."
Assert-Match $mcm 'SetSliderDialogRange\(0\.0, 30\.0\)' "MCM lock duration must span 0-30 days."
foreach ($setting in 'enableLivingArmorChestTrap', 'enableParasiteArmorChestTrap', 'enableDwemerArmorChestTrap') {
    Assert-Match $mcm ('"' + $setting + '", 1') "MCM must expose and default-enable $setting."
    Assert-Match $trapScript ('"' + $setting + '", 1') "Trap selection must enforce $setting."
}
Assert-Match $nativeSource 'event->menuName != RE::ContainerMenu::MENU_NAME' "Player traps must wait for the actual container menu."
Assert-Match $nativeSource 'activator != RE::PlayerCharacter::GetSingleton\(\)' "Raw player activation must not dispatch a chest trap before lockpicking."
Assert-Match $nativeSource 'chest->IsLocked\(\)' "NPC chest activation must reject locked containers."
Assert-Match $api 'Return 10' "Public API version must be 10."
Assert-Match $api 'Function RegisterTimedArmor' "Public registration facade is missing."
Assert-Match $api 'Function ReleaseTimedArmor' "Public release facade is missing."
Assert-Match $fomod "C5Kev's Tentacled Terrors Of Tamriel 3BA\.esp" "FOMOD C5Kev auto-detection is missing."
Assert-Match $fomod 'DwarvenDeviousCuirass\.esp' "FOMOD Dwemer auto-detection is missing."
Assert-Match $fomod 'Trap Treasure Chest with Tentacle Armor' "Requested Tentacle Armor FOMOD label is missing."
Assert-Match $fomod 'Trap Treasure Chest with Devious Dwemer Armor' "Requested Dwemer Armor FOMOD label is missing."
if ($notifications.stringList.unequip_resisted.Count -lt 4) { throw "Timed armor needs at least four playful removal messages." }
Assert-Match $build 'TimedArmorNotifications\.json' "Build must package the editable timed-armor notification pool."
Assert-Match $dialogue 'GetRegisteredArmorClass\(lockedArmor\)' "Vendor removal must classify the exact registered locked armor."
Assert-Match $dialogue '!playerActor\.IsEquipped\(lockedArmor\)' "Vendor removal must reject stale or replaced armor."
Assert-Match $dialogue 'MMETimedArmorLock\.Release\(playerActor, "Vendor Assistance"\)' "Vendor removal must use the canonical timed-lock release path."
Assert-Match $dialogue 'armorClass == 4 && !speaker\.IsInFaction\(blacksmithFaction\)' "Dwemer armor must route to blacksmiths."
Assert-Match $dialogue 'armorClass == 2 \|\| armorClass == 3' "Living and parasite armor classes must share the magic-service route."
Assert-Match $dialogue '!speaker\.IsInFaction\(apothecaryFaction\) && !speaker\.IsInFaction\(courtWizardFaction\)' "Living and parasite armor must route to alchemists or court wizards."
Assert-Match $dialogueFragments 'Fragment_RemoveTimedTrapArmor' "The dialogue result fragment for timed armor release is missing."
Assert-Match $dialogueFragments 'SetTrapArmorDialogueState' "The opening wrapper does not refresh the timed armor dialogue gate."

Write-Host "Timed armor lock contracts passed."
