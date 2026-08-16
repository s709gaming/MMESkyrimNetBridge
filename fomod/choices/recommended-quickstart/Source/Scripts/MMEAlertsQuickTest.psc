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
    Potion regularMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm") as Potion
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Potion bretonMilk = FindMilkByName(milkController.MME_Milk_Race, "Breton")
    Potion succubusMilk = Game.GetFormFromFile(0x0394C2, "MilkModNEW.esp") as Potion

    GrantMilkVariety(playerActor, lactacid, regularMilk, bretonMilk, succubusMilk)
EndFunction

Function GrantMilkVariety(Actor playerActor, Potion lactacid, Potion regularMilk, Potion bretonMilk, Potion succubusMilk)
    If playerActor == None
        Return
    EndIf

    If lactacid != None
        playerActor.AddItem(lactacid, 3, False)
    EndIf
    If regularMilk != None
        playerActor.AddItem(regularMilk, 3, False)
    EndIf
    If bretonMilk != None
        playerActor.AddItem(bretonMilk, 3, False)
    EndIf
    If succubusMilk != None
        playerActor.AddItem(succubusMilk, 3, False)
    EndIf
EndFunction

Potion Function FindMilkByName(FormList milkList, String nameFragment)
    If milkList == None
        Return None
    EndIf

    Int index = 0
    While index < milkList.GetSize()
        Potion milk = milkList.GetAt(index) as Potion
        If milk != None && StringUtil.Find(milk.GetName(), nameFragment) >= 0
            Return milk
        EndIf
        index += 1
    EndWhile
    Return None
EndFunction