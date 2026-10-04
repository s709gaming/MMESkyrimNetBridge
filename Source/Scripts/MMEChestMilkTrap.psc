Scriptname MMEChestMilkTrap Hidden

; Called only after the existing Milk Maid conversion trap declines or fails.
; Failed chance rolls and unavailable candidates do not consume the shared
; cooldown; only a verified potion consumption starts it.
Bool Function HandleActivation(Actor sourceActor, String chestIdentity, Bool bossChest) Global
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableChestMilkTrap", 1) != 1
        Return False
    EndIf
    If sourceActor == None || chestIdentity == ""
        Report("ignored malformed activation")
        Return False
    EndIf

    Float nowGame = Utility.GetCurrentGameTime()
    Float nextAllowed = StorageUtil.GetFloatValue(None, "MMEExtensions.ChestDrink.NextAllowedGameDay", -1.0)
    If nextAllowed > nowGame
        Report("cooldown active | remaining game hours=" + ((nextAllowed - nowGame) * 24.0))
        Return False
    EndIf

    Int chance = JsonUtil.GetIntValue("/MMEAlerts/Settings", "chestMilkTrapChance", 33)
    If chance < 0
        chance = 0
    ElseIf chance > 100
        chance = 100
    EndIf
    If chance == 0 || Utility.RandomInt(1, 100) > chance
        Report("chance missed | chest=" + chestIdentity + " | chance=" + chance)
        Return False
    EndIf

    Actor drinker = MMEChestTrapTargets.SelectTarget(sourceActor, 3, 1500.0)
    If drinker == None
        Report("no eligible nearby adult humanoid | chest=" + chestIdentity)
        Return False
    EndIf
    Form milkItem = SelectExoticMilk()
    If milkItem == None
        MMELog.Alarm("[MME Extensions Chest Milk] FAILURE: Succubus, Vampire and Werewolf milk lists contained no usable forms")
        Return False
    EndIf

    String chestKind = "regular treasure chest"
    If bossChest
        chestKind = "boss treasure chest"
    EndIf
    SetContext(drinker, milkItem, chestKind)

    String animationOwner = "ChestMilkTrap.Drink"
    Bool animationStarted = False
    If drinker != Game.GetPlayer()
        animationStarted = MMEMinorAnimations.StartDrink(drinker, animationOwner, False, False)
    EndIf
    Bool consumed = MMEForcedMilkDrink.ForceMilkDrink(drinker, milkItem)
    If animationStarted
        Float remainingDuration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "npcDrinkAnimationDuration", 3.0) - 0.5
        If remainingDuration > 0.0
            Utility.Wait(remainingDuration)
        EndIf
        MMEMinorAnimations.Complete(drinker, animationOwner, "Chest milk drink", False)
    EndIf
    If !consumed
        ClearContext(drinker)
        Report("forced consumption failed | actor=" + GetActorName(drinker) + " | milk=" + GetMilkName(milkItem))
        Return False
    EndIf

    ; Guarantee both feedback channels even when the ordinary drink pipeline is
    ; disabled for this actor. The context flags make these calls idempotent if
    ; the native/alias observer already handled them during EquipItem.
    ShowNotificationIfOwned(drinker, milkItem)
    TryNarrateContext(drinker, milkItem)

    Float baseHours = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "chestMilkTrapCooldownHours", 1.0)
    Float variation = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "chestMilkTrapCooldownVariation", 0.0)
    If baseHours < 0.0
        baseHours = 0.0
    EndIf
    If variation < 0.0
        variation = 0.0
    EndIf
    Float rolledHours = baseHours + Utility.RandomFloat(0.0 - variation, variation)
    If rolledHours < 0.0
        rolledHours = 0.0
    EndIf
    StorageUtil.SetFloatValue(None, "MMEExtensions.ChestDrink.NextAllowedGameDay", nowGame + (rolledHours / 24.0))
    Report("complete | chest=" + chestIdentity + " | actor=" + GetActorName(drinker) + " | milk=" + GetMilkName(milkItem) + " | cooldown hours=" + rolledHours)
    Return True
EndFunction

Form Function SelectExoticMilk() Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return None
    EndIf
    Int category = Utility.RandomInt(0, 2)
    Int attempts = 0
    While attempts < 3
        FormList candidates = None
        If category == 0
            candidates = milkController.MME_Milk_Succubus
        ElseIf category == 1
            candidates = milkController.MME_Milk_Vampire
        Else
            candidates = milkController.MME_Milk_Werewolf
        EndIf
        Form selected = SelectSupportedForm(candidates)
        If selected != None
            Return selected
        EndIf
        category += 1
        If category > 2
            category = 0
        EndIf
        attempts += 1
    EndWhile
    Return None
EndFunction

Form Function SelectSupportedForm(FormList candidates) Global
    If candidates == None || candidates.GetSize() <= 0
        Return None
    EndIf
    Int size = candidates.GetSize()
    Int start = Utility.RandomInt(0, size - 1)
    Int offset = 0
    While offset < size
        Int index = start + offset
        While index >= size
            index -= size
        EndWhile
        Form selected = candidates.GetAt(index)
        If MMEDrinkTracker.GetSupportedDrinkKind(selected) != 0
            Return selected
        EndIf
        offset += 1
    EndWhile
    Return None
EndFunction

Function SetContext(Actor drinker, Form milkItem, String chestKind) Global
    StorageUtil.SetIntValue(drinker, "MMEExtensions.ChestDrink.Active", 1)
    StorageUtil.SetIntValue(drinker, "MMEExtensions.ChestDrink.MilkForm", milkItem.GetFormID())
    StorageUtil.SetStringValue(drinker, "MMEExtensions.ChestDrink.MilkName", GetMilkName(milkItem))
    StorageUtil.SetStringValue(drinker, "MMEExtensions.ChestDrink.ChestKind", chestKind)
    StorageUtil.SetFloatValue(drinker, "MMEExtensions.ChestDrink.Time", Utility.GetCurrentRealTime())
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.ChestDrink.Notified")
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.ChestDrink.Narrated")
EndFunction

Bool Function HasOwnedContext(Actor drinker, Form milkItem = None) Global
    If drinker == None || StorageUtil.GetIntValue(drinker, "MMEExtensions.ChestDrink.Active", 0) != 1
        Return False
    EndIf
    Float elapsed = Utility.GetCurrentRealTime() - StorageUtil.GetFloatValue(drinker, "MMEExtensions.ChestDrink.Time", -100.0)
    If elapsed < 0.0 || elapsed > 10.0
        ClearContext(drinker)
        Return False
    EndIf
    If milkItem != None && StorageUtil.GetIntValue(drinker, "MMEExtensions.ChestDrink.MilkForm", 0) != milkItem.GetFormID()
        Return False
    EndIf
    Return True
EndFunction

; Returns true whenever this exact chest transaction owns the notification,
; including when its dedicated toggle is off. That suppresses generic text.
Bool Function ShowNotificationIfOwned(Actor drinker, Form milkItem) Global
    If !HasOwnedContext(drinker, milkItem)
        Return False
    EndIf
    If StorageUtil.GetIntValue(drinker, "MMEExtensions.ChestDrink.Notified", 0) != 1
        StorageUtil.SetIntValue(drinker, "MMEExtensions.ChestDrink.Notified", 1)
        If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableChestMilkTrapNotification", 1) == 1
            Debug.Notification(BuildSituation(drinker))
        EndIf
    EndIf
    Return True
EndFunction

; Returns true whenever chest context owns narration, whether dispatch is
; enabled/available or not, so the ordinary drink narrator never duplicates it.
Bool Function TryNarrateContext(Actor drinker, Form milkItem = None) Global
    If !HasOwnedContext(drinker, milkItem)
        Return False
    EndIf
    If StorageUtil.GetIntValue(drinker, "MMEExtensions.ChestDrink.Narrated", 0) != 1
        StorageUtil.SetIntValue(drinker, "MMEExtensions.ChestDrink.Narrated", 1)
        MMEAlertsSkyrimNet.NarrateChestMilkDrink(drinker, StorageUtil.GetStringValue(drinker, "MMEExtensions.ChestDrink.MilkName", "exotic milk"), StorageUtil.GetStringValue(drinker, "MMEExtensions.ChestDrink.ChestKind", "treasure chest"))
    EndIf
    Return True
EndFunction

String Function BuildSituation(Actor drinker) Global
    Return GetActorName(drinker) + " is magically forced to drink " + StorageUtil.GetStringValue(drinker, "MMEExtensions.ChestDrink.MilkName", "exotic milk") + " from the chest!"
EndFunction

Function ClearContext(Actor drinker) Global
    If drinker == None
        Return
    EndIf
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.ChestDrink.Active")
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.ChestDrink.MilkForm")
    StorageUtil.UnsetStringValue(drinker, "MMEExtensions.ChestDrink.MilkName")
    StorageUtil.UnsetStringValue(drinker, "MMEExtensions.ChestDrink.ChestKind")
    StorageUtil.UnsetFloatValue(drinker, "MMEExtensions.ChestDrink.Time")
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.ChestDrink.Notified")
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.ChestDrink.Narrated")
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

String Function GetMilkName(Form milkItem) Global
    Return MMEForcedMilkDrink.GetItemName(milkItem)
EndFunction

Function Report(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Chest Milk] " + detail)
EndFunction
