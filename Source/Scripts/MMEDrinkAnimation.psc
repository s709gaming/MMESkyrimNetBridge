Scriptname MMEDrinkAnimation Hidden

; Sends the shared milk-drink reaction animation when its toggle is enabled.
; Returns True when the animation event was sent to a valid actor.
Bool Function StartDrinkAnimation(Actor target, String enableKey, String durationKey, String roleLabel, String drinkLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    String prefix = roleLabel + " (" + drinkLabel + ")"
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", enableKey, 0) != 1
        Report(diagnostic, prefix + " animation skipped: disabled")
        Return False
    EndIf
    If target == None
        Report(diagnostic, prefix + " animation skipped: actor missing")
        Return False
    EndIf
    If !wasEstablishedMilkmaid
        Report(diagnostic, prefix + " animation skipped: not an established Milk Maid before drink")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkMaid.Find(target) == -1
        Report(diagnostic, prefix + " animation skipped: not an MME Milkmaid")
        Return False
    EndIf
    If target.IsDead() || target.IsDisabled() || !target.Is3DLoaded()
        Report(diagnostic, prefix + " animation skipped: actor unavailable")
        Return False
    EndIf
    If target.IsInCombat()
        Report(diagnostic, prefix + " animation skipped: in combat")
        Return False
    EndIf
    If target.IsOnMount()
        Report(diagnostic, prefix + " animation skipped: mounted")
        Return False
    EndIf
    Int sitState = target.GetSitState()
    If sitState > 0 && sitState <= 3
        Report(diagnostic, prefix + " animation skipped: sitting")
        Return False
    EndIf

    String animationEvent = PickStandingMilkingAnimation(diagnostic, prefix)
    If animationEvent == ""
        Return False
    EndIf
    Debug.SendAnimationEvent(target, animationEvent)
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0)
    Report(diagnostic, prefix + " animation started: " + animationEvent + " (" + duration + " seconds)")
    Return True
EndFunction

; Selects one random standing breast-fondling animation from MME's shared
; standing milking pool. Returns an empty string when the pool is unavailable.
String Function PickStandingMilkingAnimation(Bool diagnostic, String prefix) Global
    Int animationCount = JsonUtil.StringListCount("/MME/Strings", "standingmilkinganimations")
    If animationCount <= 0
        Report(diagnostic, prefix + " animation skipped: standing animation list missing")
        Return ""
    EndIf
    String animationEvent = JsonUtil.StringListGet("/MME/Strings", "standingmilkinganimations", Utility.RandomInt(0, animationCount - 1))
    If animationEvent == ""
        Report(diagnostic, prefix + " animation skipped: animation entry empty")
        Return ""
    EndIf
    Return animationEvent
EndFunction

; Latent finish path for the NPC dialogue pipeline: holds for the configured
; duration and then returns the actor to idle.
Function FinishDrinkAnimation(Actor target, Bool animationStarted, String durationKey, String roleLabel, Bool diagnostic) Global
    If !animationStarted
        Return
    EndIf
    Utility.Wait(JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0))
    ResetAnimation(target, roleLabel, diagnostic)
EndFunction

; Non-latent reset for the player native path, called from OnUpdate.
Function ResetAnimation(Actor target, String roleLabel, Bool diagnostic) Global
    If target != None && !target.IsDead() && target.Is3DLoaded()
        Debug.SendAnimationEvent(target, "IdleForceDefaultState")
        Report(diagnostic, roleLabel + " animation finished for " + GetActorName(target))
    Else
        Report(diagnostic, roleLabel + " animation ended while actor was unavailable")
    EndIf
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<no actor>"
    EndIf
    String result = target.GetDisplayName()
    If result == ""
        ActorBase baseInfo = target.GetLeveledActorBase()
        If baseInfo != None
            result = baseInfo.GetName()
        EndIf
    EndIf
    If result == ""
        result = "Unknown actor"
    EndIf
    Return result
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MMEAlert Drink Animation] " + reportText)
    If showNotification
        Debug.Notification("Milk Drink Animation: " + reportText)
    EndIf
EndFunction
