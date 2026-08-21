Scriptname MMEReactionAnimation Hidden

; Shared executor for short free-arm Standing and Kneeling reactions. Trigger-
; specific settings, notifications, and Skyrim.Net work stay with callers.
Bool Function Start(Actor target, String owner, String requestLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    Return StartStanding(target, owner, requestLabel, diagnostic, wasEstablishedMilkmaid)
EndFunction

Bool Function StartStanding(Actor target, String owner, String requestLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    Return StartSelected(target, owner, requestLabel, "Standing", "", diagnostic, wasEstablishedMilkmaid)
EndFunction

Bool Function StartKneeling(Actor target, String owner, String requestLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    Return StartSelected(target, owner, requestLabel, "Kneeling", "ZaZAPCHorFd", diagnostic, wasEstablishedMilkmaid)
EndFunction

Bool Function StartSelected(Actor target, String owner, String requestLabel, String animationKind, String animationEvent, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    If target == None
        Report(diagnostic, requestLabel, "rejected: actor missing")
        Return False
    EndIf
    If !wasEstablishedMilkmaid
        Report(diagnostic, requestLabel, "rejected: not an established Milk Maid before trigger")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, requestLabel, "rejected: MME controller unavailable")
        Return False
    EndIf
    If milkController.MilkMaid.Find(target) == -1
        Report(diagnostic, requestLabel, "rejected: not an MME Milk Maid")
        Return False
    EndIf
    If MMEAlertsController.IsMilkmaidCreationPending(target)
        Report(diagnostic, requestLabel, "rejected: Milk Maid conversion owns actor")
        Return False
    EndIf

    String blocked = MMEAnimationSafety.GetStartBlockReason(target, milkController, True)
    If blocked != ""
        Report(diagnostic, requestLabel, "rejected: " + blocked)
        Return False
    EndIf

    If animationKind == "Standing"
        animationEvent = PickStandingAnimation(requestLabel, diagnostic)
        If animationEvent == ""
            Return False
        EndIf
    EndIf
    If animationEvent == ""
        Report(diagnostic, requestLabel, "rejected: " + animationKind + " animation missing")
        Return False
    EndIf
    If !MMEAnimationSafety.TryAcquire(target, owner)
        Report(diagnostic, requestLabel, "rejected: ownership acquisition failed")
        Return False
    EndIf

    Debug.SendAnimationEvent(target, animationEvent)
    Report(False, requestLabel, animationKind + " started: " + animationEvent + " on " + GetActorName(target))
    Return True
EndFunction

; Latent completion path for callers that can wait in place.
Function Finish(Actor target, Bool animationStarted, String owner, Float duration, String requestLabel, Bool diagnostic) Global
    If !animationStarted
        Return
    EndIf
    If duration < 0.0
        duration = 0.0
    EndIf
    Report(False, requestLabel, "holding for " + duration + " seconds")
    Utility.Wait(duration)
    Reset(target, owner, requestLabel, diagnostic)
EndFunction

; Non-latent completion path used by the native player-drink listener's
; existing OnUpdate timer.
Function Reset(Actor target, String owner, String requestLabel, Bool diagnostic) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String blocked = MMEAnimationSafety.GetResetBlockReason(target, milkController, owner)
    If blocked == ""
        Debug.SendAnimationEvent(target, "IdleForceDefaultState")
        Report(False, requestLabel, "finished and reset " + GetActorName(target))
    Else
        Report(diagnostic, requestLabel, "finished without reset: " + blocked)
    EndIf
    MMEAnimationSafety.Release(target, owner)
EndFunction

String Function PickStandingAnimation(String requestLabel, Bool diagnostic) Global
    Int animationCount = JsonUtil.StringListCount("/MME/Strings", "standingmilkinganimations")
    If animationCount <= 0
        Report(diagnostic, requestLabel, "rejected: MME standing animation list missing")
        Return ""
    EndIf
    String animationEvent = JsonUtil.StringListGet("/MME/Strings", "standingmilkinganimations", Utility.RandomInt(0, animationCount - 1))
    If animationEvent == ""
        Report(diagnostic, requestLabel, "rejected: selected MME animation entry is empty")
        Return ""
    EndIf
    Return animationEvent
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<missing actor>"
    EndIf
    String actorName = target.GetDisplayName()
    If actorName == ""
        ActorBase baseInfo = target.GetLeveledActorBase()
        If baseInfo != None
            actorName = baseInfo.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

Function Report(Bool showNotification, String requestLabel, String reportText) Global
    Debug.Trace("[MME Extensions Reaction Animation] [" + requestLabel + "] " + reportText)
    If showNotification
        Debug.Notification("Reaction Animation [" + requestLabel + "]: " + reportText)
    EndIf
EndFunction
