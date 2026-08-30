Scriptname MMENewMilkMaid extends MME_Dialogues Hidden

; Isolated dialogue/result adapter for the breastfeeding-to-Milk-Maid route.
; The persistent MMEDebug service owns scene tracking; this script owns the
; special request's validation and the post-scene handoff to MME's native
; Lactacid creation effect.

Function Fragment_CreateMilkMaid(ObjectReference akSpeakerRef)
    StartRequest(Game.GetPlayer(), akSpeakerRef as Actor)
EndFunction

; SexLab-specific result fragment. Arm Extensions first, then deliberately
; enter MME's own player-source/NPC-drinker fragment. MME remains responsible
; for registrar selection, StartSex, and Mode 4 startup.
Function Fragment_CreateMilkMaidSexLab(ObjectReference akSpeakerRef)
    Actor milkSource = Game.GetPlayer()
    Actor candidate = akSpeakerRef as Actor
    TraceSexLabStop(1, "ENTRY | target=" + GetActorIdentity(candidate))
    If !ValidateSexLabRequest(milkSource, candidate)
        Return
    EndIf

    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        TraceSexLabStop(6, "persistent breastfeeding service unavailable", True)
        Return
    EndIf
    If !service.ArmMMENewMilkMaidSexLab(milkSource, candidate)
        TraceSexLabStop(6, "CreateMilkMaid intent rejected", True)
        Return
    EndIf

    TraceSexLabStop(7, "MME breastfeeding requested")
    Parent.Fragment_02(akSpeakerRef)
    ; MME's StartSex call is asynchronous. The persistent service claims the
    ; exact resulting thread from SexLab's AnimationEnding event, before its
    ; controller resets the ordered Positions used by MME.
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
    ; This is the established OStim INFO lane. The independent SexLab INFO uses
    ; Fragment_CreateMilkMaidSexLab and never falls through this function.
    If !MMEOStimBreastfeeding.IsBreastfeedingEnabled()
        TraceStep("OStim breastfeeding is disabled", True)
        Return False
    EndIf
    TraceStep("backend=OStim")
    Bool started = service.StartBreastfeeding(milkSource, candidate, diagnostic, "Dialogue", "CreateMilkMaid")
    If !started
        TraceStep("scene did not start", True)
    EndIf
    Return started
EndFunction

; Called only by MMEDebug after it proves that the exact owned OStim or SexLab
; scene ended normally. Mode 4 is useful milk-processing telemetry, but it is
; not a prerequisite for the separate native MME Milk Maid creation transaction.
Function HandleBreastfeedingCompleted(Actor milkSource, Actor candidate, String semanticIntent, Bool mmeProcessed) Global
    Bool sexLabRoute = semanticIntent == "CreateMilkMaidSexLab"
    If semanticIntent != "CreateMilkMaid" && !sexLabRoute
        Return
    EndIf

    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If !mmeProcessed
        TraceStep("Mode 4 incomplete; creation continues")
    EndIf
    If milkSource != Game.GetPlayer()
        TraceStep("player source changed", True)
        If sexLabRoute
            TraceSexLabStop(13, "player is no longer the stored milk source", True)
        EndIf
        Report(diagnostic, "conversion skipped: player is no longer the milk source")
        Return
    EndIf

    String eligibilityFailure = GetEligibilityFailure(candidate, milkController)
    If eligibilityFailure != ""
        TraceStep(eligibilityFailure, True)
        If sexLabRoute
            TraceSexLabStop(13, eligibilityFailure, True)
        EndIf
        Report(diagnostic, "conversion skipped: " + eligibilityFailure)
        Return
    EndIf
    If milkController.MME_Util_Potions == None
        TraceStep("MME potion list unavailable", True)
        If sexLabRoute
            TraceSexLabStop(13, "MME potion list unavailable", True)
        EndIf
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
        If sexLabRoute
            TraceSexLabStop(13, "MME Lactacid form missing", True)
        EndIf
        Report(diagnostic, "conversion skipped: MME Lactacid form did not resolve")
        Return
    EndIf

    TraceStep("native creation requested")
    If sexLabRoute
        TraceSexLabStop(13, "native Milk Maid creation requested")
    EndIf
    Int beforeCount = candidate.GetItemCount(lactacid)
    candidate.AddItem(lactacid, 1, True)
    Int stagedCount = candidate.GetItemCount(lactacid)
    If stagedCount != beforeCount + 1
        TraceStep("internal Lactacid could not be staged", True)
        If sexLabRoute
            TraceSexLabStop(13, "internal Lactacid could not be staged", True)
        EndIf
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
        If sexLabRoute
            TraceSexLabStop(13, "native Lactacid consumption was blocked", True)
        EndIf
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
        If sexLabRoute
            TraceSexLabStop(14, "native MME effect did not assign a Milk Maid slot", True)
        EndIf
        Report(diagnostic, "conversion failed: native MME effect did not assign a Milk Maid slot")
        Return
    EndIf
    TraceStep("slot confirmed")
    If sexLabRoute
        TraceSexLabStop(14, "Milk Maid slot confirmed")
    EndIf

    ; MilkLactacidScr waits one second after AssignSlotMaid before adding its
    ; first Lactacid point. Observe that final native initialization boundary.
    Int initializationAttempt = 0
    While initializationAttempt < 40 && MME_Storage.getLactacidCurrent(candidate) < 1.0
        Utility.Wait(0.25)
        initializationAttempt += 1
    EndWhile
    If MME_Storage.getLactacidCurrent(candidate) < 1.0
        TraceStep("Lactacid state was not initialized", True)
        If sexLabRoute
            TraceSexLabStop(15, "slot exists but Lactacid state was not initialized", True)
        EndIf
        Report(diagnostic, "conversion incomplete: slot exists but native Lactacid state was not initialized")
        Return
    EndIf

    TraceStep("initialized")
    TraceStep("created")
    If sexLabRoute
        TraceSexLabStop(15, "Lactacid initialized")
        TraceSexLabStop(16, "COMPLETE")
    EndIf
    Report(diagnostic, "canonical MME Lactacid creation effect confirmed for " + GetActorName(candidate))
EndFunction

Bool Function ValidateSexLabRequest(Actor milkSource, Actor candidate) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkSource != Game.GetPlayer() || !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, False) || MME_Storage.getMilkCurrent(milkSource) < 1.0
        TraceSexLabStop(2, "player/source invalid", True)
        Return False
    EndIf
    TraceSexLabStop(2, "player/source valid")

    String eligibilityFailure = GetEligibilityFailure(candidate, milkController)
    If eligibilityFailure != ""
        TraceSexLabStop(3, eligibilityFailure, True)
        Return False
    EndIf
    TraceSexLabStop(3, "candidate eligible")

    If MMEOStimBreastfeeding.IsBreastfeedingEnabled()
        TraceSexLabStop(4, "OStim breastfeeding is ON", True)
        Return False
    EndIf
    TraceSexLabStop(4, "OStim OFF")

    If !MMEAlertsController.IsExtensionsEnabled() || !MMEDebug.IsOriginalMMESexLabBreastfeedingAvailable(milkController)
        TraceSexLabStop(5, "original MME SexLab route unavailable", True)
        Return False
    EndIf
    TraceSexLabStop(5, "original MME SexLab route available")
    Return True
EndFunction

Function RunSexLabBusPreflight(Actor candidate) Global
    TraceSexLabStop(1, "ENTRY | crosshair=" + GetActorIdentity(candidate))
    If ValidateSexLabRequest(Game.GetPlayer(), candidate)
        TraceSexLabMessage("PRE-FLIGHT COMPLETE | select the SexLab New Milk Maid dialogue for stops 06-16")
    EndIf
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

Bool Function IsSexLabTraceEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNewMilkmaidSexLabTrace", 0) == 1
EndFunction

Function TraceSexLabStop(Int stopNumber, String traceText, Bool failed = False) Global
    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service != None
        service.RecordNewMilkMaidSexLabBusStop(stopNumber, traceText, failed)
    EndIf
    If !IsSexLabTraceEnabled()
        Return
    EndIf
    String stopLabel = stopNumber as String
    If stopNumber < 10
        stopLabel = "0" + stopLabel
    EndIf
    String line = "NMM SexLab " + stopLabel + " " + traceText
    If failed
        line = "NMM SexLab " + stopLabel + " FAIL: " + traceText
    EndIf
    Debug.Trace("[MME Extensions New Milkmaid SexLab] " + line)
    ; Rapid one-line notifications overwrite one another. Report grouped route
    ; boundaries in game while preserving every stop in the persistent report
    ; and Papyrus trace.
    If failed || stopNumber == 7 || stopNumber == 9 || stopNumber == 12 || stopNumber == 16
        Debug.Notification(line)
    EndIf
EndFunction

Function TraceSexLabMessage(String traceText) Global
    If IsSexLabTraceEnabled()
        Debug.Trace("[MME Extensions New Milkmaid SexLab] " + traceText)
        Debug.Notification("NMM SexLab: " + traceText)
    EndIf
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
