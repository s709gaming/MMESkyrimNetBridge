$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$intro = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorIntroduction.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$animation = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEReactionAnimation.psc") -Raw
$sounds = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEReactionSounds.psc") -Raw
$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$stories = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\ArmorIntroductionStories.json") -Raw | ConvertFrom-Json
$alchemist = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlchemistDialogue.psc") -Raw
$mage = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEMageDialogue.psc") -Raw
$dwemerBlacksmith = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDwemerBlacksmithDialogue.psc") -Raw
$blacksmith = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEBlacksmithDialogue.psc") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($intro -match 'target != Game\.GetPlayer\(\)' -and $controller -match 'MMEArmorIntroduction\.TryAutomatic') "automatic pausing introductions are player-only"
Assert-Contract ($intro -match 'armorClass == 1 \|\| armorClass == 2 \|\| armorClass == 3 \|\| armorClass == 4') "Milking, Living, Parasite, and Dwemer categories qualify"
Assert-Contract ($intro -match 'MMEExtensions\.ArmorIntroduction\.Living' -and $intro -match 'MMEExtensions\.ArmorIntroduction\.Parasite' -and $intro -match 'MMEExtensions\.ArmorIntroduction\.Dwemer') "completion is tracked per actor and category"
Assert-Contract ($intro -match 'StartPresentationKneeling' -and $intro -match 'PlayPresentationHighMoan' -and $intro -match 'ShowRandomStoryPopup') "sequence reuses safe animation, high sound, and shared story facade"
Assert-Contract ($animation -match 'Bool Function StartPresentationKneeling' -and $animation -match 'GetStartBlockReason' -and $animation -match 'TryAcquire') "presentation animation retains shared safety and ownership"
Assert-Contract ($sounds -match 'Int Function PlayPresentationHighMoan' -and $sounds -match 'PlayPresentationHighMoan[\s\S]*Return instance[\s\S]*EndFunction') "presentation sound uses a standalone helper without conversion gating"
Assert-Contract ($intro -notmatch 'AssignSlotMaid|MakeTargetNewMilkMaid|TryCreateMilkMaidForcedAnimated') "presentation facade does not convert the actor"
Assert-Contract ($intro -match '!trapStory && !MMEArmorScript\.IsMMEMilkMaid\(target, milkController\)' -and $intro -match 'ordinary armor-story wearer is not a Milk Maid') "ordinary and artisan armor stories reject non-Milk-Maid wearers while confirmed trap stories remain eligible"
Assert-Contract ($animation -match 'StartPresentationKneeling[\s\S]*LockMovement\(target, owner, requestLabel\)' -and $animation -match 'Function LockMovement' -and $animation -match 'Function UnlockMovement') "armor presentations lock and release translation for players and NPCs"
Assert-Contract ($animation -match 'MovementActors' -and $animation -match 'FormListAdd\(None, GetMovementActorListKey\(\), target, False\)' -and $animation -match 'FormListRemove\(None, GetMovementActorListKey\(\), target, True\)') "movement-held actors are tracked for interruption recovery"
Assert-Contract ($intro -notmatch 'Bool playerMovementLocked = LockPlayerMovement') "armor facade does not duplicate the shared movement lock"
Assert-Contract ($controller -match 'RestorePlayerMovementIfNeeded\(Game\.GetPlayer\(\), "controller initialization"\)' -and $controller -match 'RestorePlayerMovementIfNeeded\(Game\.GetPlayer\(\), "native load event"\)') "startup and load lifecycle recover an interrupted movement lock"
Assert-Contract ($controller -match 'Event OnNativeLifecycle[\s\S]*RestorePlayerMovementIfNeeded[\s\S]*If !IsExtensionsEnabled') "load recovery runs before the master-enable early return"
Assert-Contract ($animation -match 'StartSelected[\s\S]*LockPlayerMovement\(target, owner, requestLabel\)' -and $animation -match 'Function Reset[\s\S]*UnlockMovement\(target, owner, requestLabel\)') "ordinary shared reactions retain player-only locking with owner-checked release"
Assert-Contract ($animation -match 'GetPlayerMovementOwnerKey' -and $animation -match 'StorageUtil\.GetStringValue\(target, GetPlayerMovementOwnerKey\(\), ""\) != owner') "reaction movement cleanup is owner-tagged"
Assert-Contract ($controller -match 'MMEReactionAnimation\.RestorePlayerMovementIfNeeded\(Game\.GetPlayer\(\), "controller initialization"\)' -and $controller -match 'MMEReactionAnimation\.RestorePlayerMovementIfNeeded\(Game\.GetPlayer\(\), "native load event"\)') "reaction movement lock recovers on startup and load"
Assert-Contract ($api -match 'Return 1[6-9]' -and $api -match 'TryFirstArmorIntroduction' -and $api -match 'TryTrapArmorEquipStory' -and $api -match 'TryRepeatArmorEquipStory' -and $api -match 'HasSeenArmorIntroduction' -and $api -match 'ResetArmorIntroduction') "API version 16 or later exposes Milking Equipment through the shared presentation calls"
Assert-Contract ($stories.stringList.living_first_equip.Count -gt 0 -and $stories.stringList.parasite_first_equip.Count -gt 0 -and $stories.stringList.dwemer_first_equip.Count -gt 0) "all three JSON story pools contain a fallback-editable entry"
Assert-Contract ($stories.stringList.milking_first_equip.Count -eq 3 -and $stories.stringList.milking_repeat_equip.Count -eq 3) "Milking Equipment has three actor-aware first and repeat stories"
Assert-Contract ($stories.stringList.living_trap_equip.Count -eq 3 -and $stories.stringList.parasite_trap_equip.Count -eq 3 -and $stories.stringList.dwemer_trap_equip.Count -eq 3) "all three repeatable trap story pools contain three variants"
Assert-Contract ($stories.stringList.living_repeat_equip.Count -eq 3 -and $stories.stringList.parasite_repeat_equip.Count -eq 3 -and $stories.stringList.dwemer_repeat_equip.Count -eq 3) "all three ordinary repeat story pools contain three variants"
Assert-Contract ($controller -match 'IsTrapEquipPending' -and $controller -match 'enableRepeatTrapArmorStories' -and $controller -match 'TryTrapArmorEquipStory' -and $controller -match 'trapStoryAttempted') "repeat presentation is gated by the chest-origin marker and cannot fall through into a duplicate first story"
Assert-Contract ($controller -match 'alreadyTimedLocked' -and $controller -match 'enableRepeatOrdinaryArmorStories' -and $controller -match 'TryRepeatArmorEquipStory') "ordinary repeat presentation excludes chest and existing timed-lock equips"
Assert-Contract ($controller -match 'armorClass >= 1 && armorClass <= 4') "ordinary equip routing includes regular Milking Equipment"
Assert-Contract ($mcm -match 'Repeat Trap Armor Stories' -and $mcm -match 'repeatTrapArmorStoriesMigration150' -and $mcm -match 'Repeat Equipped Armor Stories' -and $mcm -match 'repeatOrdinaryArmorStoriesMigration151' -and $mcm -match 'Return 15[2-9]') "Misc chest and Armor ordinary-repeat toggles default on and migrate independently"
Assert-Contract ($alchemist -match 'TryIntroduction\(playerActor, wornArmor, "Alchemist Living Armor service"\)' -and $mage -match 'TryIntroduction\(playerActor, wornArmor, "Mage Parasite Armor service"\)' -and $dwemerBlacksmith -match 'TryIntroduction\(playerActor, wornArmor, "Blacksmith Dwemer attachment service"\)') "successful artisan services immediately request their guarded armor introduction"
Assert-Contract ($blacksmith -match 'TryRepeatArmorEquipStory\(playerActor, wornArmor\)' -and $blacksmith -match 'TryIntroduction\(playerActor, wornArmor, "Blacksmith Milking Armor service"\)' -and $blacksmith -match 'immediate Milking Armor introduction result=') "regular blacksmith fitting immediately requests its guarded Milking Armor story"
Assert-Contract ($alchemist -match 'enableRepeatOrdinaryArmorStories' -and $alchemist -match 'TryRepeatArmorEquipStory' -and $mage -match 'enableRepeatOrdinaryArmorStories' -and $mage -match 'TryRepeatArmorEquipStory' -and $dwemerBlacksmith -match 'enableRepeatOrdinaryArmorStories' -and $dwemerBlacksmith -match 'TryRepeatArmorEquipStory') "blacksmith, alchemist, and court-wizard installations share the Armor-page repeat toggle"
Assert-Contract ($build -match '"MMEArmorIntroduction"' -and $build -match 'ArmorIntroductionStories\.json' -and $build -match 'Test-ArmorIntroductionContracts\.ps1') "release build compiles, packages, and contract-tests the feature"
