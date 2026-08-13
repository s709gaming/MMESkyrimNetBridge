Scriptname MMEDebug extends Quest

String SettingsFile = "/MMEAlerts/Settings"

Event OnInit()
    UpdateDebugLoop()
EndEvent

Function UpdateDebugLoop()
    UnregisterForUpdate()
    If JsonUtil.GetIntValue(SettingsFile, "enableDebugSoundLoop", 0) == 1
        RegisterForSingleUpdate(5.0)
        Debug.Trace("[MMEAlert Debug] five-second notification loop enabled")
    EndIf
EndFunction

Function TestReactionSound()
    ; Papyrus plays a SOUN marker. 000854 links to the randomized Mild SNDR pool.
    Sound testSound = Game.GetFormFromFile(0x000854, "MMEAlert.esp") as Sound
    If testSound == None
        Debug.Notification("MME Alerts SOUND TEST - marker 000854 lookup failed.")
        Debug.Trace("[MMEAlert Sound Test] Game.GetFormFromFile returned None for MMEAlert.esp 000854")
        Return
    EndIf

    Int instance = testSound.Play(Game.GetPlayer())
    If instance <= 0
        Debug.Notification("MME Alerts SOUND TEST - pool resolved, but Sound.Play failed: " + instance)
        Debug.Trace("[MMEAlert Sound Test] pool resolved; Sound.Play returned " + instance)
        Return
    EndIf

    Float volume = JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0)
    Sound.SetInstanceVolume(instance, volume / 100.0)
    Debug.Notification("MME Alerts SOUND TEST - playback started. Instance " + instance + ", volume " + volume + "%.")
    Debug.Trace("[MMEAlert Sound Test] playback started; instance=" + instance + ", volume=" + volume)
EndFunction

Event OnUpdate()
    If JsonUtil.GetIntValue(SettingsFile, "enableDebugSoundLoop", 0) != 1
        Return
    EndIf

    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.ShowDebugCapacitySnapshot()
    Else
        Debug.Notification("MME Alerts DEBUG - capacity controller was not found.")
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableDebugSoundTest", 0) == 1
        TestReactionSound()
    EndIf
    Debug.Trace("[MMEAlert Debug] diagnostic notification fired")
    RegisterForSingleUpdate(5.0)
EndEvent
