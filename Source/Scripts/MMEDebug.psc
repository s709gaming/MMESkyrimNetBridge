Scriptname MMEDebug extends Quest

String SettingsFile = "/MMEAlerts/Settings"

; Quest startup delegates timing to the shared controller scheduler.
Event OnInit()
    UpdateDebugLoop()
EndEvent

; Both scripts share one quest form, so only the controller may own update registration.
Function UpdateDebugLoop()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.UpdatePolling()
    EndIf
EndFunction

; Update events are delivered to every script on the quest; remain passive here.
Event OnUpdate()
EndEvent

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

; DRINK TRACKER DIAGNOSTICS (disabled).
; This old five-second status report was too noisy. Keep it at the bottom for
; future troubleshooting, but do not call it or expose it in the MCM.
;Function ShowDrinkTrackerDiagnostics()
;    Actor playerActor = Game.GetPlayer()
;    Spell monitorSpell = Game.GetFormFromFile(0x000805, "MMEAlert.esp") as Spell
;    MagicEffect monitorEffect = Game.GetFormFromFile(0x000804, "MMEAlert.esp") as MagicEffect
;    Form lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp")
;    FormList milkList = Game.GetFormFromFile(0x05C81C, "MilkModNEW.esp") as FormList
;    Bool ownsSpell = False
;    Bool effectActive = False
;    If monitorSpell != None
;        ownsSpell = playerActor.HasSpell(monitorSpell)
;    EndIf
;    If monitorEffect != None
;        effectActive = playerActor.HasMagicEffect(monitorEffect)
;    EndIf
;    String result = "spell=" + (monitorSpell != None) + "/owned=" + ownsSpell
;    result = result + " | effect=" + (monitorEffect != None) + "/active=" + effectActive
;    result = result + " | Lactacid=" + (lactacid != None) + " | milk list=" + (milkList != None)
;    Debug.Notification("MME Alerts DRINK DIAG - " + result)
;EndFunction
