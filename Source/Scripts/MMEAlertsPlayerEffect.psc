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
    Refresh("load")
EndEvent

; Refresh capacity baselines when the player enters another location.
Event OnLocationChange(Location oldLocation, Location newLocation)
    Refresh("location")
EndEvent

; Refresh capacity after waiting because MME may update milk during time skips.
Event OnWaitStop()
    Refresh("wait")
EndEvent

; Refresh capacity after sleeping because MME may update milk during time skips.
Event OnSleepStop(Bool interrupted)
    Refresh("sleep")
EndEvent
