Scriptname MMEArousalAnimations Hidden

; Three-second, sex-aware arousal animation facade. The threshold monitor and
; public API both enter here so safety, movement ownership, and diagnostics do
; not drift into separate implementations.

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

Float Function GetDuration() Global
    Return 3.0
EndFunction

Bool Function IsEnabled() Global
    Return MMEAlertsController.IsExtensionsEnabled() \
        && JsonUtil.GetIntValue(GetSettingsFile(), "enableArousalEffectAnimations", 1) == 1
EndFunction

; Latent. True means the registered behavior event was dispatched and the
; complete three-second owned hold finished. SendAnimationEvent has no result,
; so a missing behavior-generator run cannot be detected from Papyrus.
Bool Function TryPlay(Actor target, Int tier, String sourceLabel = "Internal") Global
    Bool started = TryStart(target, tier, sourceLabel)
    If !started
        Return False
    EndIf
    FinishStarted(target, tier, sourceLabel)
    Return True
EndFunction

; Non-latent start half used by the threshold monitor so its notification and
; sound can begin at the same moment as the animation. Public callers that want
; the complete owned three-second reaction should continue to use TryPlay.
Bool Function TryStart(Actor target, Int tier, String sourceLabel = "Internal") Global
    If !IsEnabled()
        MMELog.MasterDiagnostic("[MME Extensions Arousal Animation] skipped: feature disabled | source=" + sourceLabel)
        Return False
    EndIf
    If target == None
        AlarmOnce("MMEExtensions.ArousalAnimations.Alarm.MissingActor", "[MME Extensions Arousal Animation] FAILURE: request had no actor | source=" + sourceLabel)
        Return False
    EndIf
    If tier < 1 || tier > 3
        AlarmOnce("MMEExtensions.ArousalAnimations.Alarm.InvalidTier", "[MME Extensions Arousal Animation] FAILURE: invalid tier " + tier + " | actor=" + GetActorName(target) + " | source=" + sourceLabel)
        Return False
    EndIf

    ActorBase baseInfo = target.GetLeveledActorBase()
    Bool female = baseInfo == None || baseInfo.GetSex() != 0
    String animationEvent = GetAnimationEvent(tier, female)
    If animationEvent == ""
        AlarmOnce("MMEExtensions.ArousalAnimations.Alarm.Mapping", "[MME Extensions Arousal Animation] FAILURE: no event mapping | actor=" + GetActorName(target) + " | tier=" + tier)
        Return False
    EndIf

    String sexLabel = "male"
    If female
        sexLabel = "female"
    EndIf
    String owner = "ArousalAnimation." + sexLabel + "." + tier
    String requestLabel = "Arousal Animation " + sexLabel + " tier " + tier
    MMELog.MasterDiagnostic("[MME Extensions Arousal Animation] request | actor=" + GetActorName(target) + " | tier=" + tier + " | sex=" + sexLabel + " | event=" + animationEvent + " | source=" + sourceLabel)
    Bool started = MMEReactionAnimation.StartCustomEvent(target, owner, requestLabel, animationEvent, True, True)
    If !started
        MMELog.MasterDiagnostic("[MME Extensions Arousal Animation] rejected by shared animation safety | actor=" + GetActorName(target) + " | tier=" + tier + " | source=" + sourceLabel)
        Return False
    EndIf
    Return True
EndFunction

; Latent completion half matching TryStart.
Function FinishStarted(Actor target, Int tier, String sourceLabel = "Internal") Global
    ActorBase baseInfo = target.GetLeveledActorBase()
    Bool female = baseInfo == None || baseInfo.GetSex() != 0
    String sexLabel = "male"
    If female
        sexLabel = "female"
    EndIf
    String owner = "ArousalAnimation." + sexLabel + "." + tier
    String requestLabel = "Arousal Animation " + sexLabel + " tier " + tier
    MMEReactionAnimation.Finish(target, True, owner, GetDuration(), requestLabel, True)
    MMELog.MasterDiagnostic("[MME Extensions Arousal Animation] complete | actor=" + GetActorName(target) + " | tier=" + tier + " | duration=" + GetDuration() + " | source=" + sourceLabel)
EndFunction

String Function GetAnimationEvent(Int tier, Bool female) Global
    If female
        If tier == 1
            Return "MMEExt_Arousal_F_L1"
        ElseIf tier == 2
            Return "MMEExt_Arousal_F_L2"
        ElseIf tier == 3
            Return "MMEExt_Arousal_F_L3"
        EndIf
    Else
        If tier == 1
            Return "MMEExt_Arousal_M_L1"
        ElseIf tier == 2 || tier == 3
            ; The supplied male level-2 clip intentionally serves both tiers.
            Return "MMEExt_Arousal_M_L2"
        EndIf
    EndIf
    Return ""
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

Function AlarmOnce(String alarmKey, String alarmText) Global
    If StorageUtil.GetIntValue(None, alarmKey, 0) != 1
        StorageUtil.SetIntValue(None, alarmKey, 1)
        MMELog.Alarm(alarmText)
    EndIf
EndFunction
