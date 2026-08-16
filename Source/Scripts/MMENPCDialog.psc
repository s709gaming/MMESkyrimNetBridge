Scriptname MMENPCDialog extends TopicInfo Hidden

String SettingsFile = "/MMEAlerts/Settings"

; Stage-one dialogue fragment: validate and report only. No inventory changes.
Function Fragment_0(ObjectReference akSpeakerRef)
    Actor target = akSpeakerRef as Actor
    TestDialogueTarget(target)
EndFunction

Function TestDialogueTarget(Actor target)
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0) == 1
    GiveMilkToTarget(target, diagnostic)
EndFunction

; Shared entry point for dialogue fragments and optional Skyrim.Net actions.
Bool Function GiveMilkToTarget(Actor target, Bool diagnostic = False) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Return False
    EndIf
    If target == None
        Report(diagnostic, "target detection failed (speaker is not an Actor)")
        Return False
    EndIf

    String targetName = GetActorName(target)
    Report(diagnostic, "target detected: " + targetName)

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, "validation failed: MME controller not found")
        Return False
    EndIf

    Bool isMilkmaid = milkController.MilkMaid.Find(target) != -1
    If !isMilkmaid
        Report(diagnostic, targetName + " is not an MME Milkmaid; request rejected")
        Return False
    EndIf

    Report(diagnostic, targetName + " is an MME Milkmaid; validation passed")
    Return TestInventorySelection(Game.GetPlayer(), target, milkController, diagnostic)
EndFunction

; Selects one supported milk, then hands it to the validated NPC for native consumption.
Bool Function TestInventorySelection(Actor giver, Actor target, MilkQUEST milkController, Bool diagnostic) Global
    If giver == None
        Report(diagnostic, "inventory test failed: giver not found")
        Return False
    EndIf

    Form lactacid = milkController.MME_Util_Potions.GetAt(0)
    Form hearthfireMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    Int lactacidCount = GetOwnedCount(giver, lactacid)
    Int normalCount = GetOwnedCount(giver, hearthfireMilk) + CountOwnedFromList(giver, milkController.MME_Milk_Basic)
    Int racialCount = CountOwnedFromList(giver, milkController.MME_Milk_Race)
    Int supernaturalCount = CountOwnedFromList(giver, milkController.MME_Milk_Special)

    Report(diagnostic, "inventory: Lactacid " + lactacidCount + " | Normal " + normalCount + " | Racial " + racialCount + " | Supernatural " + supernaturalCount)

    Form selectedItem = None
    String selectedType = ""
    If lactacidCount > 0
        selectedItem = lactacid
        selectedType = "Lactacid"
    ElseIf normalCount > 0
        If GetOwnedCount(giver, hearthfireMilk) > 0
            selectedItem = hearthfireMilk
        Else
            selectedItem = FindFirstOwnedFromList(giver, milkController.MME_Milk_Basic)
        EndIf
        selectedType = "Normal"
    ElseIf racialCount > 0
        selectedItem = FindFirstOwnedFromList(giver, milkController.MME_Milk_Race)
        selectedType = "Racial"
    ElseIf supernaturalCount > 0
        selectedItem = FindFirstOwnedFromList(giver, milkController.MME_Milk_Special)
        selectedType = "Supernatural"
    EndIf

    If selectedItem == None
        Report(diagnostic, "no supported milk found; inventory unchanged")
        Return False
    EndIf
    String itemName = selectedItem.GetName()
    If itemName == ""
        itemName = "<unnamed milk>"
    EndIf
    Report(diagnostic, "selected " + selectedType + ": " + itemName + " [form " + selectedItem.GetFormID() + "]")
    Return ProcessNativeConsumption(giver, target, selectedItem, selectedType, milkController, diagnostic)
EndFunction

; Stage three transfers exactly one item and verifies that EquipItem consumed it.
Bool Function ProcessNativeConsumption(Actor giver, Actor target, Form selectedItem, String selectedType, MilkQUEST milkController, Bool diagnostic) Global
    If giver == None || target == None || selectedItem == None
        Report(diagnostic, "transfer failed: missing giver, target, or item")
        Return False
    EndIf
    If milkController.MilkMaid.Find(target) == -1
        Report(diagnostic, "transfer rejected: target is no longer an MME Milkmaid")
        Return False
    EndIf

    Int giverBefore = giver.GetItemCount(selectedItem)
    Int targetBefore = target.GetItemCount(selectedItem)
    If giverBefore < 1
        Report(diagnostic, "transfer failed: selected item is no longer in player inventory")
        Return False
    EndIf

    Float lactacidBefore = MME_Storage.getLactacidCurrent(target)
    giver.RemoveItem(selectedItem, 1, True, target)
    Int giverAfterTransfer = giver.GetItemCount(selectedItem)
    Int targetAfterTransfer = target.GetItemCount(selectedItem)

    If giverAfterTransfer != giverBefore - 1 || targetAfterTransfer != targetBefore + 1
        If giverAfterTransfer == giverBefore - 1 && targetAfterTransfer == targetBefore
            giver.AddItem(selectedItem, 1, True)
        ElseIf targetAfterTransfer > targetBefore
            target.RemoveItem(selectedItem, 1, True, giver)
        EndIf
        Report(diagnostic, "transfer failed; rollback attempted | player " + giverBefore + " -> " + giver.GetItemCount(selectedItem) + " | target " + targetBefore + " -> " + target.GetItemCount(selectedItem))
        Return False
    EndIf

    Report(diagnostic, "transferred one " + selectedType + " milk to " + GetActorName(target) + "; native consume attempted")
    ; The native equip observer will see this consumption. Mark it so the already
    ; tested dialogue pipeline remains the sole owner of these extension effects.
    StorageUtil.SetFloatValue(target, "MMEExtensions.NPCDrink.SuppressTime", Utility.GetCurrentRealTime())
    StorageUtil.SetIntValue(target, "MMEExtensions.NPCDrink.SuppressForm", selectedItem.GetFormID())
    target.EquipItem(selectedItem, False, True)
    Utility.Wait(0.5)

    Int targetAfterConsume = target.GetItemCount(selectedItem)
    If targetAfterConsume >= targetAfterTransfer
        ; The item is still present, so return the transferred copy to the giver.
        target.RemoveItem(selectedItem, 1, True, giver)
        Report(diagnostic, "consume failed; item returned | player " + giverBefore + " -> " + giver.GetItemCount(selectedItem))
        Return False
    EndIf

    Float lactacidAfter = MME_Storage.getLactacidCurrent(target)
    If selectedType == "Lactacid"
        Report(diagnostic, GetActorName(target) + " consumed Lactacid | player " + giverBefore + " -> " + giver.GetItemCount(selectedItem) + " | MME Lactacid " + lactacidBefore + " -> " + lactacidAfter)
    Else
        Report(diagnostic, GetActorName(target) + " consumed " + selectedItem.GetName() + " | player " + giverBefore + " -> " + giver.GetItemCount(selectedItem) + " | native potion processed")
    EndIf

    MMEAlertsSkyrimNet.NarrateNPCMilkDrink(target, True)
    Bool animationStarted = StartDrinkAnimation(target, diagnostic)
    ApplyExtensionEffects(target, selectedItem, selectedType, diagnostic)
    FinishDrinkAnimation(target, animationStarted, diagnostic)
    Return True
EndFunction

; Stage four applies only our modular extension effects. Native MME potion effects have
; already run, and Skyrim.Net is intentionally excluded from NPC dialogue consumption.
Function ApplyExtensionEffects(Actor target, Form selectedItem, String selectedType, Bool diagnostic) Global
    If target == None || selectedItem == None
        Report(diagnostic, "effects failed: missing target or consumed item")
        Return
    EndIf

    Int drinkKind = 1
    If selectedType == "Lactacid"
        drinkKind = 2
    EndIf

    Float milkBefore = MME_Storage.getMilkCurrent(target)
    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(target, drinkKind, False)
    Float milkAfter = MME_Storage.getMilkCurrent(target)

    Int arousalBefore = MMEArousalBridge.GetCurrentArousal(target)
    Bool arousalSent = MMEArousalBridge.ApplyMilkDrinkArousalForActor(target, selectedItem, False)
    If arousalSent
        Utility.Wait(0.25)
    EndIf
    Int arousalAfter = MMEArousalBridge.GetCurrentArousal(target)

    Int moanResult = MMEMilkDrinkEffects.PlayDrinkReaction(target, False)
    MMEDrinkTracker.ShowNPCDrinkNotification(target, selectedItem, milkAdded, arousalSent)
    String arousalResult = "off/unavailable"
    If arousalSent
        arousalResult = arousalBefore + " -> " + arousalAfter
    ElseIf MMEArousalBridge.IsAvailable() && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkDrinkArousal", 1) == 1
        arousalResult = "not applied"
    EndIf
    String moanResultText = "off"
    If moanResult > 0
        moanResultText = "played"
    ElseIf moanResult < 0
        moanResultText = "failed"
    EndIf

    Report(diagnostic, "effects " + GetActorName(target) + " | milk " + milkBefore + " -> " + milkAfter + " (+" + milkAdded + ") | arousal " + arousalResult + " | moan " + moanResultText)
EndFunction

; Starts MME's visible Lactacid reaction as soon as consumption is confirmed.
Bool Function StartDrinkAnimation(Actor target, Bool diagnostic) Global
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNPCDrinkAnimation", 0) != 1
        Report(diagnostic, "animation disabled")
        Return False
    EndIf
    If target == None
        Report(diagnostic, "animation skipped: target missing")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkMaid.Find(target) == -1
        Report(diagnostic, "animation skipped: target is no longer an MME Milkmaid")
        Return False
    EndIf
    If target.IsDead() || target.IsDisabled() || !target.Is3DLoaded()
        Report(diagnostic, "animation skipped: target unavailable")
        Return False
    EndIf
    If target.IsInCombat()
        Report(diagnostic, "animation skipped: target is in combat")
        Return False
    EndIf
    If target.IsOnMount()
        Report(diagnostic, "animation skipped: target is mounted")
        Return False
    EndIf
    Int sitState = target.GetSitState()
    If sitState > 0 && sitState <= 3
        Report(diagnostic, "animation skipped: target is sitting")
        Return False
    EndIf

    Debug.SendAnimationEvent(target, "ZaZAPCHorFd")
    Report(diagnostic, "animation started for " + GetActorName(target) + " (5 seconds)")
    Return True
EndFunction

; Milk/arousal processing includes up to 0.25 seconds of the five-second hold.
Function FinishDrinkAnimation(Actor target, Bool animationStarted, Bool diagnostic) Global
    If !animationStarted
        Return
    EndIf
    Utility.Wait(4.75)
    If target != None && !target.IsDead() && target.Is3DLoaded()
        Debug.SendAnimationEvent(target, "IdleForceDefaultState")
        Report(diagnostic, "animation finished for " + GetActorName(target))
    Else
        Report(diagnostic, "animation ended while target was unavailable")
    EndIf
EndFunction

Int Function GetOwnedCount(Actor owner, Form item) Global
    If owner == None || item == None
        Return 0
    EndIf
    Return owner.GetItemCount(item)
EndFunction

Int Function CountOwnedFromList(Actor owner, FormList items) Global
    If owner == None || items == None
        Return 0
    EndIf
    Int total = 0
    Int index = 0
    While index < items.GetSize()
        Form item = items.GetAt(index)
        If item != None
            total += owner.GetItemCount(item)
        EndIf
        index += 1
    EndWhile
    Return total
EndFunction

Form Function FindFirstOwnedFromList(Actor owner, FormList items) Global
    If owner == None || items == None
        Return None
    EndIf
    Int index = 0
    While index < items.GetSize()
        Form item = items.GetAt(index)
        If item != None && owner.GetItemCount(item) > 0
            Return item
        EndIf
        index += 1
    EndWhile
    Return None
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<no actor>"
    EndIf
    String result = target.GetDisplayName()
    If result == ""
        ActorBase baseInfo = target.GetLeveledActorBase()
        If baseInfo != None
            result = baseInfo.GetName()
        EndIf
    EndIf
    If result == ""
        result = "Unknown actor"
    EndIf
    Return result
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MME Extensions Dialogue] " + reportText)
    If showNotification
        Debug.Notification("Dialogue Debug: " + reportText)
    EndIf
EndFunction
