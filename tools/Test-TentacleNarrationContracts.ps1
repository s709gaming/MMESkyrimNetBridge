$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$bridge = Get-Content (Join-Path $projectRoot 'Source\Scripts\MMEAlertsSkyrimNet.psc') -Raw
$effects = Get-Content (Join-Path $projectRoot 'Source\Scripts\MMETentacleEffects.psc') -Raw
$mcm = Get-Content (Join-Path $projectRoot 'Source\Scripts\MMEAlertsMCM.psc') -Raw
$config = Get-Content (Join-Path $projectRoot 'SKSE\Plugins\StorageUtilData\MMEAlerts\TentacleEffectNarration.json') -Raw | ConvertFrom-Json

function Assert-Contract([bool]$Condition, [string]$Message) {
    if (!$Condition) { throw "Tentacle narration contract: $Message" }
    Write-Host "PASS: $Message"
}

# Source/JSON contract checks, not a substitute for a Skyrim runtime test.
$sender = [regex]::Match($bridge, '(?s)Function NarrateTentacleEffect\(.*?EndFunction').Value
$builder = [regex]::Match($bridge, '(?s)String Function BuildTentacleEffectNarration\(.*?EndFunction').Value
Assert-Contract ($sender.Length -gt 0 -and $builder.Length -gt 0) 'bridge helper and result builder exist'
Assert-Contract ([regex]::Matches($sender, 'SkyrimNetApi\.DirectNarration\(').Count -eq 1) 'one request site per check'
Assert-Contract ($sender.Contains('SkyrimNetApi.DirectNarration(content, wearer, Game.GetPlayer())')) 'NPC wearer is speaker and player is listener'
Assert-Contract ($sender.Contains('If wearer == Game.GetPlayer()')) 'player-originator special case cannot select a random bystander'
Assert-Contract ($sender.Contains('arousalSent && arousalBefore >= 0 && arousalAfter > arousalBefore')) 'arousal needs sent event plus observed positive change'
Assert-Contract ($sender.Contains('BuildTentacleEffectNarration(actorName, milkAdded > 0.0, arousalIncreased, diagnostic)')) 'builder receives actual effect results'
Assert-Contract ($sender -notmatch 'Utility\.Wait|RegisterFor|ApplyMilk|ApplyConfigured|GetNearbyActors') 'narration adds no wait, timer, scan, or gameplay writes'
Assert-Contract ($sender.IndexOf('If !enabled') -lt $sender.IndexOf('Utility.RandomInt')) 'disabled narration does not roll'
Assert-Contract ($sender.Contains('Utility.RandomInt(1, 100)') -and $sender.Contains('If roll > chance')) 'chance supports both 0% and 100% endpoints'
Assert-Contract ([regex]::Matches($effects, 'MMEAlertsSkyrimNet\.NarrateTentacleEffect\(').Count -eq 1) 'gameplay hands off exactly once'
Assert-Contract ($effects.IndexOf('MMEAlertsSkyrimNet.NarrateTentacleEffect(') -gt $effects.IndexOf('Debug.Notification(notificationText)')) 'handoff follows HUD and completed actor loop'
Assert-Contract ($effects.Contains('If narrationActor == None && candidate != playerActor')) 'narration selects one affected NPC wearer'
Assert-Contract ($effects.Contains('narrationMilkAdded = milkAdded') -and $effects.Contains('narrationArousalBefore = arousalBefore') -and $effects.Contains('narrationArousalSent = arousalSent')) 'narration wearer retains its own results'
Assert-Contract ($effects.Contains('MMEMilkBoost.ApplyMilkDrinkBonusForActor(candidate, 1, False, False)') -and $effects.Contains('MMEArousalBridge.ApplyConfiguredMilkArousalForActor(candidate, "armor injection", False)')) 'existing effect calls remain unchanged'
Assert-Contract ($builder.Contains('If milkIncreased && arousalIncreased') -and $builder.Contains('".milkAndArousal"')) 'both-results branch selects its full template'
Assert-Contract ($builder.Contains('ElseIf milkIncreased') -and $builder.Contains('".milk"')) 'milk-only branch selects its full template'
Assert-Contract ($builder.Contains('ElseIf arousalIncreased') -and $builder.Contains('".arousal"')) 'arousal-only branch selects its full template'
Assert-Contract ($builder.Contains('narration skipped: neither milk nor arousal increase was confirmed')) 'neither-result branch skips narration'
Assert-Contract ($builder.Contains('Immediate situation affecting YOU, ') -and $builder.Contains('do not change subjects')) 'prompt mirrors Armor Thoughts grounding'
Assert-Contract ($builder -notmatch 'JsonUtil\.GetStringValue') 'ordinary JSON uses path API, like Thoughts'
foreach ($key in @('milk', 'arousal', 'milkAndArousal')) {
    $value = $config.$key
    Assert-Contract ($value -is [string] -and $value.Trim().Length -gt 0) "JSON $key is a nonempty string"
    Assert-Contract ([regex]::Matches($value, '\{(?:actor|ACTOR)\}').Count -eq 1) "JSON $key has one supported actor token"
}
Assert-Contract ($bridge.Contains('String Function RenderTentacleNarrationActorToken') -and $bridge.Contains('"{ACTOR}"')) 'renderer accepts existing uppercase actor token'
Assert-Contract ($mcm.Contains('Return 106') -and $mcm.Contains('armorInjectionNarrationMigration106')) 'MCM upgrades existing saves'
Assert-Contract ($mcm.Contains('AddHeaderOption("Skyrim.Net Narration")')) 'section stays on Tentacle Effects page'
Assert-Contract ($mcm -match '(?s)ElseIf option == armorInjectionNarrationChanceOption\s+SetSliderDialogStartValue\(JsonUtil.GetIntValue\(SettingsFile, "armorInjectionNarrationChance", 100\)\)\s+SetSliderDialogDefaultValue\(100.0\)\s+SetSliderDialogRange\(0.0, 100.0\)\s+SetSliderDialogInterval\(5.0\)') 'chance defaults to 100%, ranges 0-100%, steps 5%'
