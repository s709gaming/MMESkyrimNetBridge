Scriptname MMEAlertsQuickTest extends Quest

; Installed only by the Recommended FOMOD choice. The global latch prevents
; duplicate grants when normal startup hooks invoke this helper more than once.
String QuickStartGrantKey = "MMEExtensions.QuickStart.Granted"
String QuickStartMilkCuirassGrantKey = "MMEExtensions.QuickStart.MilkCuirassGranted"
String QuickStartTentacleMeatGrantKey = "MMEExtensions.QuickStart.TentacleMeatGranted"
Bool milkVarietyGranted = False
Bool quickStartScheduled = False

Event OnInit()
    ScheduleTestSetup()
EndEvent

; Every startup hook enters through this one delayed gate. Repeated hooks do
; not restart the timer or create another grant attempt.
Function ScheduleTestSetup()
    ; Delay is a compatibility barrier for MME quest-property initialization,
    ; not a recurring timer. Multiple startup hooks share quickStartScheduled.
    If quickStartScheduled
        Return
    EndIf
    If StorageUtil.GetIntValue(None, QuickStartGrantKey, 0) != 0 \
    && StorageUtil.GetIntValue(None, QuickStartMilkCuirassGrantKey, 0) != 0 \
    && StorageUtil.GetIntValue(None, QuickStartTentacleMeatGrantKey, 0) != 0
        Return
    EndIf
    quickStartScheduled = True
    RegisterForSingleUpdate(15.0)
EndFunction

Event OnUpdate()
    ; Clear the in-memory debounce before attempting grants so an unresolved MME
    ; property can be retried by a later legitimate startup hook.
    quickStartScheduled = False
    ApplyTestSetup()
EndEvent

Function ApplyTestSetup()
    ; Armor and milk use separate persistent latches so upgrades can add the
    ; cuirass without duplicating milk previously granted by QuickStart.
    Actor playerActor = Game.GetPlayer()
    If playerActor == None
        Return
    EndIf
    GrantMilkCuirassOnce(playerActor)
    GrantOptionalArmorBonuses(playerActor)
    If milkVarietyGranted || StorageUtil.GetIntValue(None, QuickStartGrantKey, 0) != 0
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

; These plugins remain completely optional: their load-order index is checked
; before any form lookup, and every individual unresolved armor form is skipped.
Function GrantOptionalArmorBonuses(Actor playerActor)
    If playerActor == None
        Return
    EndIf

    String tentaclePlugin = "C5Kev's Tentacled Terrors Of Tamriel 3BA.esp"
    If StorageUtil.GetIntValue(None, QuickStartTentacleMeatGrantKey, 0) == 0
        StorageUtil.SetIntValue(None, QuickStartTentacleMeatGrantKey, 1)
        If Game.GetModByName(tentaclePlugin) != 255
            ; The plugin contains two three-piece armor families. Grant only each
            ; family's Mashed Meat records, never its Slime or Magma alternatives.
            GrantOptionalArmor(playerActor, tentaclePlugin, 0x0012F0) ; Living Armor cuirass
            GrantOptionalArmor(playerActor, tentaclePlugin, 0x0012F1) ; Living Armor shoes
            GrantOptionalArmor(playerActor, tentaclePlugin, 0x0012F2) ; Living Armor gauntlets
            GrantOptionalArmor(playerActor, tentaclePlugin, 0x00131F) ; Tentacle Parasite cuirass
            GrantOptionalArmor(playerActor, tentaclePlugin, 0x001320) ; Tentacle Parasite shoes
            GrantOptionalArmor(playerActor, tentaclePlugin, 0x001321) ; Tentacle Parasite gauntlets
        EndIf
    EndIf
EndFunction

Function GrantOptionalArmor(Actor playerActor, String pluginName, Int localFormID)
    Armor armorPiece = Game.GetFormFromFile(localFormID, pluginName) as Armor
    If armorPiece != None
        playerActor.AddItem(armorPiece, 1, False)
    EndIf
EndFunction

; Separate save latch lets existing Recommended QuickStart users receive this
; newly added test item without duplicating their earlier milk grants.
Function GrantMilkCuirassOnce(Actor playerActor)
    If playerActor == None || StorageUtil.GetIntValue(None, QuickStartMilkCuirassGrantKey, 0) != 0
        Return
    EndIf
    Bool armorDiagnostic = MMEArmorScript.GetArmorDiagnostic()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkCuirass == None
        MMEArmorScript.ReportArmor(armorDiagnostic, "Recommended QuickStart could not resolve MME Milk Cuirass")
        Return
    EndIf
    ; Set the latch only after inventory proves AddItem succeeded. A transiently
    ; unresolved property remains safely retryable on the next startup.
    Int cuirassCountBefore = playerActor.GetItemCount(milkController.MilkCuirass)
    playerActor.AddItem(milkController.MilkCuirass, 1, False)
    If playerActor.GetItemCount(milkController.MilkCuirass) > cuirassCountBefore
        StorageUtil.SetIntValue(None, QuickStartMilkCuirassGrantKey, 1)
        MMEArmorScript.ReportArmor(armorDiagnostic, "Recommended QuickStart granted one MME Milk Cuirass")
    Else
        MMEArmorScript.ReportArmor(armorDiagnostic, "Recommended QuickStart Milk Cuirass add did not succeed; grant remains pending")
    EndIf
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
