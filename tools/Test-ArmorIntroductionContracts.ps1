$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$intro = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorIntroduction.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$animation = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEReactionAnimation.psc") -Raw
$sounds = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEReactionSounds.psc") -Raw
$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$stories = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\ArmorIntroductionStories.json") -Raw | ConvertFrom-Json
$alchemist = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlchemistDialogue.psc") -Raw
$mage = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEMageDialogue.psc") -Raw
$dwemerBlacksmith = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDwemerBlacksmithDialogue.psc") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($intro -match 'target != Game\.GetPlayer\(\)' -and $controller -match 'MMEArmorIntroduction\.TryAutomatic') "automatic pausing introductions are player-only"
Assert-Contract ($intro -match 'armorClass == 2 \|\| armorClass == 3 \|\| armorClass == 4') "only Living, Parasite, and Dwemer categories qualify"
Assert-Contract ($intro -match 'MMEExtensions\.ArmorIntroduction\.Living' -and $intro -match 'MMEExtensions\.ArmorIntroduction\.Parasite' -and $intro -match 'MMEExtensions\.ArmorIntroduction\.Dwemer') "completion is tracked per actor and category"
Assert-Contract ($intro -match 'StartPresentationKneeling' -and $intro -match 'PlayPresentationHighMoan' -and $intro -match 'ShowRandomStoryPopup') "sequence reuses safe animation, high sound, and shared story facade"
Assert-Contract ($animation -match 'Bool Function StartPresentationKneeling' -and $animation -match 'GetStartBlockReason' -and $animation -match 'TryAcquire') "presentation animation retains shared safety and ownership"
Assert-Contract ($sounds -match 'Int Function PlayPresentationHighMoan' -and $sounds -match 'PlayPresentationHighMoan[\s\S]*Return instance[\s\S]*EndFunction') "presentation sound uses a standalone helper without conversion gating"
Assert-Contract ($intro -notmatch 'AssignSlotMaid|MakeTargetNewMilkMaid|TryCreateMilkMaidForcedAnimated') "presentation facade does not convert the actor"
Assert-Contract ($intro -match 'target\.SetDontMove\(True\)' -and $intro -match 'target\.SetDontMove\(False\)' -and $intro -match 'MMEExtensions\.ArmorIntroduction\.PlayerMovementLocked') "player movement lock has symmetric marker-owned cleanup"
Assert-Contract ($controller -match 'RestorePlayerMovementIfNeeded\(Game\.GetPlayer\(\), "controller initialization"\)' -and $controller -match 'RestorePlayerMovementIfNeeded\(Game\.GetPlayer\(\), "native load event"\)') "startup and load lifecycle recover an interrupted movement lock"
Assert-Contract ($controller -match 'Event OnNativeLifecycle[\s\S]*RestorePlayerMovementIfNeeded[\s\S]*If !IsExtensionsEnabled') "load recovery runs before the master-enable early return"
Assert-Contract ($api -match 'Return 11' -and $api -match 'TryFirstArmorIntroduction' -and $api -match 'HasSeenArmorIntroduction' -and $api -match 'ResetArmorIntroduction') "API version 11 retains trigger, query, and reset calls"
Assert-Contract ($stories.stringList.living_first_equip.Count -gt 0 -and $stories.stringList.parasite_first_equip.Count -gt 0 -and $stories.stringList.dwemer_first_equip.Count -gt 0) "all three JSON story pools contain a fallback-editable entry"
Assert-Contract ($alchemist -match 'TryIntroduction\(playerActor, wornArmor, "Alchemist Living Armor service"\)' -and $mage -match 'TryIntroduction\(playerActor, wornArmor, "Mage Parasite Armor service"\)' -and $dwemerBlacksmith -match 'TryIntroduction\(playerActor, wornArmor, "Blacksmith Dwemer attachment service"\)') "successful artisan services immediately request their guarded armor introduction"
Assert-Contract ($build -match '"MMEArmorIntroduction"' -and $build -match 'ArmorIntroductionStories\.json' -and $build -match 'Test-ArmorIntroductionContracts\.ps1') "release build compiles, packages, and contract-tests the feature"
