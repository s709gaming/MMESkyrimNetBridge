Scriptname MMEForcedMilkDrink Hidden

; Reusable, backend-neutral forced milk transaction. A real supported potion is
; staged and equipped so MME Extensions' normal native/alias drink observers
; remain the only owners of milk gain, arousal, conversion, sound and events.
Bool Function ForceMilkDrink(Actor drinker, Form milkItem) Global
    If !MMEAlertsController.IsExtensionsEnabled() || !IsEligibleActor(drinker)
        Report("rejected invalid or unavailable drinker")
        Return False
    EndIf
    Int drinkKind = MMEDrinkTracker.GetSupportedDrinkKind(milkItem)
    If drinkKind == 0
        Report("rejected unsupported milk item")
        Return False
    EndIf

    String lockKey = "MMEExtensions.ForcedMilkDrink.Lock"
    Float now = Utility.GetCurrentRealTime()
    Float lockTime = StorageUtil.GetFloatValue(drinker, lockKey, -10.0)
    If StorageUtil.GetIntValue(drinker, lockKey, 0) == 1 && now - lockTime >= 0.0 && now - lockTime < 5.0
        Report("rejected overlapping transaction for " + GetActorName(drinker))
        Return False
    EndIf
    StorageUtil.SetIntValue(drinker, lockKey, 1)
    StorageUtil.SetFloatValue(drinker, lockKey, now)

    Int beforeCount = drinker.GetItemCount(milkItem)
    drinker.AddItem(milkItem, 1, True)
    Int stagedCount = drinker.GetItemCount(milkItem)
    If stagedCount != beforeCount + 1
        ReleaseLock(drinker, lockKey)
        Report("failed to stage milk for " + GetActorName(drinker))
        Return False
    EndIf

    drinker.EquipItem(milkItem, False, True)
    Utility.Wait(0.5)
    Int afterCount = drinker.GetItemCount(milkItem)
    Bool consumed = afterCount <= beforeCount
    If !consumed && afterCount > beforeCount
        ; Roll back only the temporary item introduced by this transaction.
        drinker.RemoveItem(milkItem, afterCount - beforeCount, True)
    EndIf
    ReleaseLock(drinker, lockKey)

    If consumed
        MMEExtensionsAPI.PublishForcedMilkDrinkCompleted(drinker, milkItem, drinkKind)
        Report("consumption verified | actor=" + GetActorName(drinker) + " | item=" + GetItemName(milkItem) + " | kind=" + drinkKind)
    Else
        Report("consumption blocked; staged item removed | actor=" + GetActorName(drinker) + " | item=" + GetItemName(milkItem))
    EndIf
    Return consumed
EndFunction

Bool Function IsEligibleActor(Actor target) Global
    If target == None || target.IsDead() || target.IsDisabled() || target.IsUnconscious() || target.IsChild() || !target.Is3DLoaded()
        Return False
    EndIf
    ActorBase baseInfo = target.GetLeveledActorBase()
    Keyword actorTypeNPC = Game.GetFormFromFile(0x013794, "Skyrim.esm") as Keyword
    Return baseInfo != None && baseInfo.GetRace() != None && actorTypeNPC != None && baseInfo.GetRace().HasKeyword(actorTypeNPC)
EndFunction

Function ReleaseLock(Actor target, String lockKey) Global
    StorageUtil.UnsetIntValue(target, lockKey)
    StorageUtil.UnsetFloatValue(target, lockKey)
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<missing actor>"
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

String Function GetItemName(Form item) Global
    If item == None || item.GetName() == ""
        Return "some milk"
    EndIf
    Return item.GetName()
EndFunction

Function Report(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Forced Milk Drink] " + detail)
EndFunction
