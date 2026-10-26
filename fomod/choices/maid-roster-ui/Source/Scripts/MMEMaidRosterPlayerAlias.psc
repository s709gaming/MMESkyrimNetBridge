Scriptname MMEMaidRosterPlayerAlias extends ReferenceAlias

Event OnPlayerLoadGame()
    MMEMaidRosterUI roster = GetOwningQuest() as MMEMaidRosterUI
    If roster != None
        roster.RecoverAfterLoad()
    EndIf
EndEvent
