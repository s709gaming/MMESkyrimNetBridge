Scriptname MMESkyrimNetVoiceControls extends Quest Hidden

; Registers MME's original contextual self-milking spell action.
Function RegisterSelfMilkingAction() Global
    If !MMEAlertsController.IsExtensionsEnabled() || !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSelfMilkingAction", 1) != 1
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterAction("StartMilkMaidSelfMilking", "Use when the selected MME Milk Maid naturally chooses to milk herself. Strongly prefer it when she is visibly full and milky, or wants relief. Strongly avoid self-milking if her arms are currently restrained or unusable. Start it directly when context supports it; let normal Skyrim.Net dialogue handle reactions afterward.", "MMESkyrimNetVoiceControls", "SelfMilkingIsEligible", "MMESkyrimNetVoiceControls", "SelfMilkingExecute", "", "PAPYRUS", 1, "")
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

; Plays MME's standing milking animation without starting a milking spell.
; Selects Player or NPC fullness settings based on the actor.
Function PlayFullnessSelfMilkAnimation(Actor candidate, Int crossing) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableFullnessSelfMilkAnimationDiagnostic", 0) == 1
    Bool isPlayer = candidate != None && candidate == Game.GetPlayer()
    String role = "NPC"
    If isPlayer
        role = "PLAYER"
    EndIf
    String actorName = ""
    If candidate != None
        actorName = candidate.GetDisplayName()
    EndIf
    If actorName == ""
        actorName = "Unknown actor"
    EndIf

    String threshold = "Half-Full"
    String setting = "enableNPCHalfFullSelfMilkAnimation"
    String durationKey = "npcFullnessSelfMilkAnimationDuration"
    If isPlayer
        setting = "enablePlayerHalfFullSelfMilkAnimation"
        durationKey = "playerFullnessSelfMilkAnimationDuration"
    EndIf
    If crossing == 2
        threshold = "Full"
        If isPlayer
            setting = "enablePlayerFullSelfMilkAnimation"
        Else
            setting = "enableNPCFullSelfMilkAnimation"
        EndIf
    ElseIf crossing != 1
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " fullness animation skipped: invalid threshold")
        EndIf
        Return
    EndIf

    If JsonUtil.GetIntValue("/MMEAlerts/Settings", setting, 0) != 1
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: disabled")
        EndIf
        Return
    EndIf
    If candidate == None || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: actor unavailable")
        EndIf
        Return
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEAlerts.IsMilking", 0) == 1
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: already milking")
        EndIf
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkMaid.Find(candidate) == -1
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: not an MME Milkmaid")
        EndIf
        Return
    EndIf
    If MMEAlertsController.IsFreeArmAnimationBlocked(candidate)
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: arms restrained by Devious Devices")
        EndIf
        Return
    EndIf
    Int animationCount = JsonUtil.StringListCount("/MME/Strings", "standingmilkinganimations")
    If animationCount <= 0
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: MME milking animation missing")
        EndIf
        Return
    EndIf
    String animationEvent = JsonUtil.StringListGet("/MME/Strings", "standingmilkinganimations", Utility.RandomInt(0, animationCount - 1))
    If animationEvent == ""
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: MME milking animation empty")
        EndIf
        Return
    EndIf
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0)
    If diagnostic
        Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation started (" + duration + " seconds)")
    EndIf
    Debug.SendAnimationEvent(candidate, animationEvent)
    Utility.Wait(duration)
    If candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation stopped - actor unavailable")
        EndIf
        Return
    EndIf
    Debug.SendAnimationEvent(candidate, "IdleForceDefaultState")
    If diagnostic
        Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation stopped")
    EndIf
    Debug.Trace("[MMEAlert] " + role + " fullness animation completed | " + candidate + " | " + threshold)
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

; Skyrim.Net resolves its conversational second actor through the target parameter.
Function StartBreastfeedingMilkShare(Actor milkSource, Actor target) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingActionDiagnostic", 0) == 1
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingAction", 1) != 1
        If diagnostic
            Debug.Notification("[MME Debug] FAILED: paired milking action disabled")
        EndIf
        Return
    EndIf
    If diagnostic
        Debug.Notification("[MME Debug] LLM ACTION RECEIVED: StartBreastfeedingMilkShare")
    EndIf
    Actor drinker = target
    If milkSource == None || drinker == None
        If diagnostic
            Debug.Notification("[MME Debug] FAILED: actor could not resolve")
        EndIf
        Return
    EndIf
    If milkSource == drinker || milkSource.IsDead() || milkSource.IsDisabled() || !milkSource.Is3DLoaded() || drinker.IsDead() || drinker.IsDisabled() || !drinker.Is3DLoaded()
        If diagnostic
            Debug.Notification("[MME Debug] FAILED: actors must be different, alive, enabled, and loaded")
        EndIf
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.SexLab == None
        If diagnostic
            Debug.Notification("[MME Debug] FAILED: MME or SexLab unavailable")
        EndIf
        Return
    EndIf
    sslBaseAnimation[] animations = new sslBaseAnimation[1]
    String animationName = "zjBreastFeeding"
    If drinker.GetLeveledActorBase().GetSex() == 0
        animationName = "zjBreastFeedingVar"
        animations[0] = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar")
    Else
        animations[0] = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding")
    EndIf
    If animations[0] == None
        If diagnostic
            Debug.Notification("[MME Debug] FAILED: animation lookup missing " + animationName)
        EndIf
        Return
    EndIf
    Actor[] sceneActors = new Actor[2]
    sceneActors[0] = milkSource
    sceneActors[1] = drinker
    If diagnostic
        Debug.Notification("[MME Debug] Actor A: " + milkSource.GetDisplayName() + " [" + milkSource.GetFormID() + "]")
        Debug.Notification("[MME Debug] Actor B: " + drinker.GetDisplayName() + " [" + drinker.GetFormID() + "]")
        Debug.Notification("[MME Debug] Actor references resolved")
        Debug.Notification("[MME Debug] Animation lookup: " + animationName)
        Debug.Notification("[MME Debug] SexLab StartSex request")
    EndIf
    Int sceneId = milkController.SexLab.StartSex(sceneActors, animations)
    If diagnostic
        If sceneId >= 0
            Debug.Notification("[MME Debug] SexLab thread result: " + sceneId)
        Else
            Debug.Notification("[MME Debug] FAILED: SexLab rejected [" + sceneId + "]")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milk-share StartSex result " + sceneId + " | source " + milkSource + " | drinker " + drinker)
EndFunction
