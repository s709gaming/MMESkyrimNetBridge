Scriptname MMESkyrimNetVoiceControls extends Quest Hidden

; ---------------------------------------------------------------------------
; Skyrim.Net action adapters
; ---------------------------------------------------------------------------
; Eligibility callbacks are advisory UI gates; execute callbacks always repeat
; actor/framework checks because world state can change between model selection
; and Papyrus execution. Gameplay remains owned by MME/dialogue/OStim backends.

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
    ; Require an NPC, live loaded actor, real MilkQUEST membership, and no active
    ; observed milking. The action does not infer Milk Maid state from prose.
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
    ; Revalidate every eligibility invariant, then invoke MME's own MilkSelf
    ; spell. This adapter does not reproduce MME's milking implementation.
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

; Fullness-specific trigger adapter. The shared reaction executor owns actor
; validation, standing-animation selection, playback, and safe completion.
Function PlayFullnessSelfMilkAnimation(Actor candidate, Int crossing) Global
    ; Phase 1: map crossing + Player/NPC role to independent settings and duration.
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

    ; Phase 2: delegate all animation validation, cooperative ownership, and safe
    ; reset to MMEReactionAnimation; this adapter only chooses policy.
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", setting, 0) != 1
        If diagnostic
            Debug.Notification("[" + role + "] " + actorName + " " + threshold + " animation skipped: disabled")
        EndIf
        Return
    EndIf
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0)
    String owner = "FullnessAnimation." + role
    String requestLabel = "Fullness " + role + " " + threshold
    Bool animationStarted = MMEReactionAnimation.StartStanding(candidate, owner, requestLabel, diagnostic)
    MMEReactionAnimation.Finish(candidate, animationStarted, owner, duration, requestLabel, diagnostic)
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
    ; MMENPCDialog is the reusable backend for inventory selection, transfer,
    ; native consumption, effects, and animation. Do not duplicate that flow in
    ; a Skyrim.Net action callback.
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
    ; Phase 1: validate action policy and both actor references before selecting
    ; a framework. The parameter contract is explicit source then drinker.
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

    ; Phase 2: OStim is an independent complete backend when enabled. A rejected
    ; OStim request must not silently fall through to SexLab: that would violate
    ; user framework choice and could start a second, unexpected scene.
    ; One Skyrim.Net action, two internal backends. An enabled and available
    ; OStim route owns this request completely; a failed OStim start must not
    ; silently begin a SexLab scene instead.
    If MMEOStimBreastfeeding.IsDialogueEnabled()
        MMEOStimBreastfeeding ostimHandler = MMEExtensionsNative.GetFormByEditorID("MMEExt_OStimBreastfeeding_PlayerDrinks") as MMEOStimBreastfeeding
        If ostimHandler == None
            Bool ostimDiagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
            MMEOStimBreastfeeding.Report(diagnostic || ostimDiagnostic, "Skyrim.Net route could not resolve the installed OStim breastfeeding handler")
            Return
        EndIf
        Bool ostimStarted = ostimHandler.StartBreastfeeding(milkSource, drinker)
        If diagnostic
            If ostimStarted
                Debug.Notification("[MME Debug] OStim breastfeeding request started")
            Else
                Debug.Notification("[MME Debug] FAILED: OStim breastfeeding request was rejected")
            EndIf
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milk-share OStim result " + ostimStarted + " | source " + milkSource + " | drinker " + drinker)
        Return
    EndIf

    ; Phase 3: otherwise use MME's original SexLab interface and registrar names.
    ; Drinker sex selects MME's Var/non-Var animation exactly as the original
    ; pathway expects; missing registration is a failure, never a generic fallback.
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
    ; SexLab's original MME ordering is source first, drinker second. This differs
    ; from OStim action ordering and must not be "normalized" across frameworks.
    sceneActors[0] = milkSource
    sceneActors[1] = drinker
    If diagnostic
        Debug.Notification("[MME Debug] Actor A: " + milkSource.GetDisplayName() + " [" + milkSource.GetFormID() + "]")
        Debug.Notification("[MME Debug] Actor B: " + drinker.GetDisplayName() + " [" + drinker.GetFormID() + "]")
        Debug.Notification("[MME Debug] Actor references resolved")
        Debug.Notification("[MME Debug] Animation lookup: " + animationName)
        Debug.Notification("[MME Debug] SexLab StartSex request")
    EndIf
    ; StartSex is the SexLab commit point; diagnostics report its returned thread
    ; ID but scene lifecycle remains owned by SexLab/MME after this call.
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
