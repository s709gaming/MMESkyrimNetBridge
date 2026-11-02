Scriptname MMEPostMilking Hidden

; One-shot completion/history boundary. MME remains the owner of milk/gameplay.
Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Post Milking] " + detail)
EndFunction

Function AlarmOnce(Actor target, String operation, String reason) Global
    String alarmKey = "MME.After.Alarm." + operation
    Float now = Utility.GetCurrentRealTime()
    Float previous = StorageUtil.GetFloatValue(target, alarmKey, -300.0)
    If now < previous || now - previous >= 60.0
        StorageUtil.SetFloatValue(target, alarmKey, now)
        MMELog.Alarm("[MME Post Milking] failure | operation=" + operation + " | actor=" + target + " | reason=" + reason)
    EndIf
EndFunction

Function EnsureDefaults() Global
    String settings = "/MMEAlerts/Settings"
    Bool changed = False
    If !JsonUtil.HasIntValue(settings, "enablePostMilkingNarration")
        JsonUtil.SetIntValue(settings, "enablePostMilkingNarration", 1)
        changed = True
    EndIf
    If !JsonUtil.HasFloatValue(settings, "postMilkingNarrationCooldown")
        JsonUtil.SetFloatValue(settings, "postMilkingNarrationCooldown", 120.0)
        changed = True
    EndIf
    If !JsonUtil.HasIntValue(settings, "postMilkingNarrationChance")
        JsonUtil.SetIntValue(settings, "postMilkingNarrationChance", 100)
        changed = True
    EndIf
    If !JsonUtil.HasIntValue(settings, "milkFullNarrationChance")
        JsonUtil.SetIntValue(settings, "milkFullNarrationChance", 100)
        changed = True
    EndIf
    If !JsonUtil.HasIntValue(settings, "enableSkyrimNetFullEvents")
        JsonUtil.SetIntValue(settings, "enableSkyrimNetFullEvents", 1)
        changed = True
    EndIf
    ; Existing full narration cooldowns are intentionally preserved.
    If changed
        JsonUtil.Save(settings, False)
        Trace("defaults | missing settings initialized; existing choices preserved")
    EndIf
EndFunction

String Function IntegrationBlock(Actor target) Global
    If !MMEAlertsSkyrimNet.IsExtensionsEnabled()
        Return "Extensions disabled"
    EndIf
    If target == None || target.IsDeleted() || target.IsChild() || target.IsDead() || target.IsDisabled()
        Return "affected actor unavailable"
    EndIf
    If !MMEAlertsSkyrimNet.IsAvailable() || SKSE.GetPluginVersion("SkyrimNet") < 0 || JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        Return "Skyrim.Net absent or disabled"
    EndIf
    Return ""
EndFunction

String Function NarrationBlock(Actor target) Global
    String reason = IntegrationBlock(target)
    If reason != ""
        Return reason
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePostMilkingNarration", 1) != 1
        Return "narration disabled"
    EndIf
    If !target.Is3DLoaded() || target.IsInCombat() || target.GetCurrentScene() != None || MMEOStimIntegration.IsActorBusy(target)
        Return "actor unloaded, in combat, or in a scene"
    EndIf
    If MMEAnimationSafety.GetOwner(target) != "" || StorageUtil.GetIntValue(target, "MME.Source.Active", 0) > 0 || StorageUtil.GetIntValue(target, "MME.MilkMaid.IsAnimating", 0) != 0
        Return "actor animation or milking busy"
    EndIf
    Return ""
EndFunction

String Function RouteForMethod(Int method) Global
    If method == 1
        Return "complete_hands"
    ElseIf method == 2
        Return "complete_pump"
    ElseIf method == 3
        Return "complete_equipment"
    ElseIf method == 4
        Return "complete_tendrils"
    ElseIf method == 5
        Return "complete_dwemer"
    EndIf
    Return "complete_generic"
EndFunction

; Called with immutable completion values after MME cleanup and token publication.
Function RecordCompletion(Actor target, Int sessionId, Int method, Float afterMilk, Float netRemoved, Int extracted) Global
    Trace("entry | actor=" + target + " | session=" + sessionId + " | method=" + method + " | after=" + afterMilk + " | net removed=" + netRemoved + " | extraction=" + extracted)
    If target == None || sessionId <= 0 || afterMilk < 0.0 || afterMilk != afterMilk || netRemoved != netRemoved
        AlarmOnce(target, "record completion", "invalid actor, token or milk snapshot")
        Return
    EndIf
    If StorageUtil.GetIntValue(target, "MME.After.Session", 0) == sessionId
        Trace("skip | actor=" + target + " | duplicate completion=" + sessionId)
        Return
    EndIf
    ; Token first prevents a duplicate publisher from retrying or rolling again.
    StorageUtil.SetIntValue(target, "MME.After.Session", sessionId)
    StorageUtil.SetFloatValue(target, "MME.After.RecordedReal", Utility.GetCurrentRealTime())
    StorageUtil.SetIntValue(target, "MME.After.Generation", MMEExtensionsNative.GetMovementSlapSession())
    StorageUtil.UnsetStringValue(target, "MME.After.Content")
    If extracted != 1
        Trace("skip | actor=" + target + " | no proven extraction; no success event")
        Return
    EndIf
    String actorName = MMEAlertsSkyrimNet.ResolveActorName(target, "The Milk Maid")
    String resultKey = "result_remaining"
    If afterMilk == 0.0
        resultKey = "result_empty"
    EndIf
    String resultText = MMENarrationText.GetRaw("Milking", resultKey)
    String content = MMENarrationText.Text("Milking", RouteForMethod(method), "actor", actorName, "result", resultText)
    ; Extraction can coincide with production: do not claim relief without reduction.
    If netRemoved <= 0.0
        content = MMENarrationText.Text("Milking", "complete_productive", "actor", actorName, "method", MMEMilkingSource.MethodName(method))
    EndIf
    If MMENarrationText.IsBlank(content)
        AlarmOnce(target, "record completion", "empty completion text after default resolution")
        Return
    EndIf
    StorageUtil.SetStringValue(target, "MME.After.Content", content)
    String reason = IntegrationBlock(target)
    If reason != "" || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkingEvents", 1) != 1
        Trace("history skip | actor=" + target + " | reason=" + reason + " | tracking=" + JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkingEvents", 1))
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterPersistentEvent(content, target, None)
    Trace("history result | actor=" + target + " | session=" + sessionId + " | result=" + result)
    If result != 0
        AlarmOnce(target, "completion history", "RegisterPersistentEvent rejected result=" + result)
    EndIf
EndFunction

; Full crossings call this independently of speech selection/cooldown/chance.
Function RecordFull(Actor target) Global
    String reason = IntegrationBlock(target)
    If reason != "" || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetFullEvents", 1) != 1
        Trace("full history skip | actor=" + target + " | reason=" + reason)
        Return
    EndIf
    String content = MMENarrationText.Text("Fullness", "full_event", "actor", MMEAlertsSkyrimNet.ResolveActorName(target, "The Milk Maid"))
    Int result = SkyrimNetApi.RegisterPersistentEvent(content, target, None)
    Trace("full history result | actor=" + target + " | result=" + result)
    If result != 0
        AlarmOnce(target, "full history", "RegisterPersistentEvent rejected result=" + result)
    EndIf
EndFunction

; Generic sessions arrive via MME_MilkingDone. Dwemer calls after its own cleanup.
Function NarrateLast(Actor target) Global
    If target == None
        Return
    EndIf
    Int sessionId = StorageUtil.GetIntValue(target, "MME.Source.LastSession", 0)
    If sessionId <= 0 || sessionId != StorageUtil.GetIntValue(target, "MME.After.Session", 0) || sessionId == StorageUtil.GetIntValue(target, "MME.After.Attempted", 0)
        Trace("narration skip | actor=" + target + " | unmatched, missing, or already consumed completion=" + sessionId)
        Return
    EndIf
    StorageUtil.SetIntValue(target, "MME.After.Attempted", sessionId)
    Float recorded = StorageUtil.GetFloatValue(target, "MME.After.RecordedReal", -1.0)
    Float age = Utility.GetCurrentRealTime() - recorded
    If age < 0.0 || age > 120.0 || StorageUtil.GetIntValue(target, "MME.After.Generation", -1) != MMEExtensionsNative.GetMovementSlapSession()
        Trace("narration skip | actor=" + target + " | stale completion or different load")
        Return
    EndIf
    String reason = NarrationBlock(target)
    String content = StorageUtil.GetStringValue(target, "MME.After.Content", "")
    If reason != "" || MMENarrationText.IsBlank(content)
        Trace("narration skip | actor=" + target + " | reason=" + reason + " | no successful extraction=" + MMENarrationText.IsBlank(content))
        Return
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float last = StorageUtil.GetFloatValue(target, "MME.After.LastNarration", -1.0)
    Float cooldown = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "postMilkingNarrationCooldown", 120.0)
    If last >= 0.0 && last <= now && now - last < cooldown
        Trace("narration skip | actor=" + target + " | cooldown")
        Return
    EndIf
    Int chance = JsonUtil.GetIntValue("/MMEAlerts/Settings", "postMilkingNarrationChance", 100)
    If chance <= 0 || (chance < 100 && Utility.RandomInt(1, 100) > chance)
        Trace("narration skip | actor=" + target + " | chance=" + chance)
        Return
    EndIf
    String actorName = MMEAlertsSkyrimNet.ResolveActorName(target, "The Milk Maid")
    content += " " + MMENarrationText.Text("Milking", "completion_instruction", "actor", actorName)
    Int result = -1
    If target == Game.GetPlayer()
        Float pendingAt = StorageUtil.GetFloatValue(target, "MME.After.PendingAt", -1.0)
        Bool sameGeneration = StorageUtil.GetIntValue(target, "MME.After.PendingGeneration", -1) == MMEExtensionsNative.GetMovementSlapSession()
        If StorageUtil.GetIntValue(target, "MME.After.PendingPlayer", 0) != 0 && sameGeneration && now >= pendingAt && now - pendingAt < 120.0
            Trace("narration skip | actor=" + target + " | previous player request pending")
            Return
        EndIf
        MMEAlertsController bridge = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If bridge == None
            AlarmOnce(target, "player narration", "required callback controller missing")
            Return
        EndIf
        ; Correlate asynchronous replies across new sessions and save loads.
        ; The marker is stripped before TTS; an unmarked reply is never spoken.
        String marker = "[[MME:" + MMEExtensionsNative.GetMovementSlapSession() + ":" + sessionId + "]]"
        String instructions = MMENarrationText.Text("Common", "player_instructions", "actor", actorName) + " Begin your response with exactly " + marker + " followed by your dialogue. This routing marker is removed before speech."
        String contextJson = "{\"playerInstructions\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(instructions) + "\",\"speaker\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(actorName) + "\",\"situation\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(content) + "\",\"milkKnowledge\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(MMEDialogueKnowledge.ForRequest(target, "post milking player")) + "\"}"
        StorageUtil.SetIntValue(target, "MME.After.PendingPlayer", sessionId)
        StorageUtil.SetStringValue(target, "MME.After.PendingMarker", marker)
        StorageUtil.SetFloatValue(target, "MME.After.PendingAt", now)
        StorageUtil.SetIntValue(target, "MME.After.PendingGeneration", MMEExtensionsNative.GetMovementSlapSession())
        result = SkyrimNetApi.SendCustomPromptToLLM("mme_wearer_self_comment", "dialogue", contextJson, bridge, "MMEAlertsController", "OnPostMilkingPlayerLine")
        If result != 1
            StorageUtil.UnsetIntValue(target, "MME.After.PendingPlayer")
        EndIf
        ; Normalize to the DirectNarration acceptance convention below.
        result = 1 - result
    Else
        content = MMEDialogueKnowledge.Append(content, target)
        result = SkyrimNetApi.DirectNarration(content, target, Game.GetPlayer())
    EndIf
    Trace("narration result | actor=" + target + " | session=" + sessionId + " | result=" + result + " (0=accepted)")
    If result == 0
        StorageUtil.SetFloatValue(target, "MME.After.LastNarration", now)
    Else
        AlarmOnce(target, "narration request", "request rejected result=" + result)
    EndIf
EndFunction

Function PlayPlayerLine(String response, Int success) Global
    Actor target = Game.GetPlayer()
    Int pending = StorageUtil.GetIntValue(target, "MME.After.PendingPlayer", 0)
    String marker = StorageUtil.GetStringValue(target, "MME.After.PendingMarker", "")
    If success != 1 && pending > 0 && NarrationBlock(target) == ""
        AlarmOnce(target, "player generation", "custom prompt failed result=" + success)
    EndIf
    If success != 1 || marker == "" || StringUtil.Find(response, marker) != 0
        Trace("player cleanup | uncorrelated, failed or unmarked reply suppressed; pending expires after 120 seconds")
        Return
    EndIf
    StorageUtil.UnsetIntValue(target, "MME.After.PendingPlayer")
    StorageUtil.UnsetStringValue(target, "MME.After.PendingMarker")
    response = StringUtil.Substring(response, StringUtil.GetLength(marker))
    String reason = NarrationBlock(target)
    If reason == "" && pending > 0 && MMENarrationText.IsBlank(response)
        AlarmOnce(target, "player generation", "matched response contained no dialogue")
    EndIf
    Float age = Utility.GetCurrentRealTime() - StorageUtil.GetFloatValue(target, "MME.After.PendingAt", -1.0)
    If pending <= 0 || pending != StorageUtil.GetIntValue(target, "MME.Source.LastSession", 0) || reason != "" || MMENarrationText.IsBlank(response) || age < 0.0 || age > 120.0 || StorageUtil.GetIntValue(target, "MME.After.PendingGeneration", -1) != MMEExtensionsNative.GetMovementSlapSession()
        Trace("player cleanup | session=" + pending + " | reason=" + reason + " | result=" + success + " | stale/blank response suppressed; no NPC fallback")
        Return
    EndIf
    Int result = SkyrimNetApi.TriggerPlayerTTS(response)
    Trace("player playback | actor=" + target + " | session=" + pending + " | result=" + result)
    If result != 0
        AlarmOnce(target, "player playback", "TTS rejected result=" + result)
    EndIf
EndFunction
