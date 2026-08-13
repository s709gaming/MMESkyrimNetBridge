Scriptname MMEDebug extends Quest

String SettingsFile = "/MMEAlerts/Settings"

Event OnInit()
    UpdateDebugLoop()
EndEvent

Function UpdateDebugLoop()
    UnregisterForUpdate()
    If JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1 || JsonUtil.GetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 1) == 1
        RegisterForSingleUpdate(5.0)
    EndIf
EndFunction

Event OnUpdate()
    If JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1
        MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If controller != None
            controller.ShowDebugCapacitySnapshot()
        Else
            Debug.Notification("MME Alerts DEBUG - capacity controller was not found.")
        EndIf
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 1) == 1
        ShowDrinkTrackerDiagnostics()
    EndIf
    UpdateDebugLoop()
EndEvent

Function ShowDrinkTrackerDiagnostics()
    Actor playerActor = Game.GetPlayer()
    Spell monitorSpell = Game.GetFormFromFile(0x000805, "MMEAlert.esp") as Spell
    MagicEffect monitorEffect = Game.GetFormFromFile(0x000804, "MMEAlert.esp") as MagicEffect
    Form lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp")
    FormList milkList = Game.GetFormFromFile(0x05C81C, "MilkModNEW.esp") as FormList
    Bool ownsSpell = False
    Bool effectActive = False
    If monitorSpell != None
        ownsSpell = playerActor.HasSpell(monitorSpell)
    EndIf
    If monitorEffect != None
        effectActive = playerActor.HasMagicEffect(monitorEffect)
    EndIf
    String result = "spell=" + (monitorSpell != None) + "/owned=" + ownsSpell
    result = result + " | effect=" + (monitorEffect != None) + "/active=" + effectActive
    result = result + " | Lactacid=" + (lactacid != None) + " | milk list=" + (milkList != None)
    Debug.Notification("MME Alerts DRINK DIAG - " + result)
EndFunction

; SOUND DEBUG (disabled). Retained at the end for future troubleshooting.
;Function TestReactionSound()
;    Sound testSound = Game.GetFormFromFile(0x000854, "MMEAlert.esp") as Sound
;    If testSound == None
;        Debug.Notification("MME Alerts SOUND TEST - marker 000854 lookup failed.")
;        Debug.Trace("[MMEAlert Sound Test] Game.GetFormFromFile returned None for MMEAlert.esp 000854")
;        Return
;    EndIf
;    Int instance = testSound.Play(Game.GetPlayer())
;    If instance <= 0
;        Debug.Notification("MME Alerts SOUND TEST - pool resolved, but Sound.Play failed: " + instance)
;        Debug.Trace("[MMEAlert Sound Test] pool resolved; Sound.Play returned " + instance)
;        Return
;    EndIf
;    Float volume = JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0)
;    Sound.SetInstanceVolume(instance, volume / 100.0)
;    Debug.Notification("MME Alerts SOUND TEST - playback started. Instance " + instance + ", volume " + volume + "%.")
;EndFunction
