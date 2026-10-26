$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$effect = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArousalEffects.psc") -Raw
$animations = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArousalAnimations.psc") -Raw
$reactionAnimation = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEReactionAnimation.psc") -Raw
$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
$bridge = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArousalBridge.psc") -Raw
$npcDrink = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMENPCDrinkDialogue.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$fomod = Get-Content -LiteralPath (Join-Path $projectRoot "fomod\ModuleConfig.xml") -Raw
$json = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\ArousalEffects.json") -Raw | ConvertFrom-Json
$behaviorList = Get-Content -LiteralPath (Join-Path $projectRoot "assets\animations\FNIS_MMEExtensionsArousal_List.txt") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($effect -notmatch 'RegisterForUpdate|RegisterForSingleUpdate|Event OnUpdate') "arousal facade creates no independent polling loop"
Assert-Contract ($controller -match 'NextArousalEffectUpdate' -and $controller -match 'arousalEffectDue' -and $controller -match 'MMEArousalEffects\.ProcessNearbyActors\(nearbyActors\)') "controller owns five-second scheduling and supplies its native scan"
Assert-Contract ($effect -match 'Return 5\.0' -and $effect -match 'arousalEffectCooldown", 5\.0' -and $mcm -match 'arousalEffectDelay", 5\.0' -and $mcm -match 'arousalEffectCooldownVariation", 0\.0') "scan, delay, cooldown, and randomization defaults match the approved timing"
Assert-Contract ($effect -match 'Utility\.RandomInt\(1, crossingCount\) == 1') "simultaneous crossings use uniform random target selection"
Assert-Contract ($effect -match 'currentTier > previousTier' -and $effect -match 'quiet baselines established') "reactions are upward-crossing based with quiet first observation"
Assert-Contract ($effect -match 'enableArousalMilkMaidRoute", 1' -and $effect -match 'enableArousalMilkDrinkRoute", 1' -and $effect -match 'enableArousalEveryoneRoute", 0') "eligibility uses default-on Milk Maid OR milk-drink routes with everyone else off"
Assert-Contract ($effect -match 'RecordMilkDrinkCrossing' -and $effect -match 'QueueReaction\(target, afterTier, "milk drink"\)' -and $bridge -match 'RecordMilkDrinkResult' -and $npcDrink -match 'RecordMilkDrinkResult') "Milk Maid and ordinary-adult drink arousal report exact post-drink threshold crossings"
Assert-Contract ($effect -match 'PendingReady' -and $effect -match 'PendingExpires' -and $effect -match 'RollCooldown' -and $effect -match 'Utility\.RandomFloat') "qualified reactions use delayed pending state and one rolled cooldown duration"
Assert-Contract ($bridge -match 'slaFrameworkScr' -and $bridge -match 'GetActorArousal' -and $bridge -match 'UpdateActorExposure') "arousal bridge uses the portable SLA compatibility API"
Assert-Contract ($bridge -match 'ModEvent\.Create\("slaUpdateExposure"\)' -and $bridge -match 'framework != None') "direct arousal writes avoid duplicate OSL events while retaining a legacy fallback"
Assert-Contract ($effect -match 'MMELog\.MasterDiagnostic' -and $effect -match 'AlarmOnce') "normal footprints are master-gated and failures are rate limited"
Assert-Contract ($effect -match 'DispatchFutureExtensions' -and $effect -match 'MMEArousalAnimations\.TryPlay') "stable extension point dispatches the arousal animation facade"
Assert-Contract ($animations -match 'Return 3\.0' -and $animations -match 'MMEExt_Arousal_F_L1' -and $animations -match 'MMEExt_Arousal_F_L2' -and $animations -match 'MMEExt_Arousal_F_L3' -and $animations -match 'MMEExt_Arousal_M_L1' -and $animations -match 'tier == 2 \|\| tier == 3') "three tiers map to supplied sex-aware clips with male tier 3 reusing tier 2"
Assert-Contract ($animations -match 'StartCustomEvent' -and $reactionAnimation -match 'Bool Function StartCustomEvent' -and $reactionAnimation -match 'GetStartBlockReason' -and $reactionAnimation -match 'LockMovement') "custom arousal clips reuse combat-safe ownership and movement locking"
Assert-Contract ([int]([regex]::Match($mcm, '(?s)Int Function GetVersion\(\)\s+Return (\d+)').Groups[1].Value) -ge 152 -and $mcm -match 'arousalAnimationsMigration152' -and $mcm -match 'Play Arousal Animations') "MCM version 152 or later retains the default-on animation toggle"
Assert-Contract ([int]([regex]::Match($mcm, '(?s)Int Function GetVersion\(\)\s+Return (\d+)').Groups[1].Value) -ge 154 -and $mcm -match 'arousalEligibilityMigration154' -and $mcm -match 'Always React for Milk Maids' -and $mcm -match 'React After Milk Drinking' -and $mcm -match 'Include Everyone Else') "MCM version 154 or later retains the three OR-based eligibility routes"
Assert-Contract ($api -match 'Return 1[5-9]' -and $api -match 'TryPlayArousalAnimation') "API version 15 or later exposes guarded arousal animation playback"
foreach ($eventName in @('MMEExt_Arousal_F_L1', 'MMEExt_Arousal_F_L2', 'MMEExt_Arousal_F_L3', 'MMEExt_Arousal_M_L1', 'MMEExt_Arousal_M_L2')) {
    Assert-Contract ($behaviorList -match [regex]::Escape($eventName)) "behavior list declares $eventName"
}
foreach ($relativeClip in @('female aroused\femaleArousedLevel1.hkx', 'female aroused\femaleArousedLevel2.hkx', 'female aroused\femaleArousedLevel3.hkx', 'male aroused\maleArousedLevel1.hkx', 'male aroused\maleArousedLevel2.hkx')) {
    $clip = Get-Item -LiteralPath (Join-Path $projectRoot "assets\animations\$relativeClip")
    Assert-Contract ($clip.Length -gt 0) "animation clip is present and nonempty: $relativeClip"
}
Assert-Contract ($mcm -match 'SetSliderDialogDefaultValue\(10\.0\)' -and $mcm -match '"milkDrinkArousal", 10\.0') "milk-drink arousal defaults to ten without changing the observational monitor"

$poolNames = @('low_female', 'low_male', 'medium_female', 'medium_male', 'high_female', 'high_male')
foreach ($poolName in $poolNames) {
    $entries = @($json.$poolName)
    Assert-Contract ($entries.Count -eq 5) "JSON pool $poolName contains five reactions"
    Assert-Contract (($entries | Where-Object { $_ -notmatch '\{actor\}' }).Count -eq 0) "JSON pool $poolName uses the actor token"
}

Assert-Contract ($build -match '"MMEArousalAnimations"' -and $build -match 'FNIS_MMEExtensionsArousal_List\.txt' -and $build -match 'femaleArousedLevel3\.hkx' -and $build -match 'Test-ArousalEffectsContracts\.ps1') "release build compiles and packages the behavior-driven arousal animations"
Assert-Contract ($fomod -match '<folder source="meshes" destination="meshes"' -and $fomod -match '<folder source="Docs" destination="Docs"') "FOMOD deploys the animation assets and behavior-generation guide"
