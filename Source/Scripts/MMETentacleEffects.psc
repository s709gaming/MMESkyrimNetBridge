Scriptname MMETentacleEffects Hidden

; Stateless Living/Parasite armor injection gameplay. The established
; MMEAlertsController quest owns the single game-time registration so upgrades
; work in existing saves and Thoughts can share the same nearby-actor scan.

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

Bool Function IsEnabled() Global
    String settingsFile = GetSettingsFile()
    Return JsonUtil.GetIntValue(settingsFile, "enableMMEExtensions", 1) == 1 \
        && JsonUtil.GetIntValue(settingsFile, "enableArmorInjections", 1) == 1
EndFunction

Bool Function IsDiagnosticEnabled() Global
    Return JsonUtil.GetIntValue(GetSettingsFile(), "enableArmorInjectionDiagnostics", 0) == 1
EndFunction

; The MCM exposes 1..864 base hours and 0..12 variation. Defensive clamps keep
; hand-edited JSON from creating a zero/negative rapid-update loop.
Float Function CalculateNextInterval(Float baseInterval, Float variation) Global
    If baseInterval < 1.0
        baseInterval = 1.0
    ElseIf baseInterval > 864.0
        baseInterval = 864.0
    EndIf
    If variation < 0.0
        variation = 0.0
    ElseIf variation > 12.0
        variation = 12.0
    EndIf

    Float effectiveVariation = variation
    Float allowedVariation = baseInterval - 1.0
    If effectiveVariation > allowedVariation
        effectiveVariation = allowedVariation
    EndIf

    Float nextInterval = baseInterval
    If effectiveVariation > 0.0
        nextInterval = baseInterval + Utility.RandomFloat(-effectiveVariation, effectiveVariation)
    EndIf
    If nextInterval < 1.0
        nextInterval = 1.0
    EndIf
    Return nextInterval
EndFunction

; Runs both scheduled and manual checks. Manual checks bypass only the timer;
; they retain the live enable gate, actor validation, armor check, and chance.
Bool Function RunInjectionCheck(Actor[] scannedActors, Bool manualDiagnostic = False) Global
    Bool diagnostic = manualDiagnostic || IsDiagnosticEnabled()
    If !IsEnabled()
        Report(diagnostic, "check skipped: Tentacle Effects are disabled")
        Return False
    EndIf
    ; Array.Length is zero for an uninitialized array too. Comparing to None
    ; emits an invalid array cast and can falsely reject a populated scan.
    If scannedActors.Length == 0
        Report(diagnostic, "check skipped: nearby scan returned no actors")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, "check skipped: MME_MilkQUEST is unavailable")
        Return False
    EndIf

    Int chance = JsonUtil.GetIntValue(GetSettingsFile(), "armorInjectionChance", 100)
    If chance < 0
        chance = 0
    ElseIf chance > 100
        chance = 100
    EndIf

    Actor playerActor = Game.GetPlayer()
    Actor focusActor = None
    Int focusArmorClass = 0
    Actor narrationActor = None
    Float narrationMilkAdded = 0.0
    Int narrationArousalBefore = -1
    Bool narrationArousalSent = False
    Bool trackNarration = JsonUtil.GetIntValue(GetSettingsFile(), "enableArmorInjectionNarration", 1) == 1
    Int validMaidCount = 0
    Int eligibleCount = 0
    Int injectedCount = 0
    Int i = 0
    Report(diagnostic, "check started | nearby actors=" + scannedActors.Length + " | chance=" + chance + "%")
    While i < scannedActors.Length
        Actor candidate = scannedActors[i]
        If IsValidCandidate(candidate, milkController)
            validMaidCount += 1
            Armor wornArmor = candidate.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
            Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "injection", candidate)
            String actorName = MMEThoughts.ResolveActorName(candidate)
            Report(diagnostic, "candidate=" + actorName + " | armor=" + MMEArmorScript.GetArmorName(wornArmor) + " | class=" + armorClass + " " + MMEArmorScript.GetArmorTypeLabel(armorClass))
            If armorClass == 2 || armorClass == 3
                eligibleCount += 1
                Int roll = Utility.RandomInt(1, 100)
                If roll <= chance
                    Float milkBefore = 0.0
                    Int arousalBefore = -1
                    If diagnostic
                        milkBefore = MME_Storage.getMilkCurrent(candidate)
                    EndIf
                    ; Observe only; never infer success from the configured bonus.
                    ; Capture the baseline before the existing asynchronous SLA call.
                    Bool selectForNarration = focusActor == None || candidate == playerActor
                    If diagnostic || (trackNarration && selectForNarration)
                        arousalBefore = MMEArousalBridge.GetCurrentArousal(candidate)
                    EndIf

                    ; Normal milk kind + recordDrinkAttempt=False reuses the MCM
                    ; formula without Lactacid math or player post-drink state.
                    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(candidate, 1, False, False)
                    Bool arousalSent = MMEArousalBridge.ApplyConfiguredMilkArousalForActor(candidate, "armor injection", False)
                    If diagnostic && arousalSent
                        ; SLA consumes ModEvents asynchronously. This diagnostic-
                        ; only wait makes the optional after-value meaningful.
                        Utility.Wait(0.25)
                    EndIf
                    injectedCount += 1
                    If focusActor == None || candidate == playerActor
                        focusActor = candidate
                        focusArmorClass = armorClass
                    EndIf
                    ; Keep the exact HUD wearer and its results. Disabling player
                    ; speech must not substitute an NPC for the selected player.
                    If selectForNarration
                        narrationActor = candidate
                        narrationMilkAdded = milkAdded
                        narrationArousalBefore = arousalBefore
                        narrationArousalSent = arousalSent
                    EndIf
                    If diagnostic
                        Float milkAfter = MME_Storage.getMilkCurrent(candidate)
                        Int arousalAfter = MMEArousalBridge.GetCurrentArousal(candidate)
                        Report(True, "injected=" + actorName + " | roll=" + roll + "/" + chance + " | milk=" + milkBefore + " -> " + milkAfter + " (delta=" + milkAdded + ") | arousal=" + arousalBefore + " -> " + arousalAfter + " | arousal event=" + arousalSent)
                    EndIf
                Else
                    Report(diagnostic, "missed=" + actorName + " | roll=" + roll + " > " + chance)
                EndIf
            EndIf
        EndIf
        i += 1
    EndWhile

    Report(diagnostic, "check complete | valid Milk Maids=" + validMaidCount + " | eligible armor=" + eligibleCount + " | injected=" + injectedCount)
    If injectedCount <= 0 || focusActor == None
        Report(diagnostic, "narration skipped: no successfully affected wearer; roll not made")
        Return False
    EndIf

    String focusName = MMEThoughts.ResolveActorName(focusActor)
    Report(diagnostic, "notification focus=" + focusName + " | armor=" + MMEArmorScript.GetArmorTypeLabel(focusArmorClass) + " | others=" + (injectedCount - 1))
    If JsonUtil.GetIntValue(GetSettingsFile(), "enableArmorInjectionNotifications", 1) == 1
        String notificationText = BuildNotification(focusName, injectedCount)
        If notificationText != ""
            Debug.Notification(notificationText)
            PlayNotificationSound(focusActor)
        EndIf
    EndIf

    ; Exactly one optional request, after all gameplay and the unchanged HUD.
    ; The bridge owns gates, chance, result-aware JSON, and wearer-as-speaker.
    If narrationActor != None
        Report(diagnostic, "narration wearer=" + MMEThoughts.ResolveActorName(narrationActor) + " | HUD focus=" + focusName)
    Else
        Report(diagnostic, "narration skipped: no affected narration candidate")
    EndIf
    MMEAlertsSkyrimNet.NarrateTentacleEffect(narrationActor, narrationMilkAdded, narrationArousalBefore, narrationArousalSent, diagnostic)
    Return True
EndFunction

; Reuse the packaged low sound pool; the sound descriptor owns random selection.
; One playback on the notification wearer, independent of Skyrim.Net narration.
Function PlayNotificationSound(Actor wearer) Global
    If wearer == None || wearer.IsChild()
        Return
    EndIf
    String settingsFile = GetSettingsFile()
    If JsonUtil.GetIntValue(settingsFile, "enableArmorInjectionSounds", 1) != 1 || JsonUtil.GetIntValue(settingsFile, "enableReactionSounds", 1) != 1
        Return
    EndIf
    Sound reaction = MMEReactionSounds.Resolve(wearer, 0x000854)
    If reaction == None
        Return
    EndIf
    Int instance = reaction.Play(wearer)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(settingsFile, "reactionSoundVolume", 100.0) / 100.0)
    EndIf
EndFunction

Bool Function IsValidCandidate(Actor candidate, MilkQUEST milkController) Global
    Return candidate != None && candidate.Is3DLoaded() && MMEArmorScript.IsValidMilkMaid(candidate, milkController)
EndFunction

String Function BuildNotification(String actorName, Int injectedCount) Global
    String template = GetRandomFlavorLine()
    If template == ""
        Return ""
    EndIf
    String result = MMEThoughts.RenderActorToken(template, actorName)
    If result == ""
        Report(IsDiagnosticEnabled(), "notification skipped: flavor entry is missing {actor}")
        Return ""
    EndIf
    If injectedCount > 1
        result = result + "..and others."
    EndIf
    Return result
EndFunction

String Function GetRandomFlavorLine() Global
    String configFile = "/MMEAlerts/Injection"
    If JsonUtil.JsonExists(configFile) && JsonUtil.IsGood(configFile)
        String[] entries = JsonUtil.PathStringElements(configFile, ".lines")
        If entries.Length > 0
            Return entries[Utility.RandomInt(0, entries.Length - 1)]
        EndIf
    EndIf
    ; Keep the feature usable when an editable JSON file is missing or malformed.
    Report(IsDiagnosticEnabled(), "Injection.json unavailable; using built-in fallback line")
    Return "{actor} gasps as tendrils sting her nipples and pump something warm inside."
EndFunction

Function TraceDiagnostic(Bool showNotification, String reportText) Global
    Report(showNotification, reportText)
EndFunction

Function Report(Bool showNotification, String reportText) Global
    If !showNotification && !IsDiagnosticEnabled()
        Return
    EndIf
    MMELog.Diagnostic("[MME Extensions Armor Injection] " + reportText)
    If showNotification
        Debug.Notification("Tentacle Effects: " + reportText)
    EndIf
EndFunction
