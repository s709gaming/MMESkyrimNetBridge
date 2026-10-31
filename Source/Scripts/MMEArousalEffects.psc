Scriptname MMEArousalEffects Hidden

; Nearby arousal threshold reactions. The long-lived controller owns polling
; and supplies one native actor snapshot; this facade owns all feature state,
; selection, notification, sound, diagnostics, and future presentation hooks.

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

Float Function GetScanInterval() Global
    Return 5.0
EndFunction

Bool Function IsEnabled() Global
    String settingsFile = GetSettingsFile()
    Return MMEAlertsController.IsExtensionsEnabled() \
        && JsonUtil.GetIntValue(settingsFile, "enableArousalEffects", 1) == 1 \
        && MMEArousalBridge.IsAvailable()
EndFunction

; A generation token resets every nearby actor to a quiet first-observation
; baseline without trying to enumerate actors that may no longer be loaded.
Function ResetBaselines(String reason = "settings changed") Global
    String generationKey = "MMEExtensions.ArousalEffects.Generation"
    Int generation = StorageUtil.GetIntValue(None, generationKey, 1) + 1
    If generation <= 0 || generation > 2000000000
        generation = 1
    EndIf
    StorageUtil.SetIntValue(None, generationKey, generation)
    StorageUtil.UnsetFloatValue(None, "MMEExtensions.ArousalEffects.LastReaction")
    StorageUtil.UnsetFloatValue(None, "MMEExtensions.ArousalEffects.LastCooldown")
    MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] baselines reset | generation=" + generation + " | reason=" + reason)
EndFunction

; Records only a threshold crossing caused by a recognized milk-drink arousal
; change. Presentation remains owned by the existing five-second nearby scan so
; drink animations get time to finish and this facade creates no second loop.
Function RecordMilkDrinkCrossing(Actor target, Int arousalBefore, Int arousalAfter) Global
    If target == None || !IsEnabled()
        Return
    EndIf
    If arousalBefore < 0 || arousalAfter < 0
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.MilkArousalUnreadable", "[MME Extensions Arousal Effects] FAILURE: a recognized milk arousal update returned an unreadable before/after value")
        Return
    EndIf
    ClearAlarm("MMEExtensions.ArousalEffects.Alarm.MilkArousalUnreadable")
    Int[] thresholds = GetNormalizedThresholds()
    Int beforeTier = DetermineTier(arousalBefore, thresholds)
    Int afterTier = DetermineTier(arousalAfter, thresholds)
    If afterTier <= beforeTier
        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] milk drink did not cross upward | actor=" + GetActorName(target) + " | arousal=" + arousalBefore + " -> " + arousalAfter + " | tier=" + beforeTier + " -> " + afterTier)
        Return
    EndIf
    QueueReaction(target, afterTier, "milk drink")
    MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] milk crossing queued | actor=" + GetActorName(target) + " | arousal=" + arousalBefore + " -> " + arousalAfter + " | tier=" + beforeTier + " -> " + afterTier)
EndFunction

Function QueueReaction(Actor target, Int tier, String route) Global
    If target == None || tier < 1 || tier > 3
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.PendingTier", "[MME Extensions Arousal Effects] FAILURE: attempted to queue an invalid pending reaction tier")
        Return
    EndIf
    ClearAlarm("MMEExtensions.ArousalEffects.Alarm.PendingTier")
    Int existingTier = StorageUtil.GetIntValue(target, "MMEExtensions.ArousalEffects.PendingTier", 0)
    If tier > existingTier
        StorageUtil.SetIntValue(target, "MMEExtensions.ArousalEffects.PendingTier", tier)
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float delay = JsonUtil.GetFloatValue(GetSettingsFile(), "arousalEffectDelay", 5.0)
    If delay < 0.0
        delay = 0.0
    ElseIf delay > 60.0
        delay = 60.0
    EndIf
    Float existingReady = StorageUtil.GetFloatValue(target, "MMEExtensions.ArousalEffects.PendingReady", -1.0)
    Float readyAt = now + delay
    If existingReady < now || readyAt < existingReady
        StorageUtil.SetFloatValue(target, "MMEExtensions.ArousalEffects.PendingReady", readyAt)
    EndIf
    StorageUtil.SetFloatValue(target, "MMEExtensions.ArousalEffects.PendingExpires", readyAt + 30.0)
    StorageUtil.SetStringValue(target, "MMEExtensions.ArousalEffects.PendingRoute", route)
EndFunction

Function ClearPendingReaction(Actor target) Global
    StorageUtil.UnsetIntValue(target, "MMEExtensions.ArousalEffects.PendingTier")
    StorageUtil.UnsetFloatValue(target, "MMEExtensions.ArousalEffects.PendingReady")
    StorageUtil.UnsetFloatValue(target, "MMEExtensions.ArousalEffects.PendingExpires")
    StorageUtil.UnsetStringValue(target, "MMEExtensions.ArousalEffects.PendingRoute")
EndFunction

; Updates every valid actor's state, then presents at most one uniformly random
; upward crossing. Unselected simultaneous crossings are consumed rather than
; queued, preventing crowded interiors from producing a delayed reaction train.
Bool Function ProcessNearbyActors(Actor[] scannedActors) Global
    If !IsEnabled()
        Return False
    EndIf
    If scannedActors.Length == 0
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.EmptyScan", "[MME Extensions Arousal Effects] FAILURE: native nearby scan returned no actors")
        Return False
    EndIf
    ClearAlarm("MMEExtensions.ArousalEffects.Alarm.EmptyScan")

    Int[] thresholds = GetNormalizedThresholds()
    Int generation = StorageUtil.GetIntValue(None, "MMEExtensions.ArousalEffects.Generation", 1)
    Int crossingCount = 0
    Int baselineCount = 0
    Int readableCount = 0
    Int queuedCount = 0
    Actor selectedActor = None
    Int selectedTier = 0
    Int selectedArousal = -1
    Int index = 0
    While index < scannedActors.Length
        Actor candidate = scannedActors[index]
        If IsValidCandidate(candidate)
            Int arousal = MMEArousalBridge.GetCurrentArousal(candidate)
            If arousal >= 0 && StorageUtil.GetIntValue(candidate, "MMEExtensions.Tentacle.SuppressCrossing", 0) == 1
                StorageUtil.SetIntValue(candidate, "MMEExtensions.ArousalEffects.Tier", DetermineTier(arousal, thresholds))
                ClearPendingReaction(candidate)
                If StorageUtil.GetStringValue(candidate, "MMEExtensions.Tentacle.Owner", "") == ""
                    StorageUtil.UnsetIntValue(candidate, "MMEExtensions.Tentacle.SuppressCrossing")
                EndIf
            EndIf
            If arousal >= 0
                readableCount += 1
                Int currentTier = DetermineTier(arousal, thresholds)
                Int actorGeneration = StorageUtil.GetIntValue(candidate, "MMEExtensions.ArousalEffects.Generation", 0)
                Int previousTier = StorageUtil.GetIntValue(candidate, "MMEExtensions.ArousalEffects.Tier", -1)
                StorageUtil.SetIntValue(candidate, "MMEExtensions.ArousalEffects.Generation", generation)
                StorageUtil.SetIntValue(candidate, "MMEExtensions.ArousalEffects.Tier", currentTier)
                If actorGeneration != generation || previousTier < 0
                    baselineCount += 1
                ElseIf currentTier > previousTier
                    Bool milkMaidRoute = JsonUtil.GetIntValue(GetSettingsFile(), "enableArousalMilkMaidRoute", 1) == 1 && MMEAlertsController.IsKnownMilkmaid(candidate)
                    Bool everyoneRoute = JsonUtil.GetIntValue(GetSettingsFile(), "enableArousalEveryoneRoute", 0) == 1
                    If milkMaidRoute
                        QueueReaction(candidate, currentTier, "Milk Maid")
                        queuedCount += 1
                    ElseIf everyoneRoute
                        QueueReaction(candidate, currentTier, "everyone else")
                        queuedCount += 1
                    Else
                        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] crossing filtered | actor=" + GetActorName(candidate) + " | neither Milk Maid nor everyone-else route qualified")
                    EndIf
                EndIf

                Int pendingTier = StorageUtil.GetIntValue(candidate, "MMEExtensions.ArousalEffects.PendingTier", 0)
                If pendingTier > 0
                    Float now = Utility.GetCurrentRealTime()
                    Float readyAt = StorageUtil.GetFloatValue(candidate, "MMEExtensions.ArousalEffects.PendingReady", now)
                    Float expiresAt = StorageUtil.GetFloatValue(candidate, "MMEExtensions.ArousalEffects.PendingExpires", readyAt + 30.0)
                    String pendingRoute = StorageUtil.GetStringValue(candidate, "MMEExtensions.ArousalEffects.PendingRoute", "")
                    Bool routeEnabled = pendingRoute == "milk drink" && JsonUtil.GetIntValue(GetSettingsFile(), "enableArousalMilkDrinkRoute", 1) == 1
                    If pendingRoute == "Milk Maid"
                        routeEnabled = JsonUtil.GetIntValue(GetSettingsFile(), "enableArousalMilkMaidRoute", 1) == 1 && MMEAlertsController.IsKnownMilkmaid(candidate)
                    ElseIf pendingRoute == "everyone else"
                        routeEnabled = JsonUtil.GetIntValue(GetSettingsFile(), "enableArousalEveryoneRoute", 0) == 1
                    EndIf
                    If now > expiresAt || !routeEnabled
                        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] pending reaction discarded | actor=" + GetActorName(candidate) + " | route=" + pendingRoute + " | expired=" + (now > expiresAt))
                        ClearPendingReaction(candidate)
                    ElseIf now >= readyAt
                        crossingCount += 1
                        ; Reservoir selection keeps every ready actor equally
                        ; likely; all simultaneous ready entries are consumed.
                        If Utility.RandomInt(1, crossingCount) == 1
                            selectedActor = candidate
                            selectedTier = pendingTier
                            selectedArousal = arousal
                        EndIf
                        ClearPendingReaction(candidate)
                    EndIf
                EndIf
            EndIf
        EndIf
        index += 1
    EndWhile

    If readableCount <= 0
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.NoReadableActors", "[MME Extensions Arousal Effects] FAILURE: no valid nearby actor returned a readable arousal value")
        Return False
    EndIf
    ClearAlarm("MMEExtensions.ArousalEffects.Alarm.NoReadableActors")
    If baselineCount > 0
        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] quiet baselines established | actors=" + baselineCount + " | generation=" + generation)
    EndIf
    If queuedCount > 0
        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] delayed reactions queued | count=" + queuedCount)
    EndIf
    If crossingCount <= 0 || selectedActor == None
        Return False
    EndIf

    Float now = Utility.GetCurrentRealTime()
    Float cooldown = StorageUtil.GetFloatValue(None, "MMEExtensions.ArousalEffects.LastCooldown", JsonUtil.GetFloatValue(GetSettingsFile(), "arousalEffectCooldown", 5.0))
    If cooldown < 0.0
        cooldown = 0.0
    ElseIf cooldown > 600.0
        cooldown = 600.0
    EndIf
    Float lastReaction = StorageUtil.GetFloatValue(None, "MMEExtensions.ArousalEffects.LastReaction", -1000.0)
    ; GetCurrentRealTime restarts with Skyrim, so discard older-session values.
    If lastReaction > now
        lastReaction = -1000.0
        StorageUtil.UnsetFloatValue(None, "MMEExtensions.ArousalEffects.LastReaction")
    EndIf
    If now - lastReaction < cooldown
        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] crossings suppressed by cooldown | crossings=" + crossingCount + " | remaining=" + (cooldown - (now - lastReaction)) + " seconds")
        Return False
    EndIf

    Bool presented = DispatchReaction(selectedActor, selectedTier, selectedArousal)
    If presented
        ; Dispatch can make one bounded five-second retry. Start cooldown when
        ; presentation actually occurs rather than at the original crossing.
        StorageUtil.SetFloatValue(None, "MMEExtensions.ArousalEffects.LastReaction", Utility.GetCurrentRealTime())
        Float nextCooldown = RollCooldown()
        StorageUtil.SetFloatValue(None, "MMEExtensions.ArousalEffects.LastCooldown", nextCooldown)
        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] reaction presented | actor=" + GetActorName(selectedActor) + " | tier=" + selectedTier + " | arousal=" + selectedArousal + " | candidates=" + crossingCount + " | next cooldown=" + nextCooldown)
    EndIf
    Return presented
EndFunction

Float Function RollCooldown() Global
    Float baseCooldown = JsonUtil.GetFloatValue(GetSettingsFile(), "arousalEffectCooldown", 5.0)
    Float variation = JsonUtil.GetFloatValue(GetSettingsFile(), "arousalEffectCooldownVariation", 0.0)
    If baseCooldown < 0.0
        baseCooldown = 0.0
    ElseIf baseCooldown > 600.0
        baseCooldown = 600.0
    EndIf
    If variation < 0.0
        variation = 0.0
    ElseIf variation > 600.0
        variation = 600.0
    EndIf
    Float result = baseCooldown
    If variation > 0.0
        result += Utility.RandomFloat(0.0 - variation, variation)
    EndIf
    If result < 0.0
        result = 0.0
    EndIf
    Return result
EndFunction

Bool Function IsValidCandidate(Actor candidate) Global
    Return MMEForcedMilkDrink.IsEligibleActor(candidate) && !candidate.IsInCombat()
EndFunction

Int Function DetermineTier(Int arousal, Int[] thresholds) Global
    If thresholds.Length < 3
        Return 0
    EndIf
    If arousal >= thresholds[2]
        Return 3
    ElseIf arousal >= thresholds[1]
        Return 2
    ElseIf arousal >= thresholds[0]
        Return 1
    EndIf
    Return 0
EndFunction

Int[] Function GetNormalizedThresholds() Global
    String settingsFile = GetSettingsFile()
    Int[] thresholds = new Int[3]
    Int rawLow = JsonUtil.GetIntValue(settingsFile, "arousalLowThreshold", 20)
    Int rawMedium = JsonUtil.GetIntValue(settingsFile, "arousalMediumThreshold", 50)
    Int rawHigh = JsonUtil.GetIntValue(settingsFile, "arousalHighThreshold", 80)
    thresholds[0] = rawLow
    If thresholds[0] < 0
        thresholds[0] = 0
    ElseIf thresholds[0] > 90
        thresholds[0] = 90
    EndIf
    thresholds[1] = rawMedium
    If thresholds[1] < thresholds[0] + 5
        thresholds[1] = thresholds[0] + 5
    ElseIf thresholds[1] > 95
        thresholds[1] = 95
    EndIf
    thresholds[2] = rawHigh
    If thresholds[2] < thresholds[1] + 5
        thresholds[2] = thresholds[1] + 5
    ElseIf thresholds[2] > 100
        thresholds[2] = 100
    EndIf
    If thresholds[0] != rawLow || thresholds[1] != rawMedium || thresholds[2] != rawHigh
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.Thresholds", "[MME Extensions Arousal Effects] FAILURE: invalid thresholds normalized at runtime | low=" + thresholds[0] + " | medium=" + thresholds[1] + " | high=" + thresholds[2])
    Else
        ClearAlarm("MMEExtensions.ArousalEffects.Alarm.Thresholds")
    EndIf
    Return thresholds
EndFunction

Bool Function DispatchReaction(Actor target, Int tier, Int arousal) Global
    If StorageUtil.GetIntValue(target, "MMEExtensions.Tentacle.SuppressCrossing", 0) == 1
        ClearPendingReaction(target)
        Return False
    EndIf
    Bool presented = False
    String settingsFile = GetSettingsFile()
    Bool animationStarted = False
    String animationSource = "Arousal threshold " + arousal
    If MMEArousalAnimations.IsEnabled()
        animationStarted = MMEArousalAnimations.TryStart(target, tier, animationSource)
        If !animationStarted
            MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] animation busy; delaying complete reaction package for one five-second retry | actor=" + GetActorName(target) + " | tier=" + tier)
            Utility.Wait(5.0)
            If StorageUtil.GetIntValue(target, "MMEExtensions.Tentacle.SuppressCrossing", 0) == 1
                Return False
            EndIf
            animationStarted = MMEArousalAnimations.TryStart(target, tier, animationSource + " retry")
            If animationStarted
                MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] delayed animation retry started | actor=" + GetActorName(target) + " | tier=" + tier)
            Else
                MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] delayed animation retry unavailable; presenting notification and sound without animation | actor=" + GetActorName(target) + " | tier=" + tier)
            EndIf
        EndIf
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableArousalEffectNotifications", 1) == 1
        String notificationText = BuildNotification(target, tier)
        If notificationText != ""
            Debug.Notification(notificationText)
            presented = True
        EndIf
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableArousalEffectSounds", 1) == 1 \
    && JsonUtil.GetIntValue(settingsFile, "enableReactionSounds", 1) == 1
        If PlayReactionSound(target, tier)
            presented = True
        EndIf
    EndIf
    If animationStarted
        presented = True
        ; Notification and sound have now started alongside the animation; this
        ; latent finish owns the remaining hold and symmetric cleanup.
        MMEArousalAnimations.FinishStarted(target, tier, animationSource)
    EndIf
    Return presented
EndFunction

String Function BuildNotification(Actor target, Int tier) Global
    ActorBase baseInfo = target.GetLeveledActorBase()
    Bool female = baseInfo == None || baseInfo.GetSex() != 0
    String poolName = GetPoolName(tier, female)
    String fallback = GetFallbackLine(tier, female)
    String configFile = "/MMEAlerts/ArousalEffects"
    If !MMENarrationOverrides.FileAvailable(configFile)
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.JSON", "[MME Extensions Arousal Effects] FAILURE: ArousalEffects.json is missing or malformed; using fallback text")
        Return MMEThoughts.RenderActorToken(fallback, GetActorName(target))
    EndIf
    String[] entries = MMENarrationOverrides.Pool(configFile, "." + poolName, target)
    If entries.Length <= 0
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.JSON." + poolName, "[MME Extensions Arousal Effects] FAILURE: JSON pool is missing or empty: " + poolName + "; using fallback text")
        Return MMEThoughts.RenderActorToken(fallback, GetActorName(target))
    EndIf
    String selected = entries[Utility.RandomInt(0, entries.Length - 1)]
    String rendered = MMEThoughts.RenderActorToken(selected, GetActorName(target))
    If rendered == ""
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.JSON." + poolName, "[MME Extensions Arousal Effects] FAILURE: malformed entry in JSON pool " + poolName + "; using fallback text")
        rendered = MMEThoughts.RenderActorToken(fallback, GetActorName(target))
    Else
        ClearAlarm("MMEExtensions.ArousalEffects.Alarm.JSON")
        ClearAlarm("MMEExtensions.ArousalEffects.Alarm.JSON." + poolName)
    EndIf
    MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] notification selected | actor=" + GetActorName(target) + " | pool=" + poolName)
    Return rendered
EndFunction

Bool Function PlayReactionSound(Actor target, Int tier) Global
    Int markerFormID = 0x000854
    If tier == 2
        markerFormID = 0x000855
    ElseIf tier >= 3
        markerFormID = 0x000856
    EndIf
    Sound reaction = MMEReactionSounds.Resolve(target, markerFormID)
    If reaction == None
        AlarmOnce("MMEExtensions.ArousalEffects.Alarm.Sound." + tier, "[MME Extensions Arousal Effects] FAILURE: tier " + tier + " sound marker did not resolve")
        Return False
    EndIf
    ClearAlarm("MMEExtensions.ArousalEffects.Alarm.Sound." + tier)
    Int instance = reaction.Play(target)
    If instance <= 0
        MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] Sound.Play failed | actor=" + GetActorName(target) + " | tier=" + tier + " | result=" + instance)
        Return False
    EndIf
    Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(GetSettingsFile(), "reactionSoundVolume", 100.0) / 100.0)
    MMELog.MasterDiagnostic("[MME Extensions Arousal Effects] sound played | actor=" + GetActorName(target) + " | tier=" + tier + " | instance=" + instance)
    Return True
EndFunction

String Function GetPoolName(Int tier, Bool female) Global
    If tier >= 3
        If female
            Return "high_female"
        EndIf
        Return "high_male"
    ElseIf tier == 2
        If female
            Return "medium_female"
        EndIf
        Return "medium_male"
    EndIf
    If female
        Return "low_female"
    EndIf
    Return "low_male"
EndFunction

String Function GetFallbackLine(Int tier, Bool female) Global
    If tier >= 3
        If female
            Return "{actor} is visibly flushed. Her body has stopped taking orders."
        EndIf
        Return "{actor} growls low. His body is done being patient."
    ElseIf tier == 2
        If female
            Return "{actor}'s breathing deepens. Her body is running hot and getting hotter."
        EndIf
        Return "{actor}'s voice drops an octave. His thoughts drop lower."
    EndIf
    If female
        Return "{actor} shifts her weight. Her thighs clench together. Just once."
    EndIf
    Return "{actor} shifts his stance. His body has opinions it shouldn't."
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

; Stable normalized extension point. Skyrim.Net can join this boundary later
; without changing threshold selection or creating another nearby scan.
Bool Function DispatchFutureExtensions(Actor target, Int tier, Int arousal) Global
    Return MMEArousalAnimations.TryPlay(target, tier, "Arousal threshold " + arousal)
EndFunction

Function AlarmOnce(String alarmKey, String alarmText) Global
    If StorageUtil.GetIntValue(None, alarmKey, 0) != 1
        StorageUtil.SetIntValue(None, alarmKey, 1)
        MMELog.Alarm(alarmText)
    EndIf
EndFunction

Function ClearAlarm(String alarmKey) Global
    If StorageUtil.GetIntValue(None, alarmKey, 0) == 1
        StorageUtil.UnsetIntValue(None, alarmKey)
    EndIf
EndFunction
