Scriptname MMEAlertsPlayerEffect extends ActiveMagicEffect

; Permanent Player ability host. It owns no polling itself; lifecycle callbacks
; reinitialize the controller and optional installer profiles after save load.

; Forwards lifecycle changes to the quest controller; the ESP form ID is fixed.
Function Refresh(String reason)
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshCapacity(reason)
    EndIf
EndFunction

; Starts monitoring when the permanent player ability becomes active.
Event OnEffectStart(Actor target, Actor caster)
    If target == Game.GetPlayer()
        MMEAlertsQuickTest quickTest = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsQuickTest
        If quickTest != None
            quickTest.ScheduleTestSetup()
        EndIf
        Refresh("monitor start")
    EndIf
EndEvent

; Reinitializes registrations and development helpers after loading a save.
Event OnPlayerLoadGame()
    ; Ordering is intentional: apply one-time MME defaults first, rebuild runtime
    ; registrations/schedules second, then arm the optional delayed QuickStart.
    MMEAlertsFlatRateDefaults flatDefaults = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsFlatRateDefaults
    If flatDefaults != None
        flatDefaults.ApplyDefaults()
    EndIf
    MMEDebug breastfeedingService = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If breastfeedingService != None
        breastfeedingService.RecoverAfterLoad()
    EndIf
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.InitializeController()
    EndIf
    MMEAlertsQuickTest quickTest = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsQuickTest
    If quickTest != None
        quickTest.ScheduleTestSetup()
    EndIf
EndEvent
