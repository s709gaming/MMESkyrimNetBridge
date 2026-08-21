Scriptname MMEAnimationSafety Hidden

; Cooperative per-actor lock shared by every short MME Extensions animation.
; StorageUtil survives across script instances, so drink, fullness, and armor
; triggers cannot unknowingly start competing forced-animation sequences.
String Function GetOwner(Actor target) Global
    If target == None
        Return ""
    EndIf
    Return StorageUtil.GetStringValue(target, "MMEExtensions.ForcedAnimation.Owner", "")
EndFunction

Bool Function TryAcquire(Actor target, String owner) Global
    ; Read back the value after writing. StorageUtil is the shared authority and
    ; another Papyrus stack may have raced this request between the two calls.
    If target == None || owner == "" || GetOwner(target) != ""
        Return False
    EndIf
    StorageUtil.SetStringValue(target, "MMEExtensions.ForcedAnimation.Owner", owner)
    Return GetOwner(target) == owner
EndFunction

Bool Function Owns(Actor target, String owner) Global
    Return target != None && owner != "" && GetOwner(target) == owner
EndFunction

Function Release(Actor target, String owner) Global
    If Owns(target, owner)
        StorageUtil.UnsetStringValue(target, "MMEExtensions.ForcedAnimation.Owner")
    EndIf
EndFunction

; Returns a concise reason when a new free-arm animation must not take control.
String Function GetStartBlockReason(Actor target, MilkQUEST milkController, Bool requireFreeArms = True) Global
    ; Actor lifecycle and local ownership checks come first; these are cheap and
    ; prevent calls into optional frameworks for actors that cannot animate.
    If target == None
        Return "actor missing"
    EndIf
    If target.IsDead() || target.IsDisabled() || target.IsUnconscious() || !target.Is3DLoaded()
        Return "actor unavailable"
    EndIf
    If GetOwner(target) != ""
        Return "another MME Extensions animation owns actor"
    EndIf
    If target.IsInCombat()
        Return "in combat"
    EndIf
    If target.IsOnMount()
        Return "mounted"
    EndIf
    Int sitState = target.GetSitState()
    If sitState > 0 && sitState <= 3
        Return "sitting"
    EndIf
    ; External scene ownership always wins. MME, SexLab, OStim, and DD each have
    ; independent state, so none of these checks can safely stand in for another.
    If IsMMEMilking(target, milkController)
        Return "MME milking active"
    EndIf
    If milkController != None && milkController.SexLab != None && milkController.SexLab.IsActorActive(target)
        Return "SexLab scene active"
    EndIf
    If MMEOStimIntegration.IsActorInScene(target)
        Return "OStim scene active"
    EndIf
    If requireFreeArms && MMEAlertsController.IsFreeArmAnimationBlocked(target)
        Return "arms restrained by Devious Devices"
    EndIf
    Return ""
EndFunction

; An owned animation only resets the actor if no external system took over.
String Function GetResetBlockReason(Actor target, MilkQUEST milkController, String owner) Global
    ; Reset is intentionally stricter than a blind IdleForceDefaultState. If
    ; ownership changed or another gameplay system took control during the hold,
    ; sending a reset would break that newer animation/scene.
    If !Owns(target, owner)
        Return "animation ownership changed"
    EndIf
    If target.IsDead() || target.IsDisabled() || target.IsUnconscious() || !target.Is3DLoaded()
        Return "actor unavailable"
    EndIf
    If target.IsInCombat()
        Return "combat took control"
    EndIf
    If target.IsOnMount()
        Return "mount took control"
    EndIf
    Int sitState = target.GetSitState()
    If sitState > 0 && sitState <= 3
        Return "sit state took control"
    EndIf
    If IsMMEMilking(target, milkController)
        Return "MME milking took control"
    EndIf
    If milkController != None && milkController.SexLab != None && milkController.SexLab.IsActorActive(target)
        Return "SexLab took control"
    EndIf
    If MMEOStimIntegration.IsActorInScene(target)
        Return "OStim took control"
    EndIf
    Return ""
EndFunction

Bool Function IsMMEMilking(Actor target, MilkQUEST milkController) Global
    If target == None
        Return False
    EndIf
    If StorageUtil.GetIntValue(target, "MMEAlerts.IsMilking", 0) == 1
        Return True
    EndIf
    ; The controller marker covers observed events; the passive spell covers
    ; missed/early events and sessions that began outside MME Extensions.
    Return milkController != None && milkController.BeingMilkedPassive != None && target.HasSpell(milkController.BeingMilkedPassive)
EndFunction
