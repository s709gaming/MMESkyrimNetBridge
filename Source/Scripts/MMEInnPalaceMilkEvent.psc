Scriptname MMEInnPalaceMilkEvent Hidden

; Owns the delayed social-venue drink transaction. The native bridge only
; classifies venue entry/exit, and the controller only schedules the returned
; absolute deadline. All actor selection, cooldown and notification context
; remain isolated here.

Float Function Arm(Location venue, Int venueKind) Global
    If venue == None || !IsVenueKindEnabled(venueKind)
        Return 0.0
    EndIf
    Float nowGame = Utility.GetCurrentGameTime()
    Float nextAllowed = StorageUtil.GetFloatValue(None, "MMEExtensions.InnPalaceDrink.NextAllowedGameDay", -1.0)
    If nextAllowed > nowGame
        Report("entry ignored during cooldown | remaining game hours=" + ((nextAllowed - nowGame) * 24.0))
        Return 0.0
    EndIf

    ; Town/city ancestry is deliberately broad and may include interiors.
    ; Unlike inns and curated social venues, town entry uses its own chance.
    If venueKind == 4
        Int townChance = JsonUtil.GetIntValue("/MMEAlerts/Settings", "townMilkDrinkChance", 25)
        If townChance < 0
            townChance = 0
        ElseIf townChance > 100
            townChance = 100
        EndIf
        If townChance == 0 || Utility.RandomInt(1, 100) > townChance
            Report("town entry chance missed | venue=" + venue.GetFormID() + " | chance=" + townChance)
            Return 0.0
        EndIf
    EndIf

    Float baseDelay = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "innPalaceDrinkDelaySeconds", 11.0)
    Float variation = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "innPalaceDrinkDelayVariation", 10.0)
    If baseDelay < 1.0
        baseDelay = 1.0
    EndIf
    If variation < 0.0
        variation = 0.0
    EndIf
    Float delay = baseDelay + Utility.RandomFloat(0.0 - variation, variation)
    If delay < 1.0
        delay = 1.0
    EndIf
    Float due = Utility.GetCurrentRealTime() + delay
    Report("timer armed | venue=" + venue.GetFormID() + " | kind=" + venueKind + " | delay seconds=" + delay)
    Return due
EndFunction

Bool Function ProcessDue(Location venue, Int venueKind, Float radius = 2000.0) Global
    If venue == None || !IsVenueKindEnabled(venueKind)
        Report("due transaction canceled because venue or setting is unavailable")
        Return False
    EndIf
    Float nowGame = Utility.GetCurrentGameTime()
    Float nextAllowed = StorageUtil.GetFloatValue(None, "MMEExtensions.InnPalaceDrink.NextAllowedGameDay", -1.0)
    If nextAllowed > nowGame
        Report("due transaction canceled by cooldown")
        Return False
    EndIf

    Actor drinker = SelectRandomDrinker(radius)
    If drinker == None
        Report("no eligible NPC was loaded when the timer fired")
        Return False
    EndIf
    Form normalMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    If normalMilk == None
        MMELog.Alarm("[MME Extensions Inn/Palace Drink] FAILURE: HearthFires Jug of Milk did not resolve")
        Return False
    EndIf

    SetContext(drinker, normalMilk)
    Bool consumed = MMEExtensionsAPI.DrinkNormalMilk(drinker)
    If !consumed
        ClearContext(drinker)
        Report("normal milk API failed | actor=" + MMEForcedMilkDrink.GetActorName(drinker))
        Return False
    EndIf

    ; The equip observer may process before or after the API returns. This call
    ; guarantees the dedicated message, while the idempotent context suppresses
    ; the ordinary notification whenever that observer arrives.
    ShowNotificationIfOwned(drinker, normalMilk)

    Float cooldownHours = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "innPalaceDrinkCooldownHours", 4.0)
    If cooldownHours < 0.0
        cooldownHours = 0.0
    ElseIf cooldownHours > 24.0
        cooldownHours = 24.0
    EndIf
    StorageUtil.SetFloatValue(None, "MMEExtensions.InnPalaceDrink.NextAllowedGameDay", nowGame + (cooldownHours / 24.0))
    Report("complete | venue=" + venue.GetFormID() + " | actor=" + MMEForcedMilkDrink.GetActorName(drinker) + " | cooldown game hours=" + cooldownHours)
    Return True
EndFunction

Bool Function IsVenueKindEnabled(Int venueKind) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Return False
    EndIf
    If venueKind == 4
        Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableTownMilkDrink", 1) == 1
    ElseIf JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableInnPalaceMilkDrinking", 1) != 1
        Return False
    ElseIf venueKind == 1
        Return True
    ElseIf venueKind == 2
        Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableGuildTavernMilkDrinking", 1) == 1
    ElseIf venueKind == 3
        Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableJarlResidenceMilkDrinking", 1) == 1
    EndIf
    Return False
EndFunction

Actor Function SelectRandomDrinker(Float radius) Global
    Actor playerActor = Game.GetPlayer()
    Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(radius)
    Actor[] candidates = new Actor[128]
    Int candidateCount = 0
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Int i = 0
    While i < nearbyActors.Length && candidateCount < 128
        Actor candidate = nearbyActors[i]
        If candidate != None && candidate != playerActor && IsEligibleCandidate(candidate, milkController)
            candidates[candidateCount] = candidate
            candidateCount += 1
        EndIf
        i += 1
    EndWhile
    If candidateCount <= 0
        Return None
    EndIf
    Return candidates[Utility.RandomInt(0, candidateCount - 1)]
EndFunction

Bool Function IsEligibleCandidate(Actor candidate, MilkQUEST milkController) Global
    If !MMEForcedMilkDrink.IsEligibleActor(candidate) || candidate.IsInCombat()
        Return False
    EndIf
    If milkController != None && MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
        Return True
    EndIf
    Return MMENPCDrinkDialogue.IsEligible(candidate, milkController)
EndFunction

Function SetContext(Actor drinker, Form milkItem) Global
    StorageUtil.SetIntValue(drinker, "MMEExtensions.InnPalaceDrink.Active", 1)
    StorageUtil.SetIntValue(drinker, "MMEExtensions.InnPalaceDrink.MilkForm", milkItem.GetFormID())
    StorageUtil.SetFloatValue(drinker, "MMEExtensions.InnPalaceDrink.Time", Utility.GetCurrentRealTime())
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.InnPalaceDrink.Notified")
EndFunction

Bool Function HasOwnedContext(Actor drinker, Form milkItem = None) Global
    If drinker == None || StorageUtil.GetIntValue(drinker, "MMEExtensions.InnPalaceDrink.Active", 0) != 1
        Return False
    EndIf
    Float elapsed = Utility.GetCurrentRealTime() - StorageUtil.GetFloatValue(drinker, "MMEExtensions.InnPalaceDrink.Time", -100.0)
    If elapsed < 0.0 || elapsed > 10.0
        ClearContext(drinker)
        Return False
    EndIf
    If milkItem != None && StorageUtil.GetIntValue(drinker, "MMEExtensions.InnPalaceDrink.MilkForm", 0) != milkItem.GetFormID()
        Return False
    EndIf
    Return True
EndFunction

; Returns true whenever this exact venue transaction owns the HUD message.
; That lets every ordinary effect and narration run while preventing duplicate
; generic drink text.
Bool Function ShowNotificationIfOwned(Actor drinker, Form milkItem) Global
    If !HasOwnedContext(drinker, milkItem)
        Return False
    EndIf
    If StorageUtil.GetIntValue(drinker, "MMEExtensions.InnPalaceDrink.Notified", 0) != 1
        StorageUtil.SetIntValue(drinker, "MMEExtensions.InnPalaceDrink.Notified", 1)
        Debug.Notification(MMEForcedMilkDrink.GetActorName(drinker) + " is thirsty and drinks some milk!")
    EndIf
    Return True
EndFunction

Function ClearContext(Actor drinker) Global
    If drinker == None
        Return
    EndIf
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.InnPalaceDrink.Active")
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.InnPalaceDrink.MilkForm")
    StorageUtil.UnsetFloatValue(drinker, "MMEExtensions.InnPalaceDrink.Time")
    StorageUtil.UnsetIntValue(drinker, "MMEExtensions.InnPalaceDrink.Notified")
EndFunction

Function Report(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Inn/Palace Drink] " + detail)
EndFunction
