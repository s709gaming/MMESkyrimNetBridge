Scriptname MMEDwemerEffects Hidden

; Periodic class-4 Dwemer Armor effects. The established controller owns the
; only game-time registration and supplies its shared nearby-actor scan.

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

Bool Function IsEnabled() Global
    String settingsFile = GetSettingsFile()
    Return JsonUtil.GetIntValue(settingsFile, "enableMMEExtensions", 1) == 1 \
        && JsonUtil.GetIntValue(settingsFile, "enableDwemerEffects", 1) == 1
EndFunction

Bool Function IsDiagnosticEnabled() Global
    Return JsonUtil.GetIntValue(GetSettingsFile(), "enableDwemerEffectDiagnostics", 0) == 1
EndFunction

Float Function CalculateNextInterval(Float baseInterval, Float variation) Global
    Return MMETentacleEffects.CalculateNextInterval(baseInterval, variation)
EndFunction

Bool Function RunEffectCheck(Actor[] scannedActors, Bool manualDiagnostic = False, Bool applyScheduledChance = True) Global
    Bool diagnostic = manualDiagnostic || IsDiagnosticEnabled()
    If !IsEnabled()
        Report(diagnostic, "check skipped: Dwemer Effects are disabled")
        Return False
    EndIf
    If scannedActors.Length == 0
        Report(diagnostic, "check skipped: nearby scan returned no actors")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        MMELog.Alarm("[MME Extensions Dwemer Effects] MME controller unavailable")
        Return False
    EndIf

    Int chance = 100
    If applyScheduledChance
        chance = JsonUtil.GetIntValue(GetSettingsFile(), "dwemerEffectChance", 100)
        If chance < 0
            chance = 0
        ElseIf chance > 100
            chance = 100
        EndIf
    EndIf

    Actor playerActor = Game.GetPlayer()
    Actor focusActor = None
    Actor narrationActor = None
    Float narrationMilkAdded = 0.0
    Int narrationArousalBefore = -1
    Bool narrationArousalSent = False
    Bool trackNarration = JsonUtil.GetIntValue(GetSettingsFile(), "enableDwemerEffectNarration", 1) == 1
    Int validMaidCount = 0
    Int eligibleCount = 0
    Int affectedCount = 0
    Int index = 0
    Report(False, "check started | nearby actors=" + scannedActors.Length + " | chance=" + chance + "%")
    While index < scannedActors.Length
        Actor candidate = scannedActors[index]
        If IsValidCandidate(candidate, milkController)
            validMaidCount += 1
            Armor wornArmor = candidate.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
            Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "Dwemer effect", candidate)
            String actorName = MMEThoughts.ResolveActorName(candidate)
            Report(False, "candidate=" + actorName + " | armor=" + MMEArmorScript.GetArmorName(wornArmor) + " | class=" + armorClass)
            If armorClass == 4
                eligibleCount += 1
                Int roll = 1
                If applyScheduledChance
                    roll = Utility.RandomInt(1, 100)
                EndIf
                If roll <= chance
                    Float milkBefore = 0.0
                    Int arousalBefore = -1
                    Bool selectForNarration = focusActor == None || candidate == playerActor
                    If diagnostic
                        milkBefore = MME_Storage.getMilkCurrent(candidate)
                    EndIf
                    If diagnostic || (trackNarration && selectForNarration)
                        arousalBefore = MMEArousalBridge.GetCurrentArousal(candidate)
                    EndIf
                    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(candidate, 1, False, False)
                    Bool arousalSent = MMEArousalBridge.ApplyConfiguredMilkArousalForActor(candidate, "Dwemer armor effect", False)
                    If diagnostic && arousalSent
                        Utility.Wait(0.25)
                    EndIf
                    affectedCount += 1
                    If focusActor == None || candidate == playerActor
                        focusActor = candidate
                    EndIf
                    If selectForNarration
                        narrationActor = candidate
                        narrationMilkAdded = milkAdded
                        narrationArousalBefore = arousalBefore
                        narrationArousalSent = arousalSent
                    EndIf
                    If diagnostic
                        Float milkAfter = MME_Storage.getMilkCurrent(candidate)
                        Int arousalAfter = MMEArousalBridge.GetCurrentArousal(candidate)
                        Report(True, "affected=" + actorName + " | roll=" + roll + "/" + chance + " | milk=" + milkBefore + " -> " + milkAfter + " | arousal=" + arousalBefore + " -> " + arousalAfter + " | arousal event=" + arousalSent)
                    EndIf
                Else
                    Report(False, "missed=" + actorName + " | roll=" + roll + " > " + chance)
                EndIf
            EndIf
        EndIf
        index += 1
    EndWhile

    Report(False, "check complete | valid Milk Maids=" + validMaidCount + " | eligible Dwemer=" + eligibleCount + " | affected=" + affectedCount)
    If affectedCount <= 0 || focusActor == None
        Return False
    EndIf

    If JsonUtil.GetIntValue(GetSettingsFile(), "enableDwemerEffectNotifications", 1) == 1
        String notificationText = BuildNotification(MMEThoughts.ResolveActorName(focusActor), affectedCount)
        If notificationText != ""
            Debug.Notification(notificationText)
            PlayNotificationSound(focusActor)
        EndIf
    EndIf
    MMEAlertsSkyrimNet.NarrateDwemerEffect(narrationActor, narrationMilkAdded, narrationArousalBefore, narrationArousalSent, diagnostic)
    Return True
EndFunction

Bool Function IsValidCandidate(Actor candidate, MilkQUEST milkController) Global
    Return candidate != None && candidate.Is3DLoaded() && MMEArmorScript.IsValidMilkMaid(candidate, milkController)
EndFunction

String Function BuildNotification(String actorName, Int affectedCount) Global
    String template = GetRandomFlavorLine()
    If template == ""
        Return ""
    EndIf
    String result = MMEThoughts.RenderActorToken(template, actorName)
    If result == ""
        MMELog.Alarm("[MME Extensions Dwemer Effects] notification entry is missing {actor}")
        Return ""
    EndIf
    If affectedCount > 1
        result = result + "..and others."
    EndIf
    Return result
EndFunction

String Function GetRandomFlavorLine() Global
    String configFile = "/MMEAlerts/DwemerEffectNotifications"
    If JsonUtil.JsonExists(configFile) && JsonUtil.IsGood(configFile)
        String[] entries = JsonUtil.PathStringElements(configFile, ".lines")
        If entries.Length > 0
            Return entries[Utility.RandomInt(0, entries.Length - 1)]
        EndIf
    EndIf
    MMELog.Alarm("[MME Extensions Dwemer Effects] notification JSON missing, malformed, or empty; using fallback")
    Return "{actor} moans as Dwemer armor teases her nipples."
EndFunction

Function PlayNotificationSound(Actor wearer) Global
    If wearer == None || wearer.IsChild()
        Return
    EndIf
    String settingsFile = GetSettingsFile()
    If JsonUtil.GetIntValue(settingsFile, "enableDwemerEffectSounds", 1) != 1 || JsonUtil.GetIntValue(settingsFile, "enableReactionSounds", 1) != 1
        Return
    EndIf
    Sound reaction = MMEReactionSounds.Resolve(wearer, 0x000854)
    If reaction == None
        MMELog.Alarm("[MME Extensions Dwemer Effects] low notification sound marker unresolved")
        Return
    EndIf
    Int instance = reaction.Play(wearer)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(settingsFile, "reactionSoundVolume", 100.0) / 100.0)
    Else
        MMELog.MasterDiagnostic("[MME Extensions Dwemer Effects] Sound.Play failed | result=" + instance)
    EndIf
EndFunction

Function TraceDiagnostic(Bool showNotification, String reportText) Global
    Report(showNotification, reportText)
EndFunction

Function Report(Bool showNotification, String reportText) Global
    MMELog.MasterDiagnostic("[MME Extensions Dwemer Effects] " + reportText)
    If showNotification
        Debug.Notification("Dwemer Effects: " + reportText)
    EndIf
EndFunction
