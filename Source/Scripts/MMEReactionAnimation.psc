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
    ; Phase 1: validate trigger-time identity. A Lactacid drink can create a Milk
    ; Maid during the same event; the pre-trigger flag prevents that conversion
    ; sequence from being interrupted by an ordinary reaction animation.
    If target == None
        Report(diagnostic, requestLabel, "rejected: actor missing")
        Return False
    EndIf
    If !wasEstablishedMilkmaid
        Report(diagnostic, requestLabel, "rejected: not an established Milk Maid before trigger")
        Return False
    EndIf

    ; Phase 2: resolve live MME membership and conversion ownership. The arrays
    ; on MilkQUEST are authoritative; StorageUtil markers alone are not enough.
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

    ; Phase 3: reject actors already controlled by gameplay or another reaction.
    String blocked = MMEAnimationSafety.GetStartBlockReason(target, milkController, True)
    If blocked != ""
        Report(diagnostic, requestLabel, "rejected: " + blocked)
        Return False
    EndIf

    ; Phase 4: resolve the shared animation. Standing reactions intentionally
    ; reuse MME's configured standing-milking list; Kneeling uses the established
    ; ZaZ knees-on-floor event supplied by the caller.
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
    ; Acquire ownership only after every validation succeeds, minimizing stale
    ; locks. From this point the matching Finish/Reset path owns cleanup.
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
    ; The wait is deliberately owned by the initiating stack. Systems already
    ; using OnUpdate call Reset directly instead and must not add another timer.
    Report(False, requestLabel, "holding for " + duration + " seconds")
    Utility.Wait(duration)
    Reset(target, owner, requestLabel, diagnostic)
EndFunction

; Non-latent completion path used by the native player-drink listener's
; existing OnUpdate timer.
Function Reset(Actor target, String owner, String requestLabel, Bool diagnostic) Global
    ; Re-check external ownership after the hold. Only send the forced-default
    ; event when nothing else adopted the actor; always release our own lock.
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
    ; MME's JSON list is the single source of standing animations. Keeping the
    ; random selection here ensures drinks, capacity, and Milking Armor share
    ; exactly the same pool rather than drifting into duplicate implementations.
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
