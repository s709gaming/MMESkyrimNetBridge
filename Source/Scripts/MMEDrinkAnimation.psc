Scriptname MMEDrinkAnimation Hidden

; Policy adapter only. The Player path uses its alias OnUpdate for completion;
; the NPC dialogue path can wait latently. Both use MMEMinorAnimations' vanilla
; drink idle, cooperative lock, and takeover-safe reset.

; Drink-specific adapter for the shared standing reaction executor.
Bool Function StartDrinkAnimation(Actor target, String enableKey, String durationKey, String roleLabel, String drinkLabel, Bool diagnostic, Bool wasEstablishedMilkmaid = True) Global
    String prefix = roleLabel + " (" + drinkLabel + ")"
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", enableKey, 0) != 1
        Report(diagnostic, prefix + " animation skipped: disabled")
        Return False
    EndIf
    If !wasEstablishedMilkmaid
        Report(diagnostic, prefix + " animation skipped: not an established Milk Maid before trigger")
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || !MMEArmorScript.IsMMEMilkMaid(target, milkController)
        Report(diagnostic, prefix + " animation skipped: not a live MME Milk Maid")
        Return False
    EndIf
    If MMEAlertsController.IsMilkmaidCreationPending(target)
        Report(diagnostic, prefix + " animation skipped: Milk Maid conversion owns actor")
        Return False
    EndIf
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0)
    Report(False, prefix + " vanilla drink requested (" + duration + " seconds)")
    Bool holdMovement = target != Game.GetPlayer()
    Return MMEMinorAnimations.StartDrink(target, "DrinkAnimation." + roleLabel, holdMovement, diagnostic)
EndFunction

; Latent finish path for the NPC dialogue pipeline: holds for the configured
; duration and then returns the actor to idle.
Function FinishDrinkAnimation(Actor target, Bool animationStarted, String durationKey, String roleLabel, Bool diagnostic) Global
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", durationKey, 3.0)
    MMEMinorAnimations.Finish(target, animationStarted, "DrinkAnimation." + roleLabel, duration, "Drink " + roleLabel, diagnostic)
EndFunction

; Non-latent reset for the player native path, called from OnUpdate.
Function ResetAnimation(Actor target, String roleLabel, Bool diagnostic) Global
    MMEMinorAnimations.Complete(target, "DrinkAnimation." + roleLabel, "Drink " + roleLabel, diagnostic)
EndFunction

Function Report(Bool showNotification, String reportText) Global
    MMELog.Diagnostic("[MMEAlert Drink Animation] " + reportText)
    If showNotification
        Debug.Notification("Milk Drink Animation: " + reportText)
    EndIf
EndFunction
