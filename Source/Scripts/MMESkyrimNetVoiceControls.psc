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
    MMELog.Diagnostic("[MMEAlert SkyrimNet] Self-milking action registration result " + result)
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
    If milkController == None || !MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
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
    If candidate == None || milkController == None || !MMEArmorScript.IsMMEMilkMaid(candidate, milkController) || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
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
    MMELog.Diagnostic("[MMEAlert SkyrimNet] Self-milking action cast MME MilkSelf on " + candidate)
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

; Static YAML action policy for player-to-speaker Give Milk. Skyrim.Net clears
; its own busy state as soon as it hands off to Papyrus, so this adapter owns a
; real-time cooldown before entering the latent inventory/animation transaction.
Float Function GetGiveMilkActionCooldownRemaining() Global
    String settingsFile = "/MMEAlerts/Settings"
    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "giveMilkActionCooldown", 45.0)
    If cooldown < 5.0
        cooldown = 5.0
    ElseIf cooldown > 300.0
        cooldown = 300.0
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastGiveMilkActionRealTime", -1.0)
    If last < 0.0 || last > now
        Return 0.0
    EndIf
    Float remaining = cooldown - (now - last)
    If remaining < 0.0
        Return 0.0
    EndIf
    Return remaining
EndFunction

Function MarkGiveMilkActionCooldown() Global
    String settingsFile = "/MMEAlerts/Settings"
    JsonUtil.SetFloatValue(settingsFile, "lastGiveMilkActionRealTime", Utility.GetCurrentRealTime())
    JsonUtil.Save(settingsFile, False)
EndFunction

Function GivePlayerMilkToSpeaker(Actor target) Global
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableGiveMilkActionDiagnostic", 0) == 1
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue(settingsFile, "enableGiveMilkAction", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Give Milk: rejected - action disabled")
        EndIf
        Return
    EndIf
    If target == None || target == Game.GetPlayer() || target.IsDead() || target.IsDisabled() || !target.Is3DLoaded() || target.IsChild()
        If diagnostic
            Debug.Notification("Skyrim.Net Give Milk: rejected - speaker is not an available adult NPC")
        EndIf
        Return
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        MMELog.Alarm("[MME Extensions Skyrim.Net Give Milk] FAILURE: MME controller could not resolve")
        Return
    EndIf
    Bool establishedMilkmaid = MMEArmorScript.IsMMEMilkMaid(target, milkController)
    If !establishedMilkmaid && !MMENPCDrinkDialogue.IsEligible(target, milkController, diagnostic)
        If diagnostic
            Debug.Notification("Skyrim.Net Give Milk: rejected - speaker is not an eligible adult receiver")
        EndIf
        Return
    EndIf

    Float cooldownRemaining = GetGiveMilkActionCooldownRemaining()
    If cooldownRemaining > 0.0
        MMELog.Diagnostic("[MMEAlert SkyrimNet Give Milk] rejected | action cooldown active | remaining=" + (cooldownRemaining as Int) + "s")
        If diagnostic
            Debug.Notification("Skyrim.Net Give Milk: cooldown " + (cooldownRemaining as Int) + "s")
        EndIf
        Return
    EndIf

    ; Claim before the latent transaction. Skyrim.Net may otherwise dispatch a
    ; second request after clearing its own busy flag but before Papyrus returns.
    MarkGiveMilkActionCooldown()
    MMELog.Diagnostic("[MMEAlert SkyrimNet Give Milk] transaction accepted | player giver=" + Game.GetPlayer() + " | speaker/drinker=" + target + " | established Milkmaid=" + establishedMilkmaid)
    Bool success = MMENPCDialog.GiveMilkToTarget(target, diagnostic, False, True)
    If diagnostic
        If success
            Debug.Notification("Skyrim.Net Give Milk: milk consumed")
        Else
            Debug.Notification("Skyrim.Net Give Milk: transaction failed; see preceding reason")
        EndIf
    EndIf
    MMELog.Diagnostic("[MMEAlert SkyrimNet Give Milk] transaction complete | success=" + success + " | speaker/drinker=" + target)
EndFunction

; Legacy dynamically registered prototype retained for save/callback
; compatibility. Current packages use the YAML quest action above.
Function RegisterGiveMilkAction() Global
    If !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilk", 0) != 1
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterAction("GiveMilkToMilkmaid", "Use when the player naturally offers milk or Lactacid to the current MME Milkmaid. Give and consume one supported milk item from the player's inventory. Never use on a non-Milkmaid.", "MMESkyrimNetVoiceControls", "VoiceGiveMilkIsEligible", "MMESkyrimNetVoiceControls", "VoiceGiveMilkExecute", "", "PAPYRUS", 1, "")
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilkDiagnostic", 1) == 1
        Debug.Notification("Give Milk Voice: registration returned [" + result + "]")
    EndIf
    MMELog.Diagnostic("[MMEAlert SkyrimNet] Give Milk action registration result " + result)
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
    MMELog.Diagnostic("[MMEAlert SkyrimNet] Give Milk action completed | success=" + success)
EndFunction

; Skyrim.Net resolves its conversational second actor through the target parameter.
Float Function GetBreastfeedingActionCooldownRemaining() Global
    String settingsFile = "/MMEAlerts/Settings"
    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "breastfeedingActionCooldown", 45.0)
    If cooldown < 5.0
        cooldown = 5.0
    ElseIf cooldown > 300.0
        cooldown = 300.0
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastBreastfeedingActionRealTime", -1.0)
    If last < 0.0 || last > now
        Return 0.0
    EndIf
    Float remaining = cooldown - (now - last)
    If remaining < 0.0
        Return 0.0
    EndIf
    Return remaining
EndFunction

Function MarkBreastfeedingActionCooldown() Global
    String settingsFile = "/MMEAlerts/Settings"
    JsonUtil.SetFloatValue(settingsFile, "lastBreastfeedingActionRealTime", Utility.GetCurrentRealTime())
    JsonUtil.Save(settingsFile, False)
EndFunction

Function StartBreastfeedingMilkShare(Actor milkSource, Actor target, String semanticIntent = "speaker/source offers to target/drinker") Global
    ; Phase 1: validate action policy and both actor references before selecting
    ; a framework. The parameter contract is explicit source then drinker.
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingActionDiagnostic", 0) == 1
    Bool ostimDiagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    Bool skyrimNetOStimTrace = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetOStimTrace", 0) == 1
    Bool routeDiagnostic = diagnostic || ostimDiagnostic || skyrimNetOStimTrace
    Actor drinker = target
    String milkSourceName = MMEOStimBreastfeeding.GetActorName(milkSource)
    String drinkerName = MMEOStimBreastfeeding.GetActorName(drinker)
    MMELog.Diagnostic("[MMEAlert SkyrimNet BF] action received | semantic intent=" + semanticIntent + " | normalized milk source=" + milkSourceName + " " + milkSource + " | normalized drinker=" + drinkerName + " " + drinker)
    If routeDiagnostic
        Debug.Notification("Skyrim.Net BF: action received")
    EndIf
    If skyrimNetOStimTrace
        Debug.Notification("SN BF intent: " + semanticIntent)
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePairedMilkingAction", 1) != 1
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] rejected | MME Extensions or paired milking action disabled")
        If routeDiagnostic
            Debug.Notification("Skyrim.Net BF: rejected - action disabled")
        EndIf
        Return
    EndIf
    Float cooldownRemaining = GetBreastfeedingActionCooldownRemaining()
    If cooldownRemaining > 0.0
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] rejected | post-scene action cooldown active | remaining=" + (cooldownRemaining as Int) + "s")
        If routeDiagnostic
            Debug.Notification("Skyrim.Net BF: cooldown " + (cooldownRemaining as Int) + "s")
        EndIf
        Return
    EndIf
    If milkSource == None || drinker == None
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] rejected | milk source or drinker did not resolve")
        If routeDiagnostic
            Debug.Notification("Skyrim.Net BF: rejected - actor unresolved")
        EndIf
        Return
    EndIf
    If milkSource == drinker || milkSource.IsDead() || milkSource.IsDisabled() || !milkSource.Is3DLoaded() || drinker.IsDead() || drinker.IsDisabled() || !drinker.Is3DLoaded()
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] rejected | actors must be different, alive, enabled, and loaded")
        If routeDiagnostic
            Debug.Notification("Skyrim.Net BF: rejected - actors unavailable")
        EndIf
        Return
    EndIf
    If routeDiagnostic
        Debug.Notification("Skyrim.Net BF: source=" + milkSourceName + " | drinker=" + drinkerName)
    EndIf

    If skyrimNetOStimTrace
        Bool ostimDetected = MMEOStimBreastfeeding.IsOStimDetected()
        Bool ostimToggle = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) == 1
        Debug.Notification("SN OStim Trace: actors valid | detected=" + ostimDetected + " | toggle=" + ostimToggle)
    EndIf

    ; Phase 2: OStim is an independent complete backend when enabled. A rejected
    ; OStim request must not silently fall through to SexLab: that would violate
    ; user framework choice and could start a second, unexpected scene.
    ; One Skyrim.Net action, two internal backends. An enabled and available
    ; OStim route owns this request completely; a failed OStim start must not
    ; silently begin a SexLab scene instead.
    If MMEOStimBreastfeeding.IsBreastfeedingEnabled()
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] backend=OStim | calling persistent shared breastfeeding service | milk source=" + milkSourceName + " | drinker=" + drinkerName)
        If routeDiagnostic
            Debug.Notification("Skyrim.Net BF: backend=OStim")
        EndIf
        ; TopicInfo scripts are instantiated for dialogue fragments and cannot
        ; be used safely as an external API. Resolve the persistent quest script
        ; that now owns the same pipeline used by those dialogue fragments.
        Form ostimServiceForm = Game.GetFormFromFile(0x000800, "MMEAlert.esp")
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] OStim service raw form=" + ostimServiceForm)
        If skyrimNetOStimTrace
            Debug.Notification("SN OStim Trace: service form=" + ostimServiceForm)
        EndIf
        MMEDebug ostimService = ostimServiceForm as MMEDebug
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] OStim service script=" + ostimService)
        If skyrimNetOStimTrace
            Debug.Notification("SN OStim Trace: service script=" + ostimService)
        EndIf
        If ostimService == None
            MMEOStimBreastfeeding.Report(routeDiagnostic, "Skyrim.Net breastfeeding rejected: persistent OStim breastfeeding service could not resolve")
            Return
        EndIf
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] calling StartBreastfeeding")
        If skyrimNetOStimTrace
            Debug.Notification("SN OStim Trace: calling shared StartBreastfeeding")
        EndIf
        Bool ostimStarted = ostimService.StartBreastfeeding(milkSource, drinker, routeDiagnostic, "Skyrim.Net", semanticIntent)
        If ostimStarted
            MarkBreastfeedingActionCooldown()
        EndIf
        If routeDiagnostic
            If ostimStarted
                Debug.Notification("Skyrim.Net BF: OStim breastfeeding started")
            Else
                Debug.Notification("Skyrim.Net BF: OStim rejected request; see log")
            EndIf
        EndIf
        If skyrimNetOStimTrace
            Debug.Notification("SN OStim Trace: start result=" + ostimStarted + " | SexLab fallback blocked")
        EndIf
        MMELog.Diagnostic("[MMEAlert SkyrimNet BF] OStim StartBreastfeeding result=" + ostimStarted + " | milk source=" + milkSourceName + " | drinker=" + drinkerName + " | SexLab fallback=blocked")
        Return
    EndIf

    ; Phase 3: delegate to the persistent defensive SexLab transaction owner.
    MMELog.Diagnostic("[MMEAlert SkyrimNet BF] backend=SexLab | OStim breastfeeding integration not selected")
    If routeDiagnostic
        Debug.Notification("Skyrim.Net BF: backend=SexLab")
    EndIf
    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        MMELog.Alarm("[MMEAlert SkyrimNet BF] SexLab rejected | persistent service unavailable")
        Return
    EndIf
    Bool sexLabStarted = service.StartSexLabBreastfeeding(milkSource, drinker, "Skyrim.Net")
    If sexLabStarted
        MarkBreastfeedingActionCooldown()
    EndIf
    MMELog.Diagnostic("[MMEAlert SkyrimNet BF] defensive SexLab result=" + sexLabStarted + " | milk source=" + milkSourceName + " | drinker=" + drinkerName)
EndFunction
