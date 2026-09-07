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
$sound = [regex]::Match($effects, '(?s)Function PlayNotificationSound\(.*?EndFunction').Value
Assert-Contract ($effects -match '(?s)If notificationText != ""\s+Debug.Notification\(notificationText\)\s+PlayNotificationSound\(focusActor\)\s+EndIf') 'sound plays only with a displayed notification on its wearer'
Assert-Contract ($sound.Contains('0x000854') -and $sound.Contains('enableArmorInjectionSounds') -and $sound.Contains('enableReactionSounds') -and $sound.Contains('reactionSoundVolume')) 'notification reuses low sound pool with feature/master/volume gates'
$sender = [regex]::Match($bridge, '(?s)Function NarrateTentacleEffect\(.*?EndFunction').Value
$builder = [regex]::Match($bridge, '(?s)String Function BuildTentacleEffectNarration\(.*?EndFunction').Value
Assert-Contract ($sender.Length -gt 0 -and $builder.Length -gt 0) 'bridge helper and result builder exist'
Assert-Contract ([regex]::Matches($sender, 'SkyrimNetApi\.DirectNarration\(').Count -eq 1) 'one request site per check'
Assert-Contract ($sender.Contains('SkyrimNetApi.DirectNarration(content, wearer, Game.GetPlayer())')) 'NPC route explicitly supplies the affected wearer as speaker'
Assert-Contract ($sender -match '(?s)If isPlayer\s+;.*?SkyrimNetApi.SendCustomPromptToLLM\(.*?Return\s+EndIf\s+content') 'player queues private generation and returns before NPC narration'
Assert-Contract ($sender -notmatch 'speaker = None|listener = wearer') 'no automatic bystander selection'
$callback = [regex]::Match($bridge, '(?s)Function PlayTentaclePlayerLine\(.*?EndFunction').Value
Assert-Contract ($callback.Contains('SkyrimNetApi.TriggerPlayerTTS(response)') -and $callback -notmatch 'SkyrimNetApi\.(DirectNarration|RegisterDialogue|TransformDialogue)\(') 'player callback uses TTS without reaction-producing dialogue events'
Assert-Contract ($callback.Contains('enableArmorInjectionPlayerNarration') -and $callback.Contains('If success != 1')) 'callback rechecks toggle and rejects failed generation'
Assert-Contract ($sender.Contains('wearer.IsChild()') -and $callback.Contains('Game.GetPlayer().IsChild()')) 'child speakers rejected before generation and playback'
Assert-Contract ($sender.Contains('If isPlayer && JsonUtil.GetIntValue(settingsFile, "enableArmorInjectionPlayerNarration", 1) != 1')) 'bridge respects player narration toggle'
Assert-Contract ($sender.Contains('arousalSent && arousalBefore >= 0 && arousalAfter > arousalBefore')) 'arousal needs sent event plus observed positive change'
Assert-Contract ($sender.Contains('BuildTentacleEffectNarration(actorName, milkAdded > 0.0, arousalIncreased, diagnostic)')) 'builder receives actual effect results'
Assert-Contract ($sender -notmatch 'Utility\.Wait|RegisterFor|ApplyMilk|ApplyConfigured|GetNearbyActors') 'narration adds no wait, timer, scan, or gameplay writes'
Assert-Contract ($sender.IndexOf('If !enabled') -lt $sender.IndexOf('Utility.RandomInt')) 'disabled narration does not roll'
Assert-Contract ($sender.Contains('Utility.RandomInt(1, 100)') -and $sender.Contains('If roll > chance')) 'chance supports both 0% and 100% endpoints'
Assert-Contract ([regex]::Matches($effects, 'MMEAlertsSkyrimNet\.NarrateTentacleEffect\(').Count -eq 1) 'gameplay hands off exactly once'
Assert-Contract ($effects.IndexOf('MMEAlertsSkyrimNet.NarrateTentacleEffect(') -gt $effects.IndexOf('Debug.Notification(notificationText)')) 'handoff follows HUD and completed actor loop'
Assert-Contract ($effects.Contains('Bool selectForNarration = focusActor == None || candidate == playerActor') -and !$effects.Contains('allowPlayerNarration')) 'narration follows HUD wearer without toggle-dependent NPC substitution'
Assert-Contract ($effects.Contains('narrationMilkAdded = milkAdded') -and $effects.Contains('narrationArousalBefore = arousalBefore') -and $effects.Contains('narrationArousalSent = arousalSent')) 'narration wearer retains its own results'
Assert-Contract ($effects.Contains('MMEMilkBoost.ApplyMilkDrinkBonusForActor(candidate, 1, False, False)') -and $effects.Contains('MMEArousalBridge.ApplyConfiguredMilkArousalForActor(candidate, "armor injection", False)')) 'existing effect calls remain unchanged'
Assert-Contract ($builder.Contains('If milkIncreased && arousalIncreased') -and $builder.Contains('".milkAndArousal"')) 'both-results branch selects its full template'
Assert-Contract ($builder.Contains('ElseIf milkIncreased') -and $builder.Contains('".milk"')) 'milk-only branch selects its full template'
Assert-Contract ($builder.Contains('ElseIf arousalIncreased') -and $builder.Contains('".arousal"')) 'arousal-only branch selects its full template'
Assert-Contract ($builder.Contains('narration skipped: neither milk nor arousal increase was confirmed')) 'neither-result branch skips narration'
Assert-Contract ($builder.Contains('Immediate situation involving ') -and $builder.Contains('do not change subjects')) 'prompt mirrors Armor Thoughts grounding'
Assert-Contract ($builder -notmatch 'JsonUtil\.GetStringValue') 'ordinary JSON uses path API, like Thoughts'
foreach ($key in @('milk', 'arousal', 'milkAndArousal')) {
    $values = @($config.$key)
    Assert-Contract ($values.Count -gt 0) "JSON $key has at least one template"
    foreach ($value in $values) {
        Assert-Contract ($value -is [string] -and $value.Trim().Length -gt 0) "JSON $key entry is a nonempty string"
        Assert-Contract ([regex]::Matches($value, '\{(?:actor|ACTOR)\}').Count -eq 1) "JSON $key entry has one supported actor token"
    }
}
$selector = [regex]::Match($bridge, '(?s)String Function SelectTentacleNarrationTemplate\(.*?EndFunction').Value
Assert-Contract ([regex]::Matches($builder, 'SelectTentacleNarrationTemplate\(').Count -eq 3) 'all three outcome branches use pool selection'
Assert-Contract ($selector.Contains('JsonUtil.PathStringElements(configFile, path)') -and $selector -match '(?s)If entries.Length > 0.*?entries\[Utility.RandomInt\(0, entries.Length - 1\)\]') 'random pool index is guarded and covers every entry'
Assert-Contract ($selector.Contains('JsonUtil.GetPathStringValue(configFile, path, fallback)')) 'legacy single-string templates remain supported'
Assert-Contract ($bridge.Contains('String Function RenderTentacleNarrationActorToken') -and $bridge.Contains('"{ACTOR}"')) 'renderer accepts existing uppercase actor token'
$mcmVersionMatch = [regex]::Match($mcm, '(?s)Int Function GetVersion\(\)\s+Return (\d+)')
Assert-Contract ($mcmVersionMatch.Success -and [int]$mcmVersionMatch.Groups[1].Value -ge 108 -and $mcm.Contains('armorInjectionPlayerNarrationMigration107') -and $mcm.Contains('armorInjectionSoundsMigration108')) 'MCM upgrades existing saves'
Assert-Contract ($mcm.Contains('AddHeaderOption("Skyrim.Net Narration")')) 'section stays on Tentacle Effects page'
Assert-Contract ($mcm -match '(?s)ElseIf option == armorInjectionNarrationChanceOption\s+SetSliderDialogStartValue\(JsonUtil.GetIntValue\(SettingsFile, "armorInjectionNarrationChance", 100\)\)\s+SetSliderDialogDefaultValue\(100.0\)\s+SetSliderDialogRange\(0.0, 100.0\)\s+SetSliderDialogInterval\(5.0\)') 'chance defaults to 100%, ranges 0-100%, steps 5%'
