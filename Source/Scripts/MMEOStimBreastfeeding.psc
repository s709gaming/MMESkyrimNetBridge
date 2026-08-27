Scriptname MMEOStimBreastfeeding extends TopicInfo Hidden

; Thin dialogue adapter. Both dialogue and Skyrim.Net call the persistent quest
; service because TopicInfo script objects are not safe external entry points.
Function Fragment_PlayerDrinks(ObjectReference akSpeakerRef)
    StartSharedBreastfeeding(akSpeakerRef as Actor, Game.GetPlayer(), "Dialogue")
EndFunction
Function Fragment_NPCDrinks(ObjectReference akSpeakerRef)
    StartSharedBreastfeeding(Game.GetPlayer(), akSpeakerRef as Actor, "Dialogue")
EndFunction

Bool Function StartSharedBreastfeeding(Actor milkSource, Actor drinker, String caller = "Dialogue") Global
    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        Report(JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1, "persistent OStim breastfeeding service could not resolve")
        Return False
    EndIf
    Return service.StartBreastfeeding(milkSource, drinker, False, caller)
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

; Shared source-side gameplay contract used before either animation backend.
Bool Function ValidateMilkSource(Actor milkSource, MilkQUEST milkController, Bool diagnostic = False) Global
    If milkController == None
        Report(diagnostic, "MME backend unavailable")
        Return False
    EndIf
    If milkController.MilkMaid == None || milkController.MilkMaid.Find(milkSource) == -1
        Report(diagnostic, GetActorName(milkSource) + " is not an MME Milk Maid")
        Return False
    EndIf
    ActorBase milkSourceBase = milkSource.GetLeveledActorBase()
    If milkSourceBase == None || (milkSourceBase.GetSex() != 1 && !(milkSourceBase.GetSex() == 0 && milkController.MaleMaids))
        Report(diagnostic, GetActorName(milkSource) + " is not eligible under MME's Milk Maid sex settings")
        Return False
    EndIf
    If milkController.BeingMilkedPassive == None
        Report(diagnostic, "MME passive-milking state spell is unavailable")
        Return False
    EndIf
    If milkSource.HasSpell(milkController.BeingMilkedPassive)
        Report(diagnostic, GetActorName(milkSource) + " is already being milked")
        Return False
    EndIf
    Return True
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
        Debug.Notification("MME BF Debug\nBreastfeeding request rejected.\nReason: " + reportText)
    EndIf
EndFunction
