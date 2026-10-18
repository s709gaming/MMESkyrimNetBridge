Scriptname MMEReactionAnimation Hidden

; Shared executor for short free-arm Standing and Kneeling reactions. Trigger-
; specific settings, notifications, and Skyrim.Net work stay with callers.
String Function GetPlayerMovementOwnerKey() Global
    Return "MMEExtensions.ReactionAnimation.PlayerMovementOwner"
EndFunction

String Function GetMovementActorListKey() Global
    Return "MMEExtensions.ReactionAnimation.MovementActors"
EndFunction

Bool Function Start(Actor target, String owner, String requestLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    Return StartStanding(target, owner, requestLabel, diagnostic, wasEstablishedMilkmaid)
EndFunction

Bool Function StartStanding(Actor target, String owner, String requestLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    Return StartSelected(target, owner, requestLabel, "Standing", "", diagnostic, wasEstablishedMilkmaid)
EndFunction

Bool Function StartKneeling(Actor target, String owner, String requestLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    Return StartSelected(target, owner, requestLabel, "Kneeling", "ZaZAPCHorFd", diagnostic, wasEstablishedMilkmaid)
EndFunction

; Presentation-only entry point for one-shot armor introductions. Unlike the
; ordinary reaction path, this deliberately does not require Milk Maid status;
; it retains the same lifecycle, scene, restraint, and cooperative-lock safety.
Bool Function StartPresentationKneeling(Actor target, String owner, String requestLabel, Bool diagnostic) Global
    If target == None
        Report(diagnostic, requestLabel, "rejected: actor missing")
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String blocked = MMEAnimationSafety.GetStartBlockReason(target, milkController, True)
    If blocked != ""
        Report(diagnostic, requestLabel, "rejected: " + blocked)
        Return False
    EndIf
    If !MMEAnimationSafety.TryAcquire(target, owner)
        Report(diagnostic, requestLabel, "rejected: ownership acquisition failed")
        Return False
    EndIf
    Debug.SendAnimationEvent(target, "ZaZAPCHorFd")
    ; Presentation kneeling must hold both players and NPCs. Without this,
    ; follower packages can translate an NPC across the floor while the knees-
    ; down animation remains active.
    LockMovement(target, owner, requestLabel)
    Report(False, requestLabel, "presentation Kneeling started: ZaZAPCHorFd on " + GetActorName(target))
    Return True
EndFunction

; General-purpose entry point for short, explicitly registered behavior events.
; Unlike StartSelected, this does not require Milk Maid status. The caller owns
; event selection and duration; this facade owns scene safety and movement.
Bool Function StartCustomEvent(Actor target, String owner, String requestLabel, String animationEvent, Bool holdMovement = True, Bool diagnostic = True) Global
    If target == None
        Report(diagnostic, requestLabel, "rejected: actor missing")
        Return False
    EndIf
    If animationEvent == ""
        Report(diagnostic, requestLabel, "rejected: animation event missing")
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String blocked = MMEAnimationSafety.GetStartBlockReason(target, milkController, True)
    If blocked != ""
        Report(diagnostic, requestLabel, "rejected: " + blocked)
        Return False
    EndIf
    If !MMEAnimationSafety.TryAcquire(target, owner)
        Report(diagnostic, requestLabel, "rejected: ownership acquisition failed")
        Return False
    EndIf
    Debug.SendAnimationEvent(target, animationEvent)
    If holdMovement
        LockMovement(target, owner, requestLabel)
    EndIf
    Report(False, requestLabel, "custom event started: " + animationEvent + " on " + GetActorName(target))
    Return True
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
    If !MMEArmorScript.IsMMEMilkMaid(target, milkController)
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
    LockPlayerMovement(target, owner, requestLabel)
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
    ; Release translation even when combat, a scene, or another system took
    ; animation control during the hold. The owner marker prevents this cleanup
    ; from unlocking a newer MME Extensions reaction.
    UnlockMovement(target, owner, requestLabel)
    MMEAnimationSafety.Release(target, owner)
EndFunction

Function LockPlayerMovement(Actor target, String owner, String requestLabel) Global
    If target == None || target != Game.GetPlayer() || owner == ""
        Return
    EndIf
    LockMovement(target, owner, requestLabel)
EndFunction

Function LockMovement(Actor target, String owner, String requestLabel) Global
    If target == None || owner == ""
        Return
    EndIf
    StorageUtil.SetStringValue(target, GetPlayerMovementOwnerKey(), owner)
    StorageUtil.FormListAdd(None, GetMovementActorListKey(), target, False)
    target.SetDontMove(True)
    Report(False, requestLabel, "movement locked for reaction hold | actor=" + GetActorName(target) + " | owner=" + owner)
EndFunction

Function UnlockPlayerMovement(Actor target, String owner, String requestLabel = "Reaction cleanup") Global
    If target == None || target != Game.GetPlayer() || owner == ""
        Return
    EndIf
    UnlockMovement(target, owner, requestLabel)
EndFunction

Function UnlockMovement(Actor target, String owner, String requestLabel = "Reaction cleanup") Global
    If target == None || owner == ""
        Return
    EndIf
    If StorageUtil.GetStringValue(target, GetPlayerMovementOwnerKey(), "") != owner
        Return
    EndIf
    StorageUtil.UnsetStringValue(target, GetPlayerMovementOwnerKey())
    StorageUtil.FormListRemove(None, GetMovementActorListKey(), target, True)
    target.SetDontMove(False)
    If target != Game.GetPlayer()
        target.EvaluatePackage()
    EndIf
    Report(False, requestLabel, "movement unlocked | actor=" + GetActorName(target) + " | owner=" + owner)
EndFunction

; Startup/load recovery for a save interrupted during the latent reaction hold.
; This runs before the extension master-toggle early return in the controller.
Function RestorePlayerMovementIfNeeded(Actor target, String reason = "controller recovery") Global
    ; Recover every actor held by an interrupted presentation. The target
    ; argument remains for backward-compatible player recovery from older saves.
    Int index = StorageUtil.FormListCount(None, GetMovementActorListKey()) - 1
    While index >= 0
        Actor heldActor = StorageUtil.FormListGet(None, GetMovementActorListKey(), index) as Actor
        If heldActor == None
            StorageUtil.FormListRemoveAt(None, GetMovementActorListKey(), index)
        Else
            String heldOwner = StorageUtil.GetStringValue(heldActor, GetPlayerMovementOwnerKey(), "")
            If heldOwner != ""
                StorageUtil.UnsetStringValue(heldActor, GetPlayerMovementOwnerKey())
                heldActor.SetDontMove(False)
                If heldActor != Game.GetPlayer()
                    heldActor.EvaluatePackage()
                EndIf
                MMEAnimationSafety.Release(heldActor, heldOwner)
                Report(False, "Reaction recovery", "emergency movement recovery | actor=" + GetActorName(heldActor) + " | reason=" + reason + " | owner=" + heldOwner)
            EndIf
            StorageUtil.FormListRemoveAt(None, GetMovementActorListKey(), index)
        EndIf
        index -= 1
    EndWhile

    If target != None
        String legacyOwner = StorageUtil.GetStringValue(target, GetPlayerMovementOwnerKey(), "")
        If legacyOwner != ""
            StorageUtil.UnsetStringValue(target, GetPlayerMovementOwnerKey())
            target.SetDontMove(False)
            MMEAnimationSafety.Release(target, legacyOwner)
            Report(False, "Reaction recovery", "legacy movement recovery | actor=" + GetActorName(target) + " | reason=" + reason + " | owner=" + legacyOwner)
        EndIf
    EndIf
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
    MMELog.Diagnostic("[MME Extensions Reaction Animation] [" + requestLabel + "] " + reportText)
    If showNotification
        Debug.Notification("Reaction Animation [" + requestLabel + "]: " + reportText)
    EndIf
EndFunction
