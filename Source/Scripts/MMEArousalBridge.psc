Scriptname MMEArousalBridge Hidden

; Optional SexLab Aroused boundary. Validate known legacy prerequisites before
; calling third-party code; never repair or populate another framework's properties.

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

; SexLab Aroused Redux and OSLAroused both expose this compatibility master.
Bool Function IsAvailable() Global
    Return Game.IsPluginInstalled("SexLabAroused.esm")
EndFunction

; Legacy Redux puts its faction-based API on the slaUtilScr parent. Modern
; OSL/NG compatibility quests extend Quest directly and use native-backed reads.
; Failure backoff is session-scoped; existing callers drive retries (no new timer).
Bool Function IsReady(Actor actorRef = None) Global
    If !IsAvailable()
        Return False
    EndIf
    String healthKey = "MMEExtensions.ArousalBridge.Health"
    Int session = MMEExtensionsNative.GetMovementSlapSession()
    If StorageUtil.GetIntValue(None, healthKey + ".Session", -1) != session
        StorageUtil.SetIntValue(None, healthKey + ".Session", session)
        StorageUtil.SetIntValue(None, healthKey, 0)
        StorageUtil.UnsetFloatValue(None, healthKey + ".Retry")
        StorageUtil.UnsetFloatValue(None, healthKey + ".FailedAt")
        StorageUtil.UnsetIntValue(None, healthKey + ".Alarm")
    EndIf
    Float now = Utility.GetCurrentRealTime()
    If now < StorageUtil.GetFloatValue(None, healthKey + ".Retry", -1.0)
        Return False
    EndIf
    slaFrameworkScr framework = Game.GetFormFromFile(0x04290F, "SexLabAroused.esm") as slaFrameworkScr
    String reason = ""
    If framework == None
        reason = "compatibility quest/script unavailable"
    Else
        ; Native metadata avoids selecting OSL's separate utility script sibling.
        Int frameworkKind = MMEExtensionsNative.GetArousalFrameworkKind(framework as Quest)
        If frameworkKind < 0
            reason = "compatibility script hierarchy unavailable or ambiguous"
        ElseIf frameworkKind == 1
            slaUtilScr legacy = (framework as Quest) as slaUtilScr
            If legacy == None
                reason = "legacy API parent could not resolve"
            ElseIf legacy.slaArousalBlocked == None
                reason = "legacy slaArousalBlocked property is None"
            ElseIf legacy.slaArousal == None || legacy.slaExposure == None
                reason = "legacy arousal/exposure faction property is None"
            EndIf
        EndIf
    EndIf
    If reason != ""
        If StorageUtil.GetIntValue(None, healthKey, 0) != -1
            StorageUtil.SetFloatValue(None, healthKey + ".FailedAt", now)
            MMELog.MasterDiagnostic("[MME Arousal Bridge] suspended | actor=" + actorRef + " | reason=" + reason)
        EndIf
        StorageUtil.SetIntValue(None, healthKey, -1)
        StorageUtil.SetFloatValue(None, healthKey + ".Retry", now + 5.0)
        ; Give startup initialization a grace period before raising a genuine alarm.
        If now - StorageUtil.GetFloatValue(None, healthKey + ".FailedAt", now) >= 30.0 && StorageUtil.GetIntValue(None, healthKey + ".Alarm", 0) == 0
            StorageUtil.SetIntValue(None, healthKey + ".Alarm", 1)
            MMELog.Alarm("[MME Arousal Bridge] unavailable | operation=read/write | actor=" + actorRef + " | reason=" + reason + ", calls suspended, retrying prerequisites")
        EndIf
        Return False
    EndIf
    If StorageUtil.GetIntValue(None, healthKey, 0) != 1
        MMELog.MasterDiagnostic("[MME Arousal Bridge] ready | actor=" + actorRef + " | previous state=" + StorageUtil.GetIntValue(None, healthKey, 0))
        StorageUtil.SetIntValue(None, healthKey, 1)
        StorageUtil.UnsetFloatValue(None, healthKey + ".Retry")
        StorageUtil.UnsetIntValue(None, healthKey + ".Alarm")
    EndIf
    Return True
EndFunction

; Player drink wrapper around the checked compatibility API.
Function ApplyMilkDrinkArousal(Actor drinker, Form drinkItem) Global
    String settingsFile = GetSettingsFile()
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableArousalDiagnostic", 0) == 1
    If drinker == None || drinker != Game.GetPlayer()
        Report(diagnostic, "skipped: drinker is not the player")
        Return
    EndIf
    ApplyMilkDrinkArousalForActor(drinker, drinkItem, diagnostic)
EndFunction

; Drink-facing compatibility wrapper. The neutral implementation below lets
; non-drink systems reuse the same MCM amount, cap, and checked SLA API
; without writing false drink wording to the Papyrus log.
Bool Function ApplyMilkDrinkArousalForActor(Actor drinker, Form drinkItem, Bool showDiagnostic = False) Global
    String itemName = "<unnamed milk>"
    If drinkItem != None && drinkItem.GetName() != ""
        itemName = drinkItem.GetName()
    EndIf
    Int arousalBefore = GetCurrentArousal(drinker)
    Float configuredAmount = JsonUtil.GetFloatValue(GetSettingsFile(), "milkDrinkArousal", 10.0)
    Bool sent = ApplyConfiguredMilkArousalForActor(drinker, "drank " + itemName, showDiagnostic)
    RecordMilkDrinkResult(drinker, arousalBefore, configuredAmount, sent)
    Return sent
EndFunction

; Shared completion boundary for the configured Milk Maid route and the
; sex-specific ordinary-adult milk route. Retain the existing bounded requested
; result when the framework read has not caught up yet.
Function RecordMilkDrinkResult(Actor target, Int arousalBefore, Float requestedAmount, Bool sent) Global
    If target == None || !sent
        Return
    EndIf
    Int arousalAfter = GetCurrentArousal(target)
    If arousalBefore >= 0 && arousalAfter <= arousalBefore
        Float boundedAmount = requestedAmount
        If boundedAmount < 0.0
            boundedAmount = 0.0
        ElseIf boundedAmount > 100.0
            boundedAmount = 100.0
        EndIf
        arousalAfter = (arousalBefore as Float + boundedAmount) as Int
        If arousalAfter > 100
            arousalAfter = 100
        EndIf
    EndIf
    MMEArousalEffects.RecordMilkDrinkCrossing(target, arousalBefore, arousalAfter)
EndFunction

; Actor-safe implementation shared by milk drinking and armor injections.
Bool Function ApplyConfiguredMilkArousalForActor(Actor target, String sourceLabel, Bool showDiagnostic = False) Global
    ; Phase 1: enforce master/feature/dependency/actor gates before resolving the
    ; configured amount. A missing optional framework is a clean no-op.
    String settingsFile = GetSettingsFile()
    String actorName = GetActorName(target)
    If target == None
        Report(showDiagnostic, "skipped: actor not found | source=" + sourceLabel)
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

    Float configuredAmount = JsonUtil.GetFloatValue(settingsFile, "milkDrinkArousal", 10.0)
    Return ApplyArousalAmountForActor(target, configuredAmount, sourceLabel, showDiagnostic)
EndFunction

; Optional-arousal boundary for non-Milkmaids. Callers choose the sex-specific
; amount, while this function preserves the same dependency, cap, and event contract.
Bool Function ApplyArousalAmountForActor(Actor target, Float configuredAmount, String sourceLabel, Bool showDiagnostic = False) Global
    String actorName = GetActorName(target)
    If target == None
        Report(showDiagnostic, "skipped: actor not found | source=" + sourceLabel)
        Return False
    EndIf
    If !IsAvailable()
        Report(showDiagnostic, "skipped: SexLabAroused.esm not detected")
        Return False
    EndIf
    If configuredAmount < 0.0
        configuredAmount = 0.0
    ElseIf configuredAmount > 100.0
        configuredAmount = 100.0
    EndIf
    If !IsReady(target)
        Return False
    EndIf
    Int arousalBefore = GetCurrentArousal(target)
    Float amountToSend = configuredAmount
    If arousalBefore >= 0 && arousalBefore as Float + amountToSend > 100.0
        amountToSend = 100.0 - arousalBefore as Float
    EndIf
    Report(showDiagnostic, actorName + " " + sourceLabel + "; arousal " + arousalBefore + ", sending +" + amountToSend)

    If amountToSend <= 0.0
        If arousalBefore >= 100
            Report(showDiagnostic, actorName + " arousal remains capped at 100")
        Else
            Report(showDiagnostic, "no event sent: configured arousal is 0")
        EndIf
        Return False
    EndIf
    ; Prefer the compatibility quest's direct API. OSL 2.9.3 can accumulate
    ; duplicate slaUpdateExposure registrations after repeated load callbacks,
    ; causing one event to apply twice. SLA/OSL expose this legacy method.
    slaFrameworkScr framework = Game.GetFormFromFile(0x04290F, "SexLabAroused.esm") as slaFrameworkScr
    If framework != None
        Int directResult = framework.UpdateActorExposure(target, amountToSend as Int)
        If showDiagnostic
            Int arousalAfterDirect = GetCurrentArousal(target)
            Report(True, "direct UpdateActorExposure result=" + directResult + ": " + actorName + " " + arousalBefore + " -> " + arousalAfterDirect + " | source=" + sourceLabel)
        Else
            Report(False, "direct UpdateActorExposure sent for " + actorName + " (+" + amountToSend + ") | source=" + sourceLabel)
        EndIf
        Return True
    EndIf

    ; Readiness may change between validation and dispatch. Do not send an
    ; asynchronous event into an unavailable or incomplete framework.
    Return False
EndFunction

; Prefer the framework's authoritative read after known prerequisites are ready.
Int Function GetCurrentArousal(Actor actorRef) Global
    If actorRef == None || !IsReady(actorRef)
        Return -1
    EndIf
    ; Every supported SLA/OSL fork implements this legacy compatibility quest.
    ; OSL forwards it to its native state, while SLA Redux/NG return their own
    ; authoritative value. Prefer it over a faction rank that may be stale or
    ; absent for NPCs in native-backed implementations.
    slaFrameworkScr framework = Game.GetFormFromFile(0x04290F, "SexLabAroused.esm") as slaFrameworkScr
    If framework != None
        Int frameworkResult = framework.GetActorArousal(actorRef)
        If frameworkResult >= 0
            If frameworkResult > 100
                Return 100
            EndIf
            Return frameworkResult
        EndIf
    EndIf
    ; Retain the original faction read as a compatibility fallback for an older
    ; installation whose framework quest cannot be resolved.
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
    MMELog.Diagnostic("[MMEAlert Arousal] " + reportText)
    If showNotification
        Debug.Notification(MMELocalization.Text("Arousal Debug: ") + reportText)
    EndIf
EndFunction
