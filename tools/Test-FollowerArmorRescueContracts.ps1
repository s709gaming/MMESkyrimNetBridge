$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$service = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEFollowerArmorRescue.psc") -Raw
$lock = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMETimedArmorLock.psc") -Raw
$wrapper = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEBlacksmithDialogue.psc") -Raw
$tif = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\TIF_MMEExtFollowerArmorRescue.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$dialogueBuilder = Get-Content -LiteralPath (Join-Path $projectRoot "build\mutagen-dialogue-repair\Program.cs") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "Follower armor rescue contract failed: $message" }
    Write-Host "PASS: $message"
}

Assert-Contract ($service -match '0x05091D' -and $service -match '0x051596') "service is merchant-blacksmith only"
Assert-Contract ($service -match 'candidate != playerActor' -and $service -match 'IsPlayerTeammate' -and $service -match 'GetRelationshipRank') "scan excludes the player and accepts nearby companions/allies"
Assert-Contract ($service -match 'MMEForcedMilkDrink\.IsEligibleActor' -and $service -match 'GetScanRadius') "scan requires a loaded adult humanoid in bounded range"
Assert-Contract ($service -match 'MMEAnimationSafety\.GetStartBlockReason\(candidate, milkController, False\)') "combat, milking, SexLab, OStim, and shared animation ownership block removal"
Assert-Contract ($service -match 'armorClass == 2 \|\| armorClass == 3 \|\| armorClass == 4' -and $service -match 'lockedClass == 2 \|\| lockedClass == 3 \|\| lockedClass == 4') "Living, Parasite, and Dwemer armor qualify"
Assert-Contract ($service -match 'CountEligibleCompanions\(blacksmith, True\)') "opening diagnostics retain the blacksmith-centered preview scan"
Assert-Contract ($service -match 'known ally outside opening scan' -and $service -match 'GetNearbyAllyFailure' -and $service -match 'distance=') "master traces distinguish nearby-scan rejection from unsupported armor"
Assert-Contract ($service -match 'MMEArmorRemoval\.RequestActorRemoval') "blacksmith removal delegates to the shared asynchronous transaction"
Assert-Contract ($lock -match 'Bool Function ReleaseQuiet' -and $lock -match 'ReleaseInternal\(target, source, False\)') "timed lock exposes a notification-free group release facade"
Assert-Contract ($service -match 'MMELog\.MasterDiagnostic' -and $service -match 'MMELog\.Alarm') "master footprints and contradiction smoke alarms are present"
Assert-Contract ($service.Contains('Nobody nearby still needs rescuing.') -and $service.Contains('companions from their overly affectionate armor.')) "service reports zero, one, and multi-companion outcomes"
Assert-Contract ($service -match 'TryDebugRescueNearbyCompanions' -and $service -match 'RescueNearbyCompanionsFromAnchor\(playerActor, "MCM NPC Debug", False\)') "MCM debug route reuses the guarded nearby-companion transaction without requiring a vendor"
Assert-Contract ($mcm -match 'AddTextOption\("Release Player Armor"[\s\S]*AddTextOption\("Release Nearby NPC Armor"' -and $mcm -match 'MMEFollowerArmorRescue\.TryDebugRescueNearbyCompanions\(\)') "NPC debug release appears directly below player release and delegates to the rescue service"
Assert-Contract ($dialogueBuilder -match 'BindFollowerArmorRescueConditions' -and $dialogueBuilder -match 'GetInFactionConditionData' -and $dialogueBuilder -match '05091D:Skyrim\.esm' -and $dialogueBuilder -match '051596:Skyrim\.esm') "dialogue visibility uses static merchant-blacksmith speaker conditions"
Assert-Contract ($dialogueBuilder -match 'must have exactly the merchant-blacksmith conditions' -and $dialogueBuilder -notmatch 'Follower armor rescue INFO global gate is malformed') "dialogue validation rejects the retired transient-Global gate"
Assert-Contract ($wrapper -match 'MMEExt_FollowerArmorRescueState' -and $wrapper -match 'Fragment_RescueFollowerArmor' -and $wrapper -match 'Fragment_RescueFollowerArmorCompleted' -and $wrapper -match 'begin fragment was missed') "Hey there wrapper publishes state and has an end-fragment fallback"
Assert-Contract ($tif -match 'extends TopicInfo' -and ([regex]::Matches($tif, 'TryRescueNearbyCompanions').Count -eq 1) -and $tif -notmatch 'begin was missed' -and $tif -match 'HandleVendorServiceResult' -and $tif -match 'ObserveVendorServiceInfoEnd') "dedicated TIF dispatches removal exactly once and delegates completion to the persistent vendor bus"
Assert-Contract ($tif -match 'Function ClearLegacyDialogueState' -and ([regex]::Matches($tif, 'ClearLegacyDialogueState\(\)').Count -ge 3)) "dedicated TIF clears stale legacy dialogue state before and after each transaction"
Assert-Contract ($build -match '"TIF_MMEExtFollowerArmorRescue"') "release build compiles and packages the dedicated TIF"
Assert-Contract ($build -match '"MMEFollowerArmorRescue"' -and $build -match 'Test-FollowerArmorRescueContracts') "release build compiles and tests the service"
