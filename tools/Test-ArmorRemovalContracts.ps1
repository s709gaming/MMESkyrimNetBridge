$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$service = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorRemoval.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$followers = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEFollowerArmorRescue.psc") -Raw
$timed = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMETimedArmorLock.psc") -Raw
$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "Armor removal contract failed: $message" }
    Write-Host "PASS: $message"
}

Assert-Contract ($api -match 'Return 1[56]' -and $api -match 'ReleasePlayerSpecialArmor' -and $api -match 'ReleaseNearbyNPCSpecialArmor') "API version 15 or later retains player and nearby-allied-NPC removal facades"
Assert-Contract ($service -match 'armorClass == 2 \|\| armorClass == 3 \|\| armorClass == 4') "shared service accepts only Living, Parasite, and Dwemer armor"
Assert-Contract ($service -match 'candidate != playerActor' -and $service -match 'IsPlayerTeammate' -and $service -match 'GetRelationshipRank') "AOE excludes the player and targets allied NPCs"
Assert-Contract ($service -match 'MMEAnimationSafety\.GetStartBlockReason') "NPC AOE preserves shared scene, combat, and animation safety"
Assert-Contract ($service -match 'QueueVerification' -and $service -match 'GetVerificationDelay' -and $service -match 'ResolveDueVerifications') "unequip completion uses delayed verification instead of an immediate false failure"
Assert-Contract ($controller -match 'MMEArmorRemoval\.GetNextVerificationDeadline' -and $controller -match 'MMEArmorRemoval\.ResolveDueVerifications' -and $controller -match 'MMEArmorRemoval\.HandleArmorUnequipped') "verification shares the controller scheduler and native unequip event"
Assert-Contract ($followers -match 'RescueNearbyCompanionsFromAnchor\(Game\.GetPlayer\(\), "Follower Blacksmith Assistance", True\)' -and $followers -match 'MMEArmorRemoval\.RequestActorRemoval') "blacksmith validates its vendor but scans from the player and reuses the shared transaction"
Assert-Contract ($timed -notmatch 'release failed: armor remains equipped' -and $timed -match 'UnequipItem is asynchronous') "timed release no longer treats immediate IsEquipped as authoritative"
Assert-Contract ($service -match 'MMELog\.MasterDiagnostic' -and $service -match 'MMELog\.Alarm') "master footprints and delayed-failure smoke alarms are present"
Assert-Contract ($build -match '"MMEArmorRemoval"' -and $build -match 'Test-ArmorRemovalContracts') "release build compiles and contract-tests the shared service"

Write-Host "Armor removal contracts passed."
