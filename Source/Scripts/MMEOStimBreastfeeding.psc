Scriptname MMEOStimBreastfeeding extends TopicInfo Hidden

; MME Fragment_01 parity: the player drinks from the dialogue speaker.
Function Fragment_PlayerDrinks(ObjectReference akSpeakerRef)
    StartBreastfeeding(akSpeakerRef as Actor, Game.GetPlayer())
EndFunction

; MME Fragment_02 parity: the dialogue speaker drinks from the player.
Function Fragment_NPCDrinks(ObjectReference akSpeakerRef)
    StartBreastfeeding(Game.GetPlayer(), akSpeakerRef as Actor)
EndFunction

Bool Function IsOStimDetected() Global
    Return Game.GetModByName("OStim.esp") != 255
EndFunction

Bool Function IsDialogueEnabled() Global
    Return MMEAlertsController.IsExtensionsEnabled() && IsOStimDetected() && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) == 1
EndFunction

Bool Function StartBreastfeeding(Actor milkSource, Actor drinker) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1

    If !MMEAlertsController.IsExtensionsEnabled()
        Report(diagnostic, "MME Extensions is disabled")
        Return False
    EndIf
    If !IsOStimDetected()
        Report(diagnostic, "OStim not detected")
        Return False
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) != 1
        Report(diagnostic, "OStim breastfeeding support is disabled")
        Return False
    EndIf
    If milkSource == None || drinker == None || milkSource == drinker
        Report(diagnostic, "invalid or missing milk-source/drinker actor")
        Return False
    EndIf
    If !IsActorAvailable(milkSource) || !IsActorAvailable(drinker)
        Report(diagnostic, "actors unavailable, dead, disabled, or not loaded")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, "MME backend unavailable")
        Return False
    EndIf
    If milkController.MilkMaid == None || milkController.MilkMaid.Find(milkSource) == -1
        Report(diagnostic, GetActorName(milkSource) + " is not an MME Milk Maid")
        Return False
    EndIf
    If milkController.BeingMilkedPassive != None && milkSource.HasSpell(milkController.BeingMilkedPassive)
        Report(diagnostic, GetActorName(milkSource) + " is already being milked")
        Return False
    EndIf

    Actor[] actors = new Actor[2]
    actors[0] = drinker
    actors[1] = milkSource
    If !OActor.VerifyActors(actors)
        Report(diagnostic, "OStim rejected one or both actors")
        Return False
    EndIf

    String sceneID = OLibrary.GetRandomSceneWithActionForActorAndTarget(actors, 0, 1, "suckingnipples")
    If sceneID == ""
        Report(diagnostic, "no compatible OStim suckingnipples scene found")
        Return False
    EndIf

    Int builderID = OThreadBuilder.Create(actors)
    If builderID < 0
        Report(diagnostic, "OStim scene builder rejected the actors")
        Return False
    EndIf
    OThreadBuilder.SetStartingAnimation(builderID, sceneID)
    OThreadBuilder.NoFurniture(builderID)
    Int threadID = OThreadBuilder.Start(builderID)
    If threadID < 0
        OThreadBuilder.Cancel(builderID)
        Report(diagnostic, "OStim scene start rejected for " + sceneID)
        Return False
    EndIf

    If !RequestMMEMilking(milkSource)
        OThread.Stop(threadID)
        Report(diagnostic, "MME milking event could not be sent; OStim scene stopped")
        Return False
    EndIf
    ApplyMMEBreastfeedingParity(milkSource, drinker, milkController)

    Utility.Wait(0.5)
    If milkController.BeingMilkedPassive != None && !milkSource.HasSpell(milkController.BeingMilkedPassive)
        OThread.Stop(threadID)
        Report(diagnostic, "MME milking request did not start; OStim scene stopped")
        Return False
    EndIf

    Debug.Trace("[MME Extensions OStim] started " + sceneID + " | drinker=" + GetActorName(drinker) + " | milk source=" + GetActorName(milkSource) + " | thread=" + threadID)
    Return True
EndFunction

Bool Function IsActorAvailable(Actor target) Global
    Return target != None && !target.IsDead() && !target.IsDisabled() && target.Is3DLoaded()
EndFunction

; Mirrors MME's SexLab breastfeeding hook behavior that Mode 4 itself omits.
Function ApplyMMEBreastfeedingParity(Actor milkSource, Actor drinker, MilkQUEST milkController) Global
    If MME_Storage.getMilkCurrent(milkSource) < 1.0
        Return
    EndIf

    If milkController.MME_Milk_Basic != None
        Form basicMilk = milkController.MME_Milk_Basic.GetAt(0)
        If basicMilk != None
            drinker.EquipItem(basicMilk, True, True)
        EndIf
    EndIf

    ActorBase drinkerBase = drinker.GetLeveledActorBase()
    Race khajiitRace = Game.GetFormFromFile(0x013745, "Skyrim.esm") as Race
    If drinkerBase != None && drinkerBase.GetRace() == khajiitRace && milkController.MME_Util_Potions != None
        Form lactacid = milkController.MME_Util_Potions.GetAt(0)
        If lactacid != None
            milkSource.AddItem(lactacid, 1, True)
        EndIf
    EndIf
EndFunction

Bool Function RequestMMEMilking(Actor milkSource) Global
    Int handle = ModEvent.Create("MME_Milking")
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, milkSource)
    ModEvent.PushInt(handle, 4)
    ModEvent.PushInt(handle, 0)
    Return ModEvent.Send(handle)
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
