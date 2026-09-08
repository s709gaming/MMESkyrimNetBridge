Scriptname MMEMilkDrinkEffects Hidden

; Shared drink-moans boundary. Resolve the ESP SOUN marker rather than individual
; WAVs so Skyrim selects from the configured Mild pool and returns one volume-
; controllable playback instance.

; Returns the sound instance, 0 when disabled, or -1 when playback fails.
Int Function PlayDrinkReaction(Actor drinker, Bool showDiagnostic = False) Global
    String settingsFile = "/MMEAlerts/Settings"
    If drinker == None
        Report(showDiagnostic, "sound failed: no drinker")
        Return -1
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableReactionSounds", 1) != 1 || JsonUtil.GetIntValue(settingsFile, "enableDrinkMoans", 1) != 1
        Report(showDiagnostic, "sound skipped: drink moans disabled")
        Return 0
    EndIf

    Sound reaction = MMEReactionSounds.Resolve(drinker, 0x000854)
    If reaction == None
        Report(showDiagnostic, "sound failed: sex-specific mild marker missing")
        Return -1
    EndIf
    Int instance = reaction.Play(drinker)
    If instance <= 0
        Report(showDiagnostic, "sound failed: Play returned " + instance)
        Return -1
    EndIf
    Float volume = JsonUtil.GetFloatValue(settingsFile, "reactionSoundVolume", 100.0)
    Sound.SetInstanceVolume(instance, volume / 100.0)
    MMELog.Diagnostic("[MMEAlert Drink] reaction sound " + instance + " played on " + drinker)
    Return instance
EndFunction

Function Report(Bool showNotification, String reportText) Global
    MMELog.Diagnostic("[MMEAlert Drink] " + reportText)
    If showNotification
        Debug.Notification("Milk Debug: " + reportText)
    EndIf
EndFunction
