Scriptname MMENewMilkMaid extends TopicInfo Hidden

; Isolated dialogue/result adapter for the breastfeeding-to-Milk-Maid route.
; The persistent MMEDebug service owns scene tracking; this script owns the
; special request's validation and the post-scene handoff to MME's native
; Lactacid creation effect.

Function Fragment_CreateMilkMaid(ObjectReference akSpeakerRef)
    StartRequest(Game.GetPlayer(), akSpeakerRef as Actor)
EndFunction

Bool Function StartRequest(Actor milkSource, Actor candidate) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST

    TraceStep("request target=" + GetActorIdentity(candidate))
    If milkController != None && candidate != None
        TraceStep("target state: maid=" + YesNo(MMEArmorScript.IsMMEMilkMaid(candidate, milkController)) + " slave=" + YesNo(MMEArmorScript.IsMMEMilkSlave(candidate, milkController)))
    EndIf

    If milkSource != Game.GetPlayer()
        TraceStep("player is not the milk source", True)
        Report(diagnostic, "request rejected: the player must be the milk source")
        Return False
    EndIf
    If !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, diagnostic)
        TraceStep("player is not a usable milk source", True)
        Report(diagnostic, "request rejected: player is not a usable MME milk source")
        Return False
    EndIf
    If MME_Storage.getMilkCurrent(milkSource) < 1.0
        TraceStep("player has less than one milk", True)
        Report(diagnostic, "request rejected: player has less than one unit of milk")
        Return False
    EndIf

    String eligibilityFailure = GetEligibilityFailure(candidate, milkController)
    If eligibilityFailure != ""
        TraceStep(eligibilityFailure, True)
        Report(diagnostic, "request rejected: " + eligibilityFailure)
        Return False
    EndIf
    TraceStep("eligible")

    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        TraceStep("breastfeeding service unavailable", True)
        Report(diagnostic, "request rejected: persistent breastfeeding service could not resolve")
        Return False
    EndIf

    TraceStep("scene requested")
    Bool started = service.StartBreastfeeding(milkSource, candidate, diagnostic, "Dialogue", "CreateMilkMaid")
    If !started
        TraceStep("scene did not start", True)
    EndIf
    Return started
EndFunction

; Called only by MMEDebug after it proves that the exact owned OStim scene
; ended normally. Mode 4 is useful milk-processing telemetry, but it is not a
; prerequisite for the separate native MME Milk Maid creation transaction.
Function HandleBreastfeedingCompleted(Actor milkSource, Actor candidate, String semanticIntent, Bool mmeProcessed) Global
    If semanticIntent != "CreateMilkMaid"
        Return
    EndIf

    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If !mmeProcessed
        TraceStep("Mode 4 incomplete; creation continues")
    EndIf
    If milkSource != Game.GetPlayer()
        TraceStep("player source changed", True)
        Report(diagnostic, "conversion skipped: player is no longer the milk source")
        Return
    EndIf

    String eligibilityFailure = GetEligibilityFailure(candidate, milkController)
    If eligibilityFailure != ""
        TraceStep(eligibilityFailure, True)
        Report(diagnostic, "conversion skipped: " + eligibilityFailure)
        Return
    EndIf
    If milkController.MME_Util_Potions == None
        TraceStep("MME potion list unavailable", True)
        Report(diagnostic, "conversion skipped: MME potion list is unavailable")
        Return
    EndIf

    ; Feed one internally supplied dose to the candidate after breastfeeding.
    ; This invokes MME's own MilkLactacidScr, including its confirmation, slot
    ; assignment, Lactacid initialization, and ten-second reaction animation.
    ; Nothing is required from or removed from the player's inventory.
    Form lactacid = milkController.MME_Util_Potions.GetAt(0)
    If lactacid == None
        TraceStep("MME Lactacid form missing", True)
        Report(diagnostic, "conversion skipped: MME Lactacid form did not resolve")
        Return
    EndIf

    TraceStep("native creation requested")
    Int beforeCount = candidate.GetItemCount(lactacid)
    candidate.AddItem(lactacid, 1, True)
    Int stagedCount = candidate.GetItemCount(lactacid)
    If stagedCount != beforeCount + 1
        TraceStep("internal Lactacid could not be staged", True)
        Report(diagnostic, "conversion skipped: internal Lactacid dose could not be staged")
        Return
    EndIf

    ; Suppress only MME Extensions' duplicate native drink observer. MME's own
    ; ActiveMagicEffect remains authoritative and runs without interception.
    StorageUtil.SetFloatValue(candidate, "MMEExtensions.NPCDrink.SuppressTime", Utility.GetCurrentRealTime())
    StorageUtil.SetIntValue(candidate, "MMEExtensions.NPCDrink.SuppressForm", lactacid.GetFormID())
    candidate.EquipItem(lactacid, False, True)
    Utility.Wait(0.5)

    ; EquipItem normally consumes the internal potion. If another mod blocks
    ; it, remove only the one dose introduced by this transaction.
    If candidate.GetItemCount(lactacid) >= stagedCount
        candidate.RemoveItem(lactacid, 1, True)
        TraceStep("native Lactacid effect did not start", True)
        Report(diagnostic, "conversion failed: native Lactacid consumption was blocked; internal dose removed")
        Return
    EndIf

    TraceStep("native effect started")
    TraceStep("assigning slot")
    Int assignmentAttempt = 0
    While assignmentAttempt < 60 && !MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
        Utility.Wait(0.25)
        assignmentAttempt += 1
    EndWhile
    If !MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
        TraceStep("assignment failed", True)
        Report(diagnostic, "conversion failed: native MME effect did not assign a Milk Maid slot")
        Return
    EndIf
    TraceStep("slot confirmed")

    ; MilkLactacidScr waits one second after AssignSlotMaid before adding its
    ; first Lactacid point. Observe that final native initialization boundary.
    Int initializationAttempt = 0
    While initializationAttempt < 40 && MME_Storage.getLactacidCurrent(candidate) < 1.0
        Utility.Wait(0.25)
        initializationAttempt += 1
    EndWhile
    If MME_Storage.getLactacidCurrent(candidate) < 1.0
        TraceStep("Lactacid state was not initialized", True)
        Report(diagnostic, "conversion incomplete: slot exists but native Lactacid state was not initialized")
        Return
    EndIf

    TraceStep("initialized")
    TraceStep("created")
    Report(diagnostic, "canonical MME Lactacid creation effect confirmed for " + GetActorName(candidate))
EndFunction

; Returns a short failure reason, or an empty string when the original MME
; Lactacid creation branch can accept this candidate.
String Function GetEligibilityFailure(Actor candidate, MilkQUEST milkController) Global
    If milkController == None
        Return "MME controller unavailable"
    EndIf
    If !MMEDebug.IsActorAvailable(candidate) || candidate == Game.GetPlayer()
        Return "target invalid"
    EndIf
    If MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
        Return "already a Milk Maid; target=" + GetActorIdentity(candidate)
    EndIf
    If MMEArmorScript.IsMMEMilkSlave(candidate, milkController)
        Return "target is a Milk Slave; target=" + GetActorIdentity(candidate)
    EndIf

    ActorBase candidateBase = candidate.GetLeveledActorBase()
    If candidateBase == None
        Return "target base unavailable"
    EndIf
    Int candidateSex = candidateBase.GetSex()
    If candidateSex != 1 && !(candidateSex == 0 && milkController.MaleMaids)
        Return "target is not eligible under MME sex settings"
    EndIf
    If candidate.IsInCombat()
        Return "target is in combat"
    EndIf
    If candidate.IsOnMount()
        Return "target is mounted"
    EndIf
    ; Do not inspect MilkQUEST.MilkMaid from an external script. Some MME
    ; builds return None for that array even though MilkQUEST itself owns a
    ; valid live registry. The native Lactacid effect performs the definitive
    ; capacity check and AssignSlotMaid transaction after the scene.
    Return ""
EndFunction

Bool Function IsTraceEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNewMilkmaidDialogueTrace", 0) == 1
EndFunction

Function TraceStep(String traceText, Bool failed = False) Global
    If !IsTraceEnabled()
        Return
    EndIf
    String line = "New Milkmaid: " + traceText
    If failed
        line = "New Milkmaid FAIL: " + traceText
    EndIf
    Debug.Trace("[MME Extensions New Milkmaid] " + line)
    Debug.Notification(line)
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

String Function GetActorIdentity(Actor target) Global
    If target == None
        Return "<no actor>"
    EndIf
    Return GetActorName(target) + " formID=" + target.GetFormID()
EndFunction

String Function YesNo(Bool value) Global
    If value
        Return "yes"
    EndIf
    Return "no"
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MME Extensions New Milk Maid] " + reportText)
    If showNotification
        Debug.Notification("New Milk Maid: " + reportText)
    EndIf
EndFunction
