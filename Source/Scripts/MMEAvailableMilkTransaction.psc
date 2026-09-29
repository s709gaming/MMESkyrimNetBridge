Scriptname MMEAvailableMilkTransaction Hidden

; Public inventory-backed give-and-drink transaction. Selection deliberately
; preserves the established Give Milk order: normal, racial, supernatural.
; Lactacid is excluded. The existing Easy Mode setting supplies one temporary
; HearthFires Jug only when the giver owns no eligible milk.
Bool Function GiveAvailableMilk(Actor giver, Actor drinker) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableGiveMilkActionDiagnostic", 0) == 1
    If !MMEAlertsController.IsExtensionsEnabled()
        Report(diagnostic, "rejected: MME Extensions is disabled")
        Return False
    EndIf
    If giver == None || drinker == None || giver == drinker
        Report(diagnostic, "rejected: giver and drinker must be two different actors")
        Return False
    EndIf
    If !MMEActorDrinkTransaction.IsAvailableAdult(giver) || !MMEActorDrinkTransaction.IsAvailableAdult(drinker)
        Report(diagnostic, "rejected: both participants must be available, loaded adults outside combat")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        MMELog.Alarm("[MME Extensions Available Milk API] FAILURE: MME controller could not resolve")
        Return False
    EndIf
    Bool establishedMilkmaid = MMEArmorScript.IsMMEMilkMaid(drinker, milkController)
    If drinker != Game.GetPlayer() && !establishedMilkmaid && !MMENPCDrinkDialogue.IsEligible(drinker, milkController, diagnostic)
        Report(diagnostic, "rejected: NPC drinker is not enabled for the established Milk Maid or ordinary-adult route")
        Return False
    EndIf

    Float token = Utility.GetCurrentRealTime()
    If !MMEActorDrinkTransaction.TryAcquire(giver, token)
        Report(diagnostic, "rejected: giver already owns another drink transaction")
        Return False
    EndIf
    If !MMEActorDrinkTransaction.TryAcquire(drinker, token)
        MMEActorDrinkTransaction.Release(giver, token)
        Report(diagnostic, "rejected: drinker already owns another drink transaction")
        Return False
    EndIf

    ; Revalidate after both cooperative leases are held, then select once. This
    ; minimizes the inventory race between discovering and transferring milk.
    If !MMEActorDrinkTransaction.IsAvailableAdult(giver) || !MMEActorDrinkTransaction.IsAvailableAdult(drinker)
        ReleaseBoth(giver, drinker, token)
        Report(diagnostic, "rejected after lock: a participant became unavailable")
        Return False
    EndIf
    establishedMilkmaid = MMEArmorScript.IsMMEMilkMaid(drinker, milkController)
    If drinker != Game.GetPlayer() && !establishedMilkmaid && !MMENPCDrinkDialogue.IsEligible(drinker, milkController, diagnostic)
        ReleaseBoth(giver, drinker, token)
        Report(diagnostic, "rejected after lock: NPC drinker eligibility changed")
        Return False
    EndIf

    Form selectedItem = MMENPCDialog.FindFirstSupportedMilk(giver, milkController)
    Bool fallbackSupplied = False
    If selectedItem == None && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableGiveMilkEasyMode", 1) == 1
        selectedItem = Game.GetFormFromFile(0x003534, "HearthFires.esm")
        If selectedItem == None
            ReleaseBoth(giver, drinker, token)
            MMELog.Alarm("[MME Extensions Available Milk API] FAILURE: fallback HearthFires Jug of Milk could not resolve")
            Return False
        EndIf
        Int fallbackBefore = giver.GetItemCount(selectedItem)
        giver.AddItem(selectedItem, 1, True)
        If giver.GetItemCount(selectedItem) != fallbackBefore + 1
            ReleaseBoth(giver, drinker, token)
            MMELog.Alarm("[MME Extensions Available Milk API] FAILURE: temporary fallback Jug could not be staged")
            Return False
        EndIf
        fallbackSupplied = True
    EndIf
    If selectedItem == None
        ReleaseBoth(giver, drinker, token)
        Report(diagnostic, "rejected: giver owns no eligible milk and Free Jug for Give Milk is disabled")
        Return False
    EndIf

    String selectedType = MMENPCDialog.GetSupportedMilkType(selectedItem, milkController)
    Int drinkKind = MMEDrinkTracker.GetSupportedDrinkKind(selectedItem)
    If drinkKind == 0
        CleanupFallback(giver, selectedItem, fallbackSupplied)
        ReleaseBoth(giver, drinker, token)
        MMELog.Alarm("[MME Extensions Available Milk API] FAILURE: selected Give Milk form is not recognized by the drink tracker")
        Return False
    EndIf

    Int giverBefore = giver.GetItemCount(selectedItem)
    Int drinkerBefore = drinker.GetItemCount(selectedItem)
    giver.RemoveItem(selectedItem, 1, True, drinker)
    Int giverAfterTransfer = giver.GetItemCount(selectedItem)
    Int drinkerAfterTransfer = drinker.GetItemCount(selectedItem)
    If giverAfterTransfer != giverBefore - 1 || drinkerAfterTransfer != drinkerBefore + 1
        RollbackTransfer(giver, drinker, selectedItem, giverBefore, drinkerBefore, fallbackSupplied)
        ReleaseBoth(giver, drinker, token)
        Report(diagnostic, "failed: transfer did not produce the expected inventory deltas")
        Return False
    EndIf

    ; Player consumption belongs to the player alias. NPC consumption is
    ; explicitly processed below, so suppress its duplicate native callback.
    If drinker != Game.GetPlayer()
        StorageUtil.SetFloatValue(drinker, "MMEExtensions.NPCDrink.SuppressTime", Utility.GetCurrentRealTime())
        StorageUtil.SetIntValue(drinker, "MMEExtensions.NPCDrink.SuppressForm", selectedItem.GetFormID())
    EndIf
    drinker.EquipItem(selectedItem, False, True)
    Utility.Wait(0.5)
    If drinker.GetItemCount(selectedItem) >= drinkerAfterTransfer
        drinker.RemoveItem(selectedItem, 1, True, giver)
        CleanupFallback(giver, selectedItem, fallbackSupplied)
        ReleaseBoth(giver, drinker, token)
        Report(diagnostic, "failed: drinker did not consume the transferred milk; item returned")
        Return False
    EndIf

    Bool giveStarted = MMEMinorAnimations.StartGive(giver, "AvailableMilk.Giver", True, diagnostic)
    Bool drinkStarted = False
    Bool establishedAnimation = False
    String renderedReaction = ""
    If drinker != Game.GetPlayer()
        If establishedMilkmaid
            drinkStarted = MMENPCDialog.StartDrinkAnimation(drinker, selectedItem, diagnostic)
            establishedAnimation = drinkStarted
            renderedReaction = MMENPCDialog.ApplyExtensionEffects(drinker, selectedItem, selectedType, diagnostic)
        Else
            drinkStarted = MMEMinorAnimations.StartDrink(drinker, "AvailableMilk.Drinker", True, diagnostic)
            renderedReaction = MMENPCDrinkDialogue.ApplyPostDrink(drinker, selectedItem, diagnostic)
        EndIf
        MMEAlertsSkyrimNet.NarrateNPCMilkDrink(drinker, False, renderedReaction, False, establishedMilkmaid)
        MMEDrinkTracker.PublishDrinkEvent(drinker, selectedItem, drinkKind)
    EndIf

    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "npcDrinkAnimationDuration", 3.0)
    If duration < 0.0
        duration = 0.0
    EndIf
    If giveStarted || drinkStarted
        Utility.Wait(duration)
    EndIf
    If giveStarted
        MMEMinorAnimations.Complete(giver, "AvailableMilk.Giver", "Available Milk giver", diagnostic)
    EndIf
    If drinkStarted
        If establishedAnimation
            MMEDrinkAnimation.ResetAnimation(drinker, "NPC", diagnostic)
        Else
            MMEMinorAnimations.Complete(drinker, "AvailableMilk.Drinker", "Available Milk drinker", diagnostic)
        EndIf
    EndIf

    MMEExtensionsAPI.PublishAvailableMilkGiven(giver, drinker, selectedItem, fallbackSupplied)
    ReleaseBoth(giver, drinker, token)
    Report(diagnostic, "complete | giver=" + GetActorName(giver) + " | drinker=" + GetActorName(drinker) + " | milk=" + GetItemName(selectedItem) + " | fallback=" + fallbackSupplied)
    Return True
EndFunction

Function RollbackTransfer(Actor giver, Actor drinker, Form item, Int giverBefore, Int drinkerBefore, Bool fallbackSupplied) Global
    If drinker.GetItemCount(item) > drinkerBefore
        drinker.RemoveItem(item, 1, True, giver)
    ElseIf giver.GetItemCount(item) < giverBefore
        giver.AddItem(item, 1, True)
    EndIf
    CleanupFallback(giver, item, fallbackSupplied)
EndFunction

Function CleanupFallback(Actor giver, Form item, Bool fallbackSupplied) Global
    If fallbackSupplied && giver != None && item != None && giver.GetItemCount(item) > 0
        giver.RemoveItem(item, 1, True)
    EndIf
EndFunction

Function ReleaseBoth(Actor giver, Actor drinker, Float token) Global
    MMEActorDrinkTransaction.Release(drinker, token)
    MMEActorDrinkTransaction.Release(giver, token)
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEActorDrinkTransaction.GetActorName(target)
EndFunction

String Function GetItemName(Form item) Global
    If item == None || item.GetName() == ""
        Return "some milk"
    EndIf
    Return item.GetName()
EndFunction

Function Report(Bool diagnostic, String detail) Global
    MMELog.Diagnostic("[MME Extensions Available Milk API] " + detail)
    If diagnostic
        Debug.Notification("Available Milk API: " + detail)
    EndIf
EndFunction
