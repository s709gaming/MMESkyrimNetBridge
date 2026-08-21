Scriptname MMEDrinkAnimation Hidden

; Drink-specific adapter for the shared standing reaction executor.
Bool Function StartDrinkAnimation(Actor target, String enableKey, String durationKey, String roleLabel, String drinkLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    String prefix = roleLabel + " (" + drinkLabel + ")"
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", enableKey, 0) != 1
        Report(diagnostic, prefix + " animation skipped: disabled")
        Return False
    EndIf
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0)
    Report(False, prefix + " requested (" + duration + " seconds)")
    Return MMEReactionAnimation.StartStanding(target, "DrinkAnimation." + roleLabel, "Drink " + prefix, diagnostic, wasEstablishedMilkmaid)
EndFunction

; Latent finish path for the NPC dialogue pipeline: holds for the configured
; duration and then returns the actor to idle.
Function FinishDrinkAnimation(Actor target, Bool animationStarted, String durationKey, String roleLabel, Bool diagnostic) Global
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0)
    MMEReactionAnimation.Finish(target, animationStarted, "DrinkAnimation." + roleLabel, duration, "Drink " + roleLabel, diagnostic)
EndFunction

; Non-latent reset for the player native path, called from OnUpdate.
Function ResetAnimation(Actor target, String roleLabel, Bool diagnostic) Global
    MMEReactionAnimation.Reset(target, "DrinkAnimation." + roleLabel, "Drink " + roleLabel, diagnostic)
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MMEAlert Drink Animation] " + reportText)
    If showNotification
        Debug.Notification("Milk Drink Animation: " + reportText)
    EndIf
EndFunction
