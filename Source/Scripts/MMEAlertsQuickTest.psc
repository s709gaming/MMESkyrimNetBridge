Scriptname MMEAlertsQuickTest extends Quest

; TEMPORARY DEVELOPMENT HELPER.
; Remove this script, its quest attachment, and the player-effect call when testing is complete.
Bool testSetupApplied = False
Bool milkVarietyGranted = False

; Quest startup invokes the temporary test-fixture setup.
Event OnInit()
    ApplyTestSetup()
EndEvent

; Enrolls and provisions the player for repeatable MME development tests.
Function ApplyTestSetup()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Potion lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp") as Potion
    Potion regularMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm") as Potion
    Potion succubusMilk = Game.GetFormFromFile(0x0394C2, "MilkModNEW.esp") as Potion
    Potion werewolfMilk = Game.GetFormFromFile(0x038F5B, "MilkModNEW.esp") as Potion
    Potion vampireMilk = Game.GetFormFromFile(0x038F5A, "MilkModNEW.esp") as Potion

    If milkController == None
        Debug.Notification("MME Alerts TEST - MME controller was not found.")
        Debug.Trace("[MMEAlert Test] MME_MilkQUEST was not found")
        Return
    EndIf

    Actor playerActor = Game.GetPlayer()
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

    JsonUtil.SetIntValue("/MMEAlerts/Settings", "enableCapacityPolling", 1)
    JsonUtil.SetIntValue("/MMEAlerts/Settings", "enableCapacityNotifications", 1)
    JsonUtil.SetIntValue("/MMEAlerts/Settings", "enableDebugMilkReport", 0)
    JsonUtil.SetIntValue("/MMEAlerts/Settings", "enableDrinkDetectionDebug", 1)
    JsonUtil.SetIntValue("/MMEAlerts/Settings", "enableDebugSoundLoop", 0)
    JsonUtil.Save("/MMEAlerts/Settings", False)
    MMEDebug debugController = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If debugController != None
        debugController.UpdateDebugLoop()
    EndIf

    If testSetupApplied
        GrantMilkVariety(playerActor, regularMilk, succubusMilk, werewolfMilk, vampireMilk)
        Debug.Trace("[MMEAlert Test] spells and debug verified; automatic Milkmaid enrollment is disabled")
        Return
    EndIf

    If lactacid != None
        playerActor.AddItem(lactacid, 10, False)
    Else
        Debug.Trace("[MMEAlert Test] MME_Lactacid was not found")
    EndIf
    GrantMilkVariety(playerActor, regularMilk, succubusMilk, werewolfMilk, vampireMilk)

    testSetupApplied = True
    Debug.Trace("[MMEAlert Test] test spells, debug, and Lactacid added; automatic Milkmaid enrollment is disabled")
EndFunction

; Grants test drinks once per save; requires the relevant optional forms to exist.
Function GrantMilkVariety(Actor playerActor, Potion regularMilk, Potion succubusMilk, Potion werewolfMilk, Potion vampireMilk)
    If milkVarietyGranted
        Return
    EndIf
    If regularMilk != None
        playerActor.AddItem(regularMilk, 3, False)
    EndIf
    If succubusMilk != None
        playerActor.AddItem(succubusMilk, 3, False)
    EndIf
    If werewolfMilk != None
        playerActor.AddItem(werewolfMilk, 3, False)
    EndIf
    If vampireMilk != None
        playerActor.AddItem(vampireMilk, 3, False)
    EndIf
    milkVarietyGranted = True
    Debug.Trace("[MMEAlert Test] granted three each: regular, Succubus, Werewolf, and Vampire milk")
EndFunction
