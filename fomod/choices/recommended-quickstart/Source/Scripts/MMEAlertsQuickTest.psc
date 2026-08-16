Scriptname MMEAlertsQuickTest extends Quest

; Installed only by the Recommended FOMOD choice. The global latch prevents
; duplicate grants when normal startup hooks invoke this helper more than once.
String QuickStartGrantKey = "MMEExtensions.QuickStart.Granted"
Bool milkVarietyGranted = False

Event OnInit()
    ApplyTestSetup()
EndEvent

Function ApplyTestSetup()
    If milkVarietyGranted || StorageUtil.GetIntValue(None, QuickStartGrantKey, 0) != 0
        Return
    EndIf

    Actor playerActor = Game.GetPlayer()
    If playerActor == None
        Return
    EndIf

    ; Set the shared save-state latch before adding items so concurrent startup
    ; events cannot each perform the grant.
    StorageUtil.SetIntValue(None, QuickStartGrantKey, 1)
    milkVarietyGranted = True

    Potion lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp") as Potion
    Potion succubusMilk = Game.GetFormFromFile(0x0394C2, "MilkModNEW.esp") as Potion
    Potion werewolfMilk = Game.GetFormFromFile(0x038F5B, "MilkModNEW.esp") as Potion
    Potion vampireMilk = Game.GetFormFromFile(0x038F5A, "MilkModNEW.esp") as Potion

    GrantMilkVariety(playerActor, lactacid, succubusMilk, werewolfMilk, vampireMilk)
EndFunction

Function GrantMilkVariety(Actor playerActor, Potion lactacid, Potion succubusMilk, Potion werewolfMilk, Potion vampireMilk)
    If playerActor == None
        Return
    EndIf

    If lactacid != None
        playerActor.AddItem(lactacid, 3, False)
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
EndFunction