Scriptname MMEMilkCravings Hidden

; ---------------------------------------------------------------------------
; Periodic Milk Maid craving gameplay
; ---------------------------------------------------------------------------
; The persistent controller owns both game-time deadlines. This helper owns
; eligibility, chance, data-driven wording, actor state and the final public
; milk-drink transaction. It never registers its own update.

String Function GetConfigFile() Global
    Return "/MMEAlerts/MilkCravings"
EndFunction

String Function GetActiveKey() Global
    Return "MMEExtensions.MilkCraving.Active"
EndFunction

Bool Function IsEnabled() Global
    Return MMEAlertsController.IsExtensionsEnabled() && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkCravings", 1) == 1
EndFunction

Float Function CalculateNextInterval() Global
    Float baseHours = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "milkCravingIntervalHours", 48.0)
    Float variation = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "milkCravingIntervalVariation", 24.0)
    If baseHours < 1.0
        baseHours = 1.0
    ElseIf baseHours > 168.0
        baseHours = 168.0
    EndIf
    If variation < 0.0
        variation = 0.0
    ElseIf variation > 48.0
        variation = 48.0
    EndIf
    ; Never let negative randomization produce a zero/negative update delay.
    Float maximumNegativeVariation = baseHours - 1.0
    If variation > maximumNegativeVariation
        variation = maximumNegativeVariation
    EndIf
    Float result = baseHours
    If variation > 0.0
        result += Utility.RandomFloat(0.0 - variation, variation)
    EndIf
    If result < 1.0
        result = 1.0
    EndIf
    Return result
EndFunction

Float Function CalculateGiveInDelay() Global
    Float maximumDelay = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "milkCravingGiveInDelayHours", 4.0)
    If maximumDelay < 0.0
        maximumDelay = 0.0
    ElseIf maximumDelay > 4.0
        maximumDelay = 4.0
    EndIf
    If maximumDelay <= 0.0
        Return 0.0
    EndIf
    Return Utility.RandomFloat(0.0, maximumDelay)
EndFunction

; Returns the one selected actor after the due check passes. Expected skips
; return None and are visible only through Master Papyrus Logging.
Actor Function BeginCraving(Actor[] nearbyActors) Global
    If !IsEnabled()
        Report("check skipped | feature disabled")
        Return None
    EndIf
    If nearbyActors.Length == 0
        Report("check complete | nearby=0 | eligible Milkmaids=0")
        Return None
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: MME_MilkQUEST could not resolve during candidate selection")
        Return None
    EndIf
    Int validCount = CountValidCandidates(nearbyActors, milkController)
    Report("check due | nearby=" + nearbyActors.Length + " | eligible Milkmaids=" + validCount)
    If validCount <= 0
        Return None
    EndIf

    Int chance = JsonUtil.GetIntValue("/MMEAlerts/Settings", "milkCravingTriggerChance", 100)
    If chance < 0
        chance = 0
    ElseIf chance > 100
        chance = 100
    EndIf
    Int roll = 1
    If chance < 100
        roll = Utility.RandomInt(1, 100)
    EndIf
    If chance <= 0 || roll > chance
        Report("chance failed | roll=" + roll + " | chance=" + chance + "%")
        Return None
    EndIf
    Report("chance passed | roll=" + roll + " | chance=" + chance + "%")

    Actor selectedActor = SelectRandomCandidate(nearbyActors, milkController, validCount)
    If selectedActor == None
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: random selection returned no actor after finding " + validCount + " eligible Milk Maid(s)")
        Return None
    EndIf

    String rendered = SelectMessage("craving", selectedActor)
    Debug.Notification(rendered)
    StorageUtil.SetIntValue(selectedActor, GetActiveKey(), 1)
    StorageUtil.SetFloatValue(selectedActor, "MMEExtensions.MilkCraving.StartedGameDay", Utility.GetCurrentGameTime())
    Report("started | actor=" + GetActorName(selectedActor) + " | message=" + rendered)
    MMEAlertsSkyrimNet.NarrateMilkCraving(selectedActor, rendered)
    Return selectedActor
EndFunction

; Revalidates after the random delay. Natural world-state changes cancel the
; craving quietly; a rejected transaction after validation is a smoke alarm.
Bool Function ResolveCraving(Actor cravingActor) Global
    If cravingActor == None
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: give-in resolution received no actor")
        Return False
    EndIf
    If StorageUtil.GetIntValue(cravingActor, GetActiveKey(), 0) != 1
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: controller retained an actor without active craving state | actor=" + GetActorName(cravingActor))
        ClearCraving(cravingActor)
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: MME_MilkQUEST could not resolve at give-in | actor=" + GetActorName(cravingActor))
        ClearCraving(cravingActor)
        Return False
    EndIf
    If !IsValidCandidate(cravingActor, milkController)
        Report("give-in canceled | actor no longer a loaded, peaceful Milk Maid | actor=" + GetActorName(cravingActor))
        ClearCraving(cravingActor)
        Return False
    EndIf

    String rendered = SelectMessage("give_in", cravingActor)
    Debug.Notification(rendered)
    Report("give-in requested | actor=" + GetActorName(cravingActor) + " | message=" + rendered)
    Bool consumed = MMEExtensionsAPI.DrinkNormalMilk(cravingActor)
    If !consumed
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: DrinkNormalMilk rejected validated actor | actor=" + GetActorName(cravingActor))
    Else
        Report("drink complete | actor=" + GetActorName(cravingActor))
    EndIf
    ClearCraving(cravingActor)
    Return consumed
EndFunction

Function ClearCraving(Actor cravingActor) Global
    If cravingActor == None
        Return
    EndIf
    StorageUtil.UnsetIntValue(cravingActor, GetActiveKey())
    StorageUtil.UnsetFloatValue(cravingActor, "MMEExtensions.MilkCraving.StartedGameDay")
    Report("actor state cleared | actor=" + GetActorName(cravingActor))
EndFunction

Int Function CountValidCandidates(Actor[] nearbyActors, MilkQUEST milkController) Global
    Int count = 0
    Int i = 0
    While i < nearbyActors.Length
        If IsValidCandidate(nearbyActors[i], milkController)
            count += 1
        EndIf
        i += 1
    EndWhile
    Return count
EndFunction

Actor Function SelectRandomCandidate(Actor[] nearbyActors, MilkQUEST milkController, Int validCount) Global
    If validCount <= 0
        Return None
    EndIf
    Int desiredIndex = Utility.RandomInt(0, validCount - 1)
    Int foundIndex = 0
    Int i = 0
    While i < nearbyActors.Length
        Actor candidate = nearbyActors[i]
        If IsValidCandidate(candidate, milkController)
            If foundIndex == desiredIndex
                Return candidate
            EndIf
            foundIndex += 1
        EndIf
        i += 1
    EndWhile
    Return None
EndFunction

Bool Function IsValidCandidate(Actor candidate, MilkQUEST milkController) Global
    If candidate == None || milkController == None || !MMEForcedMilkDrink.IsEligibleActor(candidate) || candidate.IsInCombat()
        Return False
    EndIf
    Return MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
EndFunction

String Function SelectMessage(String poolName, Actor cravingActor) Global
    String fallback = GetFallbackMessage(poolName, cravingActor)
    String configFile = GetConfigFile()
    If !JsonUtil.JsonExists(configFile) || !JsonUtil.IsGood(configFile)
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: MilkCravings.json is missing or malformed; using fallback text")
        Return fallback
    EndIf
    String[] entries = JsonUtil.PathStringElements(configFile, "." + poolName)
    If entries.Length == 0
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: JSON pool is missing or empty: " + poolName + "; using fallback text")
        Return fallback
    EndIf
    Int selectedIndex = Utility.RandomInt(0, entries.Length - 1)
    String template = entries[selectedIndex]
    If template == ""
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: blank JSON entry in " + poolName + " at index " + selectedIndex + "; using fallback text")
        Return fallback
    EndIf
    String rendered = MMEAlertsSkyrimNet.RenderMessage(template, GetActorName(cravingActor))
    If rendered == ""
        MMELog.Alarm("[MME Extensions Milk Craving] FAILURE: message rendering returned blank text for pool " + poolName + "; using fallback text")
        Return fallback
    EndIf
    Return rendered
EndFunction

String Function GetFallbackMessage(String poolName, Actor cravingActor) Global
    String actorName = GetActorName(cravingActor)
    If poolName == "give_in"
        Return actorName + " can't resist the milk craving any longer."
    EndIf
    Return actorName + " can't stop thinking about drinking milk."
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

Function Report(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Milk Craving] " + detail)
EndFunction
