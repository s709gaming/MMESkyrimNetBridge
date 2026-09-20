Scriptname MMEActorDrinkTransaction Hidden

; One-shot actor-to-actor milk transaction used by the Skyrim.Net action.
; A temporary HearthFires Jug is the stable inventory/animation baseline.
; Confirmed MME Milk Maids may fund that jug from MilkCurrent; every failure
; after deduction restores the exact amount that was removed.

String Function BusyKey() Global
    Return "MMEExtensions.ActorDrink.Busy"
EndFunction

String Function TokenKey() Global
    Return "MMEExtensions.ActorDrink.Token"
EndFunction

Bool Function IsAvailableAdult(Actor participant) Global
    Return participant != None && !participant.IsDead() && !participant.IsDisabled() && participant.Is3DLoaded() && !participant.IsChild() && !participant.IsInCombat()
EndFunction

Bool Function TryAcquire(Actor participant, Float token) Global
    If participant == None
        Return False
    EndIf

    Float now = Utility.GetCurrentRealTime()
    Float priorToken = StorageUtil.GetFloatValue(participant, TokenKey(), -1.0)
    If StorageUtil.GetIntValue(participant, BusyKey(), 0) == 1 && priorToken >= 0.0 && now - priorToken < 30.0
        Return False
    EndIf

    ; A thirty-second lease recovers interrupted stacks without polling.
    StorageUtil.SetFloatValue(participant, TokenKey(), token)
    StorageUtil.SetIntValue(participant, BusyKey(), 1)
    Return StorageUtil.GetIntValue(participant, BusyKey(), 0) == 1 && StorageUtil.GetFloatValue(participant, TokenKey(), -1.0) == token
EndFunction

Function Release(Actor participant, Float token) Global
    If participant != None && StorageUtil.GetFloatValue(participant, TokenKey(), -1.0) == token
        StorageUtil.UnsetIntValue(participant, BusyKey())
        StorageUtil.UnsetFloatValue(participant, TokenKey())
    EndIf
EndFunction

Function RestoreMilk(Actor giver, Float deducted, Bool diagnostic) Global
    If giver == None || deducted <= 0.0
        Return
    EndIf
    Float before = MME_Storage.getMilkCurrent(giver)
    MME_Storage.changeMilkCurrent(giver, deducted, True)
    Report(diagnostic, "rollback restored " + deducted + " milk to " + GetActorName(giver) + " | " + before + " -> " + MME_Storage.getMilkCurrent(giver))
EndFunction

Function CompleteAnimations(Actor giver, Actor drinker, Bool giveStarted, Bool drinkStarted, Bool diagnostic) Global
    If giveStarted
        MMEMinorAnimations.Complete(giver, "ActorDrink.Giver", "Actor drink giver", diagnostic)
    EndIf
    If drinkStarted
        MMEMinorAnimations.Complete(drinker, "ActorDrink.Drinker", "Actor drink receiver", diagnostic)
    EndIf
EndFunction

Bool Function GiveDrink(Actor giver, Actor drinker, Bool diagnostic = False) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Report(diagnostic, "rejected: MME Extensions is disabled")
        Return False
    EndIf
    If giver == None || drinker == None || giver == drinker
        Report(diagnostic, "rejected: giver and drinker must be two different actors")
        Return False
    EndIf
    If !IsAvailableAdult(giver) || !IsAvailableAdult(drinker)
        Report(diagnostic, "rejected: both participants must be available, loaded adults outside combat")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Form milkJug = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    If milkController == None || milkJug == None
        MMELog.Alarm("[MME Extensions Actor Drink] FAILURE: MME controller or HearthFires Jug of Milk could not resolve")
        Return False
    EndIf

    Float token = Utility.GetCurrentRealTime()
    If !TryAcquire(giver, token)
        Report(diagnostic, "rejected: giver already owns another drink transaction")
        Return False
    EndIf
    If !TryAcquire(drinker, token)
        Release(giver, token)
        Report(diagnostic, "rejected: drinker already owns another drink transaction")
        Return False
    EndIf

    ; Revalidate after both leases are held. This closes the action-dispatch gap
    ; without introducing an update loop or a persistent quest state machine.
    If !IsAvailableAdult(giver) || !IsAvailableAdult(drinker)
        Release(drinker, token)
        Release(giver, token)
        Report(diagnostic, "rejected after lock: a participant became unavailable")
        Return False
    EndIf

    Int giverBefore = giver.GetItemCount(milkJug)
    Int drinkerBefore = drinker.GetItemCount(milkJug)
    giver.AddItem(milkJug, 1, True)
    If giver.GetItemCount(milkJug) != giverBefore + 1
        Release(drinker, token)
        Release(giver, token)
        MMELog.Alarm("[MME Extensions Actor Drink] FAILURE: temporary HearthFires milk jug could not be supplied")
        Return False
    EndIf

    Float deducted = 0.0
    Bool giverIsMilkmaid = MMEArmorScript.IsMMEMilkMaid(giver, milkController)
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableActorDrinkMilkRemoval", 1) == 1 && giverIsMilkmaid
        Float milkBefore = MME_Storage.getMilkCurrent(giver)
        If milkBefore >= 1.0
            MME_Storage.changeMilkCurrent(giver, -1.0, True)
            Float milkAfter = MME_Storage.getMilkCurrent(giver)
            deducted = milkBefore - milkAfter
            If deducted < 0.0
                deducted = 0.0
            EndIf
            Report(diagnostic, "Milkmaid giver funded jug from MilkCurrent | " + milkBefore + " -> " + milkAfter)
        Else
            Report(diagnostic, "Milkmaid giver below one milk; using baseline free jug")
        EndIf
    Else
        Report(diagnostic, "using baseline free jug; giver milk storage unchanged")
    EndIf

    Bool giveStarted = MMEMinorAnimations.StartGive(giver, "ActorDrink.Giver", True, diagnostic)
    Bool drinkStarted = MMEMinorAnimations.StartDrink(drinker, "ActorDrink.Drinker", True, diagnostic)

    giver.RemoveItem(milkJug, 1, True, drinker)
    If giver.GetItemCount(milkJug) != giverBefore || drinker.GetItemCount(milkJug) != drinkerBefore + 1
        ; Delete only the temporary copy wherever it landed. Pre-existing jugs
        ; remain represented by the before-count baselines.
        If drinker.GetItemCount(milkJug) > drinkerBefore
            drinker.RemoveItem(milkJug, 1, True)
        ElseIf giver.GetItemCount(milkJug) > giverBefore
            giver.RemoveItem(milkJug, 1, True)
        EndIf
        RestoreMilk(giver, deducted, diagnostic)
        CompleteAnimations(giver, drinker, giveStarted, drinkStarted, diagnostic)
        Release(drinker, token)
        Release(giver, token)
        Report(diagnostic, "failed: temporary jug transfer did not produce the expected inventory deltas")
        Return False
    EndIf

    ; Player consumption belongs to MMEDrinkTracker. NPC consumption is marked
    ; so the native global observer cannot duplicate the explicit route below.
    If drinker != Game.GetPlayer()
        StorageUtil.SetFloatValue(drinker, "MMEExtensions.NPCDrink.SuppressTime", Utility.GetCurrentRealTime())
        StorageUtil.SetIntValue(drinker, "MMEExtensions.NPCDrink.SuppressForm", milkJug.GetFormID())
    EndIf
    drinker.EquipItem(milkJug, False, True)
    Utility.Wait(0.5)

    If drinker.GetItemCount(milkJug) >= drinkerBefore + 1
        drinker.RemoveItem(milkJug, 1, True)
        RestoreMilk(giver, deducted, diagnostic)
        CompleteAnimations(giver, drinker, giveStarted, drinkStarted, diagnostic)
        Release(drinker, token)
        Release(giver, token)
        Report(diagnostic, "failed: drinker did not consume the temporary jug")
        Return False
    EndIf

    String renderedReaction = ""
    If drinker != Game.GetPlayer()
        Bool drinkerIsMilkmaid = MMEArmorScript.IsMMEMilkMaid(drinker, milkController)
        If drinkerIsMilkmaid
            renderedReaction = MMENPCDialog.ApplyExtensionEffects(drinker, milkJug, "Normal", diagnostic)
        Else
            renderedReaction = MMENPCDrinkDialogue.ApplyPostDrink(drinker, milkJug, diagnostic)
        EndIf
        MMEAlertsSkyrimNet.NarrateNPCMilkDrink(drinker, False, renderedReaction, False, drinkerIsMilkmaid)
    EndIf

    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "npcDrinkAnimationDuration", 3.0)
    If duration < 0.0
        duration = 0.0
    EndIf
    If giveStarted || drinkStarted
        Utility.Wait(duration)
    EndIf
    CompleteAnimations(giver, drinker, giveStarted, drinkStarted, diagnostic)
    Release(drinker, token)
    Release(giver, token)
    Report(diagnostic, "complete | giver=" + GetActorName(giver) + " | drinker=" + GetActorName(drinker) + " | deductedMilk=" + deducted)
    Return True
EndFunction

String Function GetActorName(Actor participant) Global
    If participant == None
        Return "<missing actor>"
    EndIf
    String actorName = participant.GetDisplayName()
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

Function Report(Bool diagnostic, String reportText) Global
    MMELog.Diagnostic("[MME Extensions Actor Drink] " + reportText)
    If diagnostic
        Debug.Notification("Actor Give Drink: " + reportText)
    EndIf
EndFunction
