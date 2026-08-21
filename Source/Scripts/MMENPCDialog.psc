Scriptname MMENPCDialog extends TopicInfo Hidden

; ---------------------------------------------------------------------------
; Reusable Give Milk backend
; ---------------------------------------------------------------------------
; The dialogue INFO and Skyrim.Net action both delegate here. This script owns
; inventory selection, one-item transfer/consumption, duplicate suppression,
; Extensions effects, and the optional NPC drink animation in that order.

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
    ; Phase 1: validate extension state, actor identity, and live MME membership.
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
    ; Phase 2: hand the validated pair to the single inventory/consumption path.
    ; Keeping selection and consumption together minimizes inventory races.
    Return TestInventorySelection(Game.GetPlayer(), target, milkController, diagnostic)
EndFunction

; Selects one supported milk, then hands it to the validated NPC for native consumption.
Bool Function TestInventorySelection(Actor giver, Actor target, MilkQUEST milkController, Bool diagnostic) Global
    ; Phase 1: resolve all supported MME/vanilla sources and report inventory
    ; state. MME's live FormLists remain authoritative where available.
    If giver == None
        Report(diagnostic, "inventory test failed: giver not found")
        Return False
    EndIf

    Form lactacid = milkController.MME_Util_Potions.GetAt(0)
    Form hearthfireMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    Int lactacidCount = GetOwnedCount(giver, lactacid)
    Int normalCount = CountOwnedNormalMilk(giver, hearthfireMilk, milkController.MME_Milk_Basic)
    Int racialCount = CountOwnedFromList(giver, milkController.MME_Milk_Race)
    Int supernaturalCount = CountOwnedFromList(giver, milkController.MME_Milk_Special)

    Report(diagnostic, "inventory: Lactacid " + lactacidCount + " | Normal " + normalCount + " | Racial " + racialCount + " | Supernatural " + supernaturalCount)
    ReportNormalMilkInventory(giver, hearthfireMilk, milkController.MME_Milk_Basic, diagnostic)

    ; Phase 2: use the shared supported-milk selector. Blacksmith payment calls
    ; this same helper, keeping category membership, fallback records, and the
    ; Lactacid -> normal -> racial -> supernatural priority in one place.
    Form selectedItem = FindFirstSupportedMilk(giver, milkController)
    String selectedType = GetSupportedMilkType(selectedItem, milkController)

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

; Selects one owned item from the exact milk sources supported by Give Milk.
; This function only resolves inventory; callers remain responsible for their
; own final revalidation and for consuming/transferring exactly one item.
Form Function FindFirstSupportedMilk(Actor owner, MilkQUEST milkController) Global
    If owner == None || milkController == None
        Return None
    EndIf
    Form lactacid = None
    If milkController.MME_Util_Potions != None
        lactacid = milkController.MME_Util_Potions.GetAt(0)
    EndIf
    If GetOwnedCount(owner, lactacid) > 0
        Return lactacid
    EndIf
    Form hearthfireMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    Form selectedItem = FindFirstOwnedNormalMilk(owner, hearthfireMilk, milkController.MME_Milk_Basic)
    If selectedItem != None
        Return selectedItem
    EndIf
    selectedItem = FindFirstOwnedFromList(owner, milkController.MME_Milk_Race)
    If selectedItem != None
        Return selectedItem
    EndIf
    Return FindFirstOwnedFromList(owner, milkController.MME_Milk_Special)
EndFunction

; Provides the existing Give Milk diagnostic label for a shared selected form.
String Function GetSupportedMilkType(Form milkItem, MilkQUEST milkController) Global
    If milkItem == None || milkController == None
        Return ""
    EndIf
    If milkController.MME_Util_Potions != None && milkItem == milkController.MME_Util_Potions.GetAt(0)
        Return "Lactacid"
    EndIf
    Form hearthfireMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    If IsNormalMilk(milkItem, hearthfireMilk, milkController.MME_Milk_Basic)
        Return "Normal"
    EndIf
    If milkController.MME_Milk_Race != None && milkController.MME_Milk_Race.HasForm(milkItem)
        Return "Racial"
    EndIf
    If milkController.MME_Milk_Special != None && milkController.MME_Milk_Special.HasForm(milkItem)
        Return "Supernatural"
    EndIf
    Return "Supported"
EndFunction

Bool Function IsNormalMilk(Form milkItem, Form hearthfireMilk, FormList basicMilkList) Global
    If milkItem == None
        Return False
    EndIf
    If milkItem == hearthfireMilk || (basicMilkList != None && basicMilkList.HasForm(milkItem))
        Return True
    EndIf
    Return milkItem == Game.GetFormFromFile(0x016364, "MilkModNEW.esp") \
        || milkItem == Game.GetFormFromFile(0x016368, "MilkModNEW.esp") \
        || milkItem == Game.GetFormFromFile(0x016369, "MilkModNEW.esp") \
        || milkItem == Game.GetFormFromFile(0x0168CE, "MilkModNEW.esp")
EndFunction

; Counts HearthFires milk and MME's four verified basic milk forms once each.
; The explicit records are a fallback for saves where MilkQUEST's FormList
; property is unavailable or incomplete; they are the actual list members in
; the supported local MilkModNEW.esp.
Int Function CountOwnedNormalMilk(Actor owner, Form hearthfireMilk, FormList basicMilkList) Global
    Int total = GetOwnedCount(owner, hearthfireMilk)
    total += CountOwnedFromList(owner, basicMilkList)
    total += CountOwnedVerifiedBasicFallback(owner, basicMilkList, 0x016364)
    total += CountOwnedVerifiedBasicFallback(owner, basicMilkList, 0x016368)
    total += CountOwnedVerifiedBasicFallback(owner, basicMilkList, 0x016369)
    total += CountOwnedVerifiedBasicFallback(owner, basicMilkList, 0x0168CE)
    Return total
EndFunction

Int Function CountOwnedVerifiedBasicFallback(Actor owner, FormList basicMilkList, Int localFormID) Global
    Form basicMilk = Game.GetFormFromFile(localFormID, "MilkModNEW.esp")
    If basicMilk == None || (basicMilkList != None && basicMilkList.HasForm(basicMilk))
        Return 0
    EndIf
    Return GetOwnedCount(owner, basicMilk)
EndFunction

Form Function FindFirstOwnedNormalMilk(Actor owner, Form hearthfireMilk, FormList basicMilkList) Global
    If GetOwnedCount(owner, hearthfireMilk) > 0
        Return hearthfireMilk
    EndIf
    Form selectedItem = FindFirstOwnedFromList(owner, basicMilkList)
    If selectedItem != None
        Return selectedItem
    EndIf
    selectedItem = FindOwnedVerifiedBasic(owner, 0x016364)
    If selectedItem == None
        selectedItem = FindOwnedVerifiedBasic(owner, 0x016368)
    EndIf
    If selectedItem == None
        selectedItem = FindOwnedVerifiedBasic(owner, 0x016369)
    EndIf
    If selectedItem == None
        selectedItem = FindOwnedVerifiedBasic(owner, 0x0168CE)
    EndIf
    Return selectedItem
EndFunction

Form Function FindOwnedVerifiedBasic(Actor owner, Int localFormID) Global
    Form basicMilk = Game.GetFormFromFile(localFormID, "MilkModNEW.esp")
    If GetOwnedCount(owner, basicMilk) > 0
        Return basicMilk
    EndIf
    Return None
EndFunction

Function ReportNormalMilkInventory(Actor owner, Form hearthfireMilk, FormList basicMilkList, Bool diagnostic) Global
    If !diagnostic
        Return
    EndIf
    Int listSize = 0
    If basicMilkList != None
        listSize = basicMilkList.GetSize()
    EndIf
    Report(True, "normal milk sources | HearthFires resolved=" + (hearthfireMilk != None) + " count=" + GetOwnedCount(owner, hearthfireMilk) + " | MME basic list size=" + listSize)
    Int index = 0
    While basicMilkList != None && index < basicMilkList.GetSize()
        Form basicMilk = basicMilkList.GetAt(index)
        If basicMilk != None
            Report(True, "MME basic[" + index + "] " + basicMilk.GetName() + " [form " + basicMilk.GetFormID() + "] count=" + GetOwnedCount(owner, basicMilk))
        Else
            Report(True, "MME basic[" + index + "] failed to resolve")
        EndIf
        index += 1
    EndWhile
EndFunction

; Stage three transfers exactly one item and verifies that EquipItem consumed it.
Bool Function ProcessNativeConsumption(Actor giver, Actor target, Form selectedItem, String selectedType, MilkQUEST milkController, Bool diagnostic) Global
    ; Phase 1: revalidate references, membership, and inventory immediately before
    ; committing. Eligibility may have changed since the dialogue/action check.
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
    ; Phase 2: transfer one item and verify both inventories. Any partial transfer
    ; is rolled back before consumption or extension effects are attempted.
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
    ; Phase 3: mark the corresponding DLL potion event for suppression, then use
    ; EquipItem so Skyrim/MME execute the real native potion effects.
    ; The native equip observer will see this consumption. Mark it so the already
    ; tested dialogue pipeline remains the sole owner of these extension effects.
    StorageUtil.SetFloatValue(target, "MMEExtensions.NPCDrink.SuppressTime", Utility.GetCurrentRealTime())
    StorageUtil.SetIntValue(target, "MMEExtensions.NPCDrink.SuppressForm", selectedItem.GetFormID())
    target.EquipItem(selectedItem, False, True)
    Utility.Wait(0.5)

    ; Phase 4: verify consumption by inventory delta. If Skyrim retained the item,
    ; return the transferred copy rather than silently duplicating or deleting it.
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

    ; Phase 5: narration, optional animation, and modular Extensions effects run
    ; only after native consumption succeeded. The animation reset is last.
    MMEAlertsSkyrimNet.NarrateNPCMilkDrink(target, True)
    Bool animationStarted = StartDrinkAnimation(target, selectedItem, diagnostic)
    ApplyExtensionEffects(target, selectedItem, selectedType, diagnostic)
    FinishDrinkAnimation(target, animationStarted, diagnostic)
    Return True
EndFunction

; Stage four applies only our modular extension effects. Native MME potion effects have
; already run, and Skyrim.Net is intentionally excluded from NPC dialogue consumption.
Function ApplyExtensionEffects(Actor target, Form selectedItem, String selectedType, Bool diagnostic) Global
    ; Each integration is intentionally independent. Milk, arousal, sound, and
    ; notification failures do not undo successful native potion consumption.
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
Bool Function StartDrinkAnimation(Actor target, Form drinkItem, Bool diagnostic) Global
    Bool animDiagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkDrinkAnimationDiagnostic", 0) == 1
    String drinkLabel = ""
    If drinkItem != None
        drinkLabel = drinkItem.GetName()
    EndIf
    If drinkLabel == ""
        drinkLabel = "<unnamed>"
    EndIf
    Return MMEDrinkAnimation.StartDrinkAnimation(target, "enableNPCDrinkAnimation", "npcDrinkAnimationDuration", "NPC", drinkLabel, animDiagnostic)
EndFunction

; Holds MME's original Lactacid/New Milkmaid reaction for its configured duration.
Function FinishDrinkAnimation(Actor target, Bool animationStarted, Bool diagnostic) Global
    Bool animDiagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkDrinkAnimationDiagnostic", 0) == 1
    MMEDrinkAnimation.FinishDrinkAnimation(target, animationStarted, "npcDrinkAnimationDuration", "NPC", animDiagnostic)
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
