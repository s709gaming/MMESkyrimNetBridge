Scriptname MMEArousalBridge Hidden

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

; SexLab Aroused Redux and OSLAroused both expose this compatibility master.
Bool Function IsAvailable() Global
    Return Game.GetModByName("SexLabAroused.esm") != 255
EndFunction

; Raises arousal through SLA's public event without creating a script dependency.
Function ApplyMilkDrinkArousal(Actor drinker, Form drinkItem) Global
    String settingsFile = GetSettingsFile()
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableArousalDiagnostic", 1) == 1
    If drinker == None || drinker != Game.GetPlayer()
        Report(diagnostic, "skipped: drinker is not the player")
        Return
    EndIf
    ApplyMilkDrinkArousalForActor(drinker, drinkItem, diagnostic)
EndFunction

; Actor-safe implementation shared by player drinking and explicit NPC interactions.
Bool Function ApplyMilkDrinkArousalForActor(Actor drinker, Form drinkItem, Bool showDiagnostic = False) Global
    String settingsFile = GetSettingsFile()
    String actorName = GetActorName(drinker)
    If drinker == None
        Report(showDiagnostic, "skipped: drinker not found")
        Return False
    EndIf
    If !IsAvailable()
        Report(showDiagnostic, "skipped: SexLabAroused.esm not detected")
        Return False
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableMilkDrinkArousal", 1) != 1
        Report(showDiagnostic, "skipped for " + actorName + ": Milk Raises Arousal is off")
        Return False
    EndIf

    Float configuredAmount = JsonUtil.GetFloatValue(settingsFile, "milkDrinkArousal", 5.0)
    If configuredAmount < 0.0
        configuredAmount = 0.0
    ElseIf configuredAmount > 100.0
        configuredAmount = 100.0
    EndIf
    String itemName = "<unnamed milk>"
    If drinkItem != None && drinkItem.GetName() != ""
        itemName = drinkItem.GetName()
    EndIf

    Int arousalBefore = GetCurrentArousal(drinker)
    Float amountToSend = configuredAmount
    If arousalBefore >= 0 && arousalBefore as Float + amountToSend > 100.0
        amountToSend = 100.0 - arousalBefore as Float
    EndIf
    Report(showDiagnostic, actorName + " drank " + itemName + "; arousal " + arousalBefore + ", sending +" + amountToSend)

    If amountToSend <= 0.0
        If arousalBefore >= 100
            Report(showDiagnostic, actorName + " arousal remains capped at 100")
        Else
            Report(showDiagnostic, "no event sent: configured arousal is 0")
        EndIf
        Return False
    EndIf
    Int handle = ModEvent.Create("slaUpdateExposure")
    If handle == 0
        Report(showDiagnostic, "failed: slaUpdateExposure event creation returned 0")
        Return False
    EndIf
    ModEvent.PushForm(handle, drinker)
    ModEvent.PushFloat(handle, amountToSend)
    Bool sent = ModEvent.Send(handle)
    If sent
        If showDiagnostic
            ; ModEvents are asynchronous; allow SLA to consume the event before reading its faction value.
            Utility.Wait(0.25)
            Int arousalAfter = GetCurrentArousal(drinker)
            Report(True, "slaUpdateExposure sent: " + actorName + " " + arousalBefore + " -> " + arousalAfter)
        Else
            Report(False, "slaUpdateExposure sent for " + actorName + " (+" + amountToSend + ")")
        EndIf
        Return True
    Else
        Report(showDiagnostic, "failed: slaUpdateExposure send returned false")
        Return False
    EndIf
EndFunction

; Reads SLA's public compatibility faction without importing any SLA scripts.
Int Function GetCurrentArousal(Actor actorRef) Global
    If actorRef == None || !IsAvailable()
        Return -1
    EndIf
    Faction arousalFaction = Game.GetFormFromFile(0x03FC36, "SexLabAroused.esm") as Faction
    If arousalFaction == None || !actorRef.IsInFaction(arousalFaction)
        Return -1
    EndIf
    Int result = actorRef.GetFactionRank(arousalFaction)
    If result < 0
        Return -1
    ElseIf result > 100
        Return 100
    EndIf
    Return result
EndFunction

String Function GetActorName(Actor actorRef) Global
    If actorRef == None
        Return "<no actor>"
    EndIf
    String result = actorRef.GetDisplayName()
    If result == ""
        ActorBase baseInfo = actorRef.GetLeveledActorBase()
        If baseInfo != None
            result = baseInfo.GetName()
        EndIf
    EndIf
    If result == ""
        result = "Player"
    EndIf
    Return result
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MMEAlert Arousal] " + reportText)
    If showNotification
        Debug.Notification("Arousal Debug: " + reportText)
    EndIf
EndFunction
