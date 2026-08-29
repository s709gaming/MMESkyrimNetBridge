Scriptname MMENewMilkMaid extends TopicInfo Hidden

; Isolated dialogue/result adapter for the breastfeeding-to-Milk-Maid route.
; The persistent MMEDebug service owns scene tracking; this script owns the
; special request's validation and MME-authoritative completion behavior.

Function Fragment_CreateMilkMaid(ObjectReference akSpeakerRef)
    StartRequest(Game.GetPlayer(), akSpeakerRef as Actor)
EndFunction

Bool Function StartRequest(Actor milkSource, Actor candidate) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST

    If milkSource != Game.GetPlayer()
        Report(diagnostic, "request rejected: the player must be the milk source")
        Return False
    EndIf
    If !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, diagnostic)
        Report(diagnostic, "request rejected: player is not a usable MME milk source")
        Return False
    EndIf
    If MME_Storage.getMilkCurrent(milkSource) < 1.0
        Report(diagnostic, "request rejected: player has less than one unit of milk")
        Return False
    EndIf
    If !MMEDebug.IsActorAvailable(candidate)
        Report(diagnostic, "request rejected: candidate is dead, disabled, or unloaded")
        Return False
    EndIf
    If milkController.MilkMaid != None && milkController.MilkMaid.Find(candidate) >= 0
        Report(diagnostic, "request rejected: candidate is already an MME Milk Maid")
        Return False
    EndIf

    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        Report(diagnostic, "request rejected: persistent breastfeeding service could not resolve")
        Return False
    EndIf

    Return service.StartBreastfeeding(milkSource, candidate, diagnostic, "Dialogue", "CreateMilkMaid")
EndFunction

; Called only by MMEDebug after it proves that the exact owned OStim scene
; ended normally. MME's Mode 4 sidecar must also have started or completed.
Function HandleBreastfeedingCompleted(Actor milkSource, Actor candidate, String semanticIntent, Bool mmeProcessed) Global
    If semanticIntent != "CreateMilkMaid"
        Return
    EndIf

    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If !mmeProcessed
        Report(diagnostic, "conversion skipped: MME Mode 4 did not start or complete")
        Return
    EndIf
    If milkSource != Game.GetPlayer() || !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, diagnostic)
        Report(diagnostic, "conversion skipped: player is no longer an authoritative MME Milk Maid source")
        Return
    EndIf
    If !MMEDebug.IsActorAvailable(candidate)
        Report(diagnostic, "conversion skipped: candidate is dead, disabled, or unloaded")
        Return
    EndIf
    If milkController.MilkMaid != None && milkController.MilkMaid.Find(candidate) >= 0
        Report(diagnostic, "conversion skipped: candidate became a Milk Maid before completion dispatch")
        Return
    EndIf
    If milkController.MME_Util_Potions == None
        Report(diagnostic, "conversion skipped: MME potion list is unavailable")
        Return
    EndIf

    ; Native Lactacid consumption is the only deployed MME entry point that
    ; includes the canonical eligibility checks, slot assignment, Lactacid
    ; initialization, and the roughly ten-second creation animation/effect.
    ; MME_AddMilkMaid and MME_MakeMilkmaid_Spell only assign a slot.
    Form lactacid = milkController.MME_Util_Potions.GetAt(0)
    If lactacid == None
        Report(diagnostic, "conversion skipped: MME Lactacid form did not resolve")
        Return
    EndIf

    Int beforeCount = candidate.GetItemCount(lactacid)
    candidate.AddItem(lactacid, 1, True)
    Int stagedCount = candidate.GetItemCount(lactacid)
    If stagedCount != beforeCount + 1
        Report(diagnostic, "conversion skipped: temporary Lactacid dose could not be staged")
        Return
    EndIf

    ; Suppress only MME Extensions' duplicate native drink observer. MME's own
    ; ActiveMagicEffect remains authoritative and runs without interception.
    StorageUtil.SetFloatValue(candidate, "MMEExtensions.NPCDrink.SuppressTime", Utility.GetCurrentRealTime())
    StorageUtil.SetIntValue(candidate, "MMEExtensions.NPCDrink.SuppressForm", lactacid.GetFormID())
    candidate.EquipItem(lactacid, False, True)
    Utility.Wait(0.5)

    ; EquipItem normally consumes the staged potion. If another mod blocks the
    ; consume, remove only the one temporary item this transaction introduced.
    If candidate.GetItemCount(lactacid) >= stagedCount
        candidate.RemoveItem(lactacid, 1, True)
        Report(diagnostic, "conversion failed: native Lactacid consumption was blocked; temporary dose removed")
        Return
    EndIf

    Report(diagnostic, "canonical MME Lactacid creation effect started for " + GetActorName(candidate))
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
    Debug.Trace("[MME Extensions New Milk Maid] " + reportText)
    If showNotification
        Debug.Notification("New Milk Maid: " + reportText)
    EndIf
EndFunction
