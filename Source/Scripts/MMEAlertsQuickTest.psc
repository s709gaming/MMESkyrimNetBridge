Scriptname MMEAlertsQuickTest extends Quest

; TEMPORARY DEVELOPMENT ITEM HELPER.
; This script only provisions consumable test items. Development defaults,
; spells, and polling configuration belong to their respective controllers.
Bool testSetupApplied = False
Bool milkVarietyGranted = False

; Quest startup invokes the temporary test-fixture setup.
Event OnInit()
    ApplyTestSetup()
EndEvent

; Provisions the player with consumables for repeatable MME development tests.
Function ApplyTestSetup()
    Potion lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp") as Potion
    Potion regularMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm") as Potion
    Potion succubusMilk = Game.GetFormFromFile(0x0394C2, "MilkModNEW.esp") as Potion
    Potion werewolfMilk = Game.GetFormFromFile(0x038F5B, "MilkModNEW.esp") as Potion
    Potion vampireMilk = Game.GetFormFromFile(0x038F5A, "MilkModNEW.esp") as Potion

    Actor playerActor = Game.GetPlayer()

    If testSetupApplied
        GrantMilkVariety(playerActor, regularMilk, succubusMilk, werewolfMilk, vampireMilk)
        Debug.Trace("[MMEAlert Test] consumable test inventory verified")
        Return
    EndIf

    If lactacid != None
        playerActor.AddItem(lactacid, 10, False)
    Else
        Debug.Trace("[MMEAlert Test] MME_Lactacid was not found")
    EndIf
    GrantMilkVariety(playerActor, regularMilk, succubusMilk, werewolfMilk, vampireMilk)

    testSetupApplied = True
    Debug.Trace("[MMEAlert Test] Lactacid and milk varieties added")
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
