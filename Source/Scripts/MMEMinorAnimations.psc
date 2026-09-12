Scriptname MMEMinorAnimations Hidden

; Reusable executor for short vanilla gestures. Callers own trigger policy;
; this utility owns animation safety, cooperative locking, optional NPC
; movement restraint, playback, and takeover-safe cleanup.

Bool Function PlayGive(Actor target, Float duration = 3.0, Bool diagnostic = False) Global
    String owner = "MinorAnimation.Give"
    Bool started = StartGive(target, owner, True, diagnostic)
    Finish(target, started, owner, duration, "Give", diagnostic)
    Return started
EndFunction

Bool Function PlayDrink(Actor target, Float duration = 3.0, Bool holdMovement = False, Bool diagnostic = False) Global
    String owner = "MinorAnimation.Drink"
    Bool started = StartDrink(target, owner, holdMovement, diagnostic)
    Finish(target, started, owner, duration, "Drink", diagnostic)
    Return started
EndFunction

Bool Function StartGive(Actor target, String owner = "MinorAnimation.Give", Bool holdMovement = True, Bool diagnostic = False) Global
    Idle giveIdle = Game.GetFormFromFile(0x0B5E20, "Skyrim.esm") as Idle
    Return StartIdle(target, giveIdle, owner, holdMovement, "Give", "IdleGive 000B5E20", diagnostic)
EndFunction

Bool Function StartDrink(Actor target, String owner = "MinorAnimation.Drink", Bool holdMovement = False, Bool diagnostic = False) Global
    ; Vanilla IdleDrink. This is the same Skyrim record used by MME's installed
    ; RND integration, but is resolved directly so this utility has no RND
    ; dependency and remains usable by future callers.
    Idle drinkIdle = Game.GetFormFromFile(0x0FD68B, "Skyrim.esm") as Idle
    Return StartIdle(target, drinkIdle, owner, holdMovement, "Drink", "IdleDrink 000FD68B", diagnostic)
EndFunction

Bool Function StartIdle(Actor target, Idle animationIdle, String owner, Bool holdMovement, String label, String idleLabel, Bool diagnostic) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String blocked = MMEAnimationSafety.GetStartBlockReason(target, milkController, True)
    If blocked != ""
        Report(diagnostic, label + " rejected: " + blocked)
        Return False
    EndIf
    If animationIdle == None
        MMELog.Alarm("[MME Extensions Minor Animation] FAILURE: " + label + " vanilla idle could not be resolved")
        Report(diagnostic, label + " rejected: vanilla idle unavailable")
        Return False
    EndIf
    If owner == "" || !MMEAnimationSafety.TryAcquire(target, owner)
        Report(diagnostic, label + " rejected: ownership acquisition failed")
        Return False
    EndIf

    ; SetDontMove is intentionally NPC-only. Broad player control changes can
    ; overwrite another mod's control state and are not needed for these idles.
    If holdMovement && target != Game.GetPlayer()
        StorageUtil.SetStringValue(target, "MMEExtensions.MinorAnimation.MovementOwner", owner)
        target.SetDontMove(True)
    EndIf

    Bool accepted = target.PlayIdle(animationIdle)
    If !accepted
        ReleaseMovement(target, owner)
        MMEAnimationSafety.Release(target, owner)
        MMELog.Alarm("[MME Extensions Minor Animation] FAILURE: PlayIdle rejected " + idleLabel + " for " + GetActorName(target))
        Report(diagnostic, label + " rejected: PlayIdle did not accept " + idleLabel)
        Return False
    EndIf
    Report(False, label + " started: " + idleLabel + " on " + GetActorName(target))
    Return True
EndFunction

Function Finish(Actor target, Bool animationStarted, String owner, Float duration, String label, Bool diagnostic) Global
    If !animationStarted
        Return
    EndIf
    If duration < 0.0
        duration = 0.0
    EndIf
    Report(False, label + " holding for " + duration + " seconds")
    Utility.Wait(duration)
    Complete(target, owner, label, diagnostic)
EndFunction

Function Complete(Actor target, String owner, String label, Bool diagnostic) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String blocked = MMEAnimationSafety.GetResetBlockReason(target, milkController, owner)
    If blocked == ""
        Idle stopIdle = Game.GetFormFromFile(0x10D9EE, "Skyrim.esm") as Idle
        If stopIdle != None && target.PlayIdle(stopIdle)
            Report(False, label + " finished with IdleStop_Loose 0010D9EE")
        Else
            Debug.SendAnimationEvent(target, "IdleForceDefaultState")
            Report(False, label + " finished with default-state fallback")
        EndIf
    Else
        Report(diagnostic, label + " finished without forced reset: " + blocked)
    EndIf

    ; Movement and cooperative ownership are always released, even when an
    ; external scene took animation control during the hold.
    ReleaseMovement(target, owner)
    MMEAnimationSafety.Release(target, owner)
EndFunction

Function Cancel(Actor target, String owner, String label = "Minor animation", Bool diagnostic = False) Global
    If target == None
        Return
    EndIf
    If MMEAnimationSafety.Owns(target, owner)
        Complete(target, owner, label, diagnostic)
    Else
        ReleaseMovement(target, owner)
    EndIf
EndFunction

Function ReleaseMovement(Actor target, String owner) Global
    If target == None || owner == ""
        Return
    EndIf
    If StorageUtil.GetStringValue(target, "MMEExtensions.MinorAnimation.MovementOwner", "") != owner
        Return
    EndIf
    StorageUtil.UnsetStringValue(target, "MMEExtensions.MinorAnimation.MovementOwner")
    target.SetDontMove(False)
    If target != Game.GetPlayer()
        target.EvaluatePackage()
    EndIf
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

Function Report(Bool showNotification, String reportText) Global
    MMELog.Diagnostic("[MME Extensions Minor Animation] " + reportText)
    If showNotification
        Debug.Notification("Minor Animation: " + reportText)
    EndIf
EndFunction
