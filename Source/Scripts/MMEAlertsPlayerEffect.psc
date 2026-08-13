Scriptname MMEAlertsPlayerEffect extends ActiveMagicEffect

Function Refresh(String reason)
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshCapacity(reason)
    EndIf
EndFunction

Event OnEffectStart(Actor target, Actor caster)
    Refresh("monitor start")
EndEvent

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

Event OnLocationChange(Location oldLocation, Location newLocation)
    Refresh("location")
EndEvent

Event OnWaitStop()
    Refresh("wait")
EndEvent

Event OnSleepStop(Bool interrupted)
    Refresh("sleep")
EndEvent
