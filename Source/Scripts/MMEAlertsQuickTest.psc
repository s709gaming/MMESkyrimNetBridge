Scriptname MMEAlertsQuickTest extends Quest

; TEMPORARY DEVELOPMENT HELPER.
; Remove this script, its quest attachment, and the player-effect call when testing is complete.
Bool testSetupApplied = False

Event OnInit()
    ApplyTestSetup()
EndEvent

Function ApplyTestSetup()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Potion lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp") as Potion

    If milkController == None
        Debug.Notification("MME Alerts TEST - MME controller was not found.")
        Debug.Trace("[MMEAlert Test] MME_MilkQUEST was not found")
        Return
    EndIf

    Actor playerActor = Game.GetPlayer()
    If milkController.MilkMaid.Find(playerActor) < 0
        milkController.AssignSlot(playerActor)
    EndIf

    If milkController.MilkMaid.Find(playerActor) < 0
        Debug.Notification("MME Alerts TEST - MME could not make the player a Milk Maid.")
        Debug.Trace("[MMEAlert Test] AssignSlot did not enroll the player")
        Return
    EndIf

    StorageUtil.SetFloatValue(None, "MME.Progression.Level", 10.0)

    If milkController.MME_MakeMilkmaid_Spell != None && !playerActor.HasSpell(milkController.MME_MakeMilkmaid_Spell)
        playerActor.AddSpell(milkController.MME_MakeMilkmaid_Spell, False)
    EndIf
    If milkController.MilkSelf != None && !playerActor.HasSpell(milkController.MilkSelf)
        playerActor.AddSpell(milkController.MilkSelf, False)
    EndIf
    If milkController.MilkTarget != None && !playerActor.HasSpell(milkController.MilkTarget)
        playerActor.AddSpell(milkController.MilkTarget, False)
    EndIf

    JsonUtil.SetIntValue("/MMEAlerts/Settings", "enableDebugSoundLoop", 1)
    JsonUtil.Save("/MMEAlerts/Settings", False)
    MMEDebug debugController = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If debugController != None
        debugController.UpdateDebugLoop()
    EndIf

    If testSetupApplied
        Debug.Trace("[MMEAlert Test] enrollment, mastery, spells, and debug verified; consumables were already granted")
        Return
    EndIf

    If lactacid != None
        playerActor.AddItem(lactacid, 10, False)
    Else
        Debug.Trace("[MMEAlert Test] MME_Lactacid was not found")
    EndIf

    testSetupApplied = True
    Debug.Notification("MME Alerts TEST - player enrolled; mastery 10; test spells and Lactacid added.")
    Debug.Trace("[MMEAlert Test] player maid, mastery=10, test spells added, debug enabled, Lactacid=10")
EndFunction
