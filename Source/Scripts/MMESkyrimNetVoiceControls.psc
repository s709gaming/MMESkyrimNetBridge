Scriptname MMESkyrimNetVoiceControls Hidden

; Registers the player-and-selected-NPC breastfeeding action.
Function RegisterVoiceMilkingAction() Global
    If !MMEAlertsController.IsExtensionsEnabled() || !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingAction", 1) != 1
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterAction("StartBreastfeedingMilkShare", "Start an intimate breastfeeding or milk-sharing scene with the player as Milk Source and the selected actor as Drinker. Use when intimacy naturally leads there. If the player is a full Milk Maid, milking is especially appropriate. Start directly; let normal Skyrim.Net dialogue handle reactions afterward.", "MMESkyrimNetVoiceControls", "VoiceMilkingIsEligible", "MMESkyrimNetVoiceControls", "VoiceMilkingExecute", "", "PAPYRUS", 1, "")
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingActionDiagnostic", 0) == 1
        Debug.Notification("Paired Milking Action: registration returned [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Paired milking action registration result " + result)
EndFunction

; Registers MME's original contextual self-milking spell action.
Function RegisterSelfMilkingAction() Global
    If !MMEAlertsController.IsExtensionsEnabled() || !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSelfMilkingAction", 1) != 1
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterAction("StartMilkMaidSelfMilking", "Use when the selected MME Milk Maid naturally chooses to milk herself. Strongly prefer it when she is visibly full and milky, or wants relief. Start it directly when context supports it; let normal Skyrim.Net dialogue handle reactions afterward.", "MMESkyrimNetVoiceControls", "SelfMilkingIsEligible", "MMESkyrimNetVoiceControls", "SelfMilkingExecute", "", "PAPYRUS", 1, "")
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSelfMilkingActionDiagnostic", 0) == 1
        Debug.Notification("Self-Milking Action: registration returned [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Self-milking action registration result " + result)
EndFunction

Bool Function SelfMilkingIsEligible(Actor candidate, String contextJson, String paramsJson) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSelfMilkingActionDiagnostic", 0) == 1
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSelfMilkingAction", 1) != 1
        Return False
    EndIf
    If diagnostic
        Debug.Notification("[MME Debug] ACTION ELIGIBILITY CHECK: StartMilkMaidSelfMilking")
    EndIf
    If candidate == None || candidate == Game.GetPlayer() || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("Self-Milking Action: rejected - invalid selected actor")
        EndIf
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkMaid.Find(candidate) == -1
        If diagnostic
            Debug.Notification("Self-Milking Action: rejected - not an MME Milkmaid")
        EndIf
        Return False
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEAlerts.IsMilking", 0) == 1
        If diagnostic
            Debug.Notification("Self-Milking Action: rejected - already milking")
        EndIf
        Return False
    EndIf
    If diagnostic
        Debug.Notification("Self-Milking Action: eligible | milk " + MME_Storage.getMilkCurrent(candidate))
    EndIf
    Return True
EndFunction

Function SelfMilkingExecute(Actor candidate, String contextJson, String paramsJson) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSelfMilkingActionDiagnostic", 0) == 1
    If diagnostic
        Debug.Notification("[MME Debug] LLM ACTION RECEIVED: StartMilkMaidSelfMilking")
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSelfMilkingAction", 1) != 1
        If diagnostic
            Debug.Notification("[MME Debug] FAILED: self-milking action disabled")
        EndIf
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If candidate == None || milkController == None || milkController.MilkMaid.Find(candidate) == -1 || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("Self-Milking Action: execution rejected - invalid target")
        EndIf
        Return
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEAlerts.IsMilking", 0) == 1
        If diagnostic
            Debug.Notification("Self-Milking Action: execution rejected - already milking")
        EndIf
        Return
    EndIf
    If diagnostic
        Debug.Notification("[MME Debug] Actor resolved: " + candidate.GetDisplayName())
        Debug.Notification("[MME Debug] Calling MME MilkSelf")
    EndIf
    milkController.MilkSelf.Cast(candidate)
    If diagnostic
        Debug.Notification("[MME Debug] MME MilkSelf cast requested")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Self-milking action cast MME MilkSelf on " + candidate)
EndFunction

; Registers the opt-in action that reuses the tested NPC dialogue pipeline.
Function RegisterGiveMilkAction() Global
    If !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilk", 0) != 1
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterAction("GiveMilkToMilkmaid", "Use when the player naturally offers milk or Lactacid to the current MME Milkmaid. Give and consume one supported milk item from the player's inventory. Never use on a non-Milkmaid.", "MMESkyrimNetVoiceControls", "VoiceGiveMilkIsEligible", "MMESkyrimNetVoiceControls", "VoiceGiveMilkExecute", "", "PAPYRUS", 1, "")
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilkDiagnostic", 1) == 1
        Debug.Notification("Give Milk Voice: registration returned [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Give Milk action registration result " + result)
EndFunction

; SkyrimNet checks each conversational actor before exposing the action.
Bool Function VoiceGiveMilkIsEligible(Actor candidate) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilkDiagnostic", 1) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilk", 0) != 1
        Return False
    EndIf
    If candidate == None || candidate == Game.GetPlayer() || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("Give Milk Voice: rejected - invalid target")
        EndIf
        Return False
    EndIf
    String actorName = candidate.GetDisplayName()
    If !MMEAlertsSkyrimNet.IsRealMMEMilkmaid(candidate)
        If diagnostic
            Debug.Notification("Give Milk Voice: " + actorName + " rejected - not a Milkmaid")
        EndIf
        Return False
    EndIf
    If diagnostic
        Debug.Notification("Give Milk Voice: " + actorName + " eligible")
    EndIf
    Return True
EndFunction

; Revalidates and delegates inventory selection, transfer, and effects to MMENPCDialog.
Function VoiceGiveMilkExecute(Actor candidate) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilkDiagnostic", 1) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilk", 0) != 1
        Return
    EndIf
    If diagnostic
        Debug.Notification("Give Milk Voice: action attempted")
    EndIf
    Bool success = MMENPCDialog.GiveMilkToTarget(candidate, diagnostic)
    If diagnostic
        If success
            Debug.Notification("Give Milk Voice: item successfully processed")
        Else
            Debug.Notification("Give Milk Voice: failed; see preceding reason")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Give Milk action completed | success=" + success)
EndFunction

; SkyrimNet calls this while preparing actions for each conversational actor.
Bool Function VoiceMilkingIsEligible(Actor candidate, String contextJson, String paramsJson) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingActionDiagnostic", 0) == 1
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingAction", 1) != 1
        Return False
    EndIf
    If diagnostic
        Debug.Notification("[MME Debug] ACTION ELIGIBILITY CHECK: StartBreastfeedingMilkShare")
    EndIf
    If candidate == None || candidate == Game.GetPlayer() || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("Milking Action: rejected - invalid selected actor")
        EndIf
        Return False
    EndIf
    String actorName = candidate.GetDisplayName()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.SexLab == None
        If diagnostic
            Debug.Notification("Milking Action: " + actorName + " rejected - MME or SexLab unavailable")
        EndIf
        Return False
    EndIf
    If milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar") == None || milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding") == None
        If diagnostic
            Debug.Notification("Milking Action: " + actorName + " rejected - MME breastfeeding animations unavailable")
        EndIf
        Return False
    EndIf
    If diagnostic
        Debug.Notification("Milking Action: source Player | drinker " + actorName)
    EndIf
    Return True
EndFunction

; Starts MME's registered breastfeeding animation with the player as source.
Function VoiceMilkingExecute(Actor candidate, String contextJson, String paramsJson) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingActionDiagnostic", 0) == 1
    If diagnostic
        Debug.Notification("[MME Debug] LLM ACTION RECEIVED: StartBreastfeedingMilkShare")
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingAction", 1) != 1
        If diagnostic
            Debug.Notification("[MME Debug] FAILED: paired milking action disabled")
        EndIf
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If candidate == None || playerActor == None || candidate == playerActor || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("Milking Action: execution rejected - invalid actors")
        EndIf
        Return
    EndIf
    String actorName = candidate.GetDisplayName()
    If actorName == ""
        actorName = "selected actor"
    EndIf
    If milkController == None || milkController.SexLab == None
        If diagnostic
            Debug.Notification("Milking Action: execution rejected - MME or SexLab unavailable")
        EndIf
        Return
    EndIf
    sslBaseAnimation[] animations = new sslBaseAnimation[1]
    If candidate.GetLeveledActorBase().GetSex() == 0
        animations[0] = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar")
    Else
        animations[0] = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding")
    EndIf
    If animations[0] == None
        If diagnostic
            Debug.Notification("Milking Action: execution rejected - selected animation unavailable")
        EndIf
        Return
    EndIf
    Actor[] sceneActors = new Actor[2]
    sceneActors[0] = playerActor
    sceneActors[1] = candidate
    If diagnostic
        Debug.Notification("[MME Debug] Source: Player | Drinker: " + actorName)
        Debug.Notification("[MME Debug] Actor references resolved")
        Debug.Notification("[MME Debug] Calling MME scene")
    EndIf
    Int sceneId = milkController.SexLab.StartSex(sceneActors, animations)
    If diagnostic
        If sceneId >= 0
            Debug.Notification("[MME Debug] SexLab scene request sent [" + sceneId + "]")
        Else
            Debug.Notification("[MME Debug] FAILED: SexLab rejected [" + sceneId + "]")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milking action StartSex result " + sceneId + " | provider " + actorName)
EndFunction
