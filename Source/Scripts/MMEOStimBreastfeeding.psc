Scriptname MMEOStimBreastfeeding extends TopicInfo Hidden

; Thin dialogue adapter. Both dialogue and Skyrim.Net call the persistent quest
; service because TopicInfo script objects are not safe external entry points.
Function Fragment_PlayerDrinks(ObjectReference akSpeakerRef)
    StartSharedBreastfeeding(akSpeakerRef as Actor, Game.GetPlayer())
EndFunction
Function Fragment_NPCDrinks(ObjectReference akSpeakerRef)
    StartSharedBreastfeeding(Game.GetPlayer(), akSpeakerRef as Actor)
EndFunction

Bool Function StartSharedBreastfeeding(Actor milkSource, Actor drinker) Global
    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        Report(JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1, "persistent OStim breastfeeding service could not resolve")
        Return False
    EndIf
    Return service.StartBreastfeeding(milkSource, drinker)
EndFunction

Bool Function IsOStimDetected() Global
    Return Game.GetModByName("OStim.esp") != 255
EndFunction

Bool Function IsBreastfeedingEnabled() Global
    Return MMEAlertsController.IsExtensionsEnabled() && IsOStimDetected() && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) == 1
EndFunction

Bool Function IsDialogueEnabled() Global
    Return IsBreastfeedingEnabled()
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<no actor>"
    EndIf
    String result = target.GetDisplayName()
    If result == ""
        ActorBase baseInfo = target.GetLeveledActorBase()
        If baseInfo != None
            result = baseInfo.GetName()
        EndIf
    EndIf
    If result == ""
        result = "Unknown actor"
    EndIf
    Return result
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MME Extensions OStim] " + reportText)
    If showNotification
        Debug.Notification("OStim Debug: " + reportText)
    EndIf
EndFunction
