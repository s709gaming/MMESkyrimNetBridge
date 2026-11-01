Scriptname MMELeakPlayerAlias extends ReferenceAlias

Event OnPlayerLoadGame()
    MMEMilkLeaks service = GetOwningQuest() as MMEMilkLeaks
    If service != None
        service.Maintenance()
    EndIf
EndEvent
