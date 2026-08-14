Scriptname MMEAlertsPlayerEffect extends ActiveMagicEffect

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
            quickTest.ApplyTestSetup()
        EndIf
        Refresh("monitor start")
    EndIf
EndEvent

; Reinitializes registrations and development helpers after loading a save.
Event OnPlayerLoadGame()
    MMEAlertsFlatRateDefaults flatDefaults = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsFlatRateDefaults
    If flatDefaults != None
        flatDefaults.ApplyDefaults()
    EndIf
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.InitializeController()
    EndIf
    MMEAlertsQuickTest quickTest = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsQuickTest
    If quickTest != None
        quickTest.ApplyTestSetup()
    EndIf
EndEvent
