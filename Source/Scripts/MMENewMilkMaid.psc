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
        MMELog.Alarm("[MME Extensions New Milkmaid] FAILURE | persistent breastfeeding service could not resolve")
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
    Bool actionRoute = semanticIntent == "CreateMilkMaidAction"
    If semanticIntent != "CreateMilkMaid" && !sexLabRoute && !actionRoute
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
        MMELog.Alarm("[MME Extensions New Milkmaid] FAILURE | MME potion list is unavailable after a completed breastfeeding scene")
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
        MMELog.Alarm("[MME Extensions New Milkmaid] FAILURE | MME Lactacid form did not resolve after a completed breastfeeding scene")
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
        MMELog.Alarm("[MME Extensions New Milkmaid] FAILURE | internal Lactacid dose could not be staged")
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
        MMELog.Alarm("[MME Extensions New Milkmaid] FAILURE | native Lactacid consumption was blocked; internal dose removed")
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
        MMELog.Alarm("[MME Extensions New Milkmaid] FAILURE | native MME effect did not assign a Milk Maid slot")
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
        MMELog.Alarm("[MME Extensions New Milkmaid] FAILURE | slot exists but native Lactacid state was not initialized")
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

; Skyrim.Net's targeted conversion action deliberately uses MME's original
; dialogue transaction rather than reproducing registration or animation:
; stage one native Lactacid dose, EquipItem it, then let MilkLactacidScr call
; AssignSlotMaid, initialize Lactacid, and run ZaZAPCHorFd for ten seconds.
; OStim and direct breastfeeding reach this same native handoff only after
; their paired scene; this action is the original dialogue's direct route.
Function MakeTargetNewMilkMaid(Actor candidate) Global
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableCreateMilkMaidAction", 1) != 1
        FailAction(candidate, "The Create Milk Maid action is disabled.", False)
        Return
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String failure = GetActionEligibilityFailure(candidate, milkController)
    If failure != ""
        FailAction(candidate, failure, IsUnexpectedActionFailure(failure))
        Return
    EndIf

    ; One global lock closes the race where two AI actions both observe the
    ; final free slot before either native Lactacid effect assigns it. A stale
    ; lock self-heals after load or an interrupted Papyrus stack.
    String lockKey = "MMEExtensions.CreateMilkMaid.ActionLock"
    String lockTimeKey = "MMEExtensions.CreateMilkMaid.ActionLockTime"
    Float now = Utility.GetCurrentRealTime()
    Int lockOwner = StorageUtil.GetIntValue(None, lockKey, 0)
    Float lockedAt = StorageUtil.GetFloatValue(None, lockTimeKey, -1.0)
    If lockOwner == 1 && lockedAt >= 0.0 && now >= lockedAt && now - lockedAt < 60.0
        FailAction(candidate, "Another Milk Maid conversion is already in progress.", False)
        Return
    EndIf
    StorageUtil.SetIntValue(None, lockKey, 1)
    StorageUtil.SetFloatValue(None, lockTimeKey, now)

    ; Revalidate after claiming the lock and before touching the target.
    milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    failure = GetActionEligibilityFailure(candidate, milkController)
    If failure != ""
        ReleaseActionLock(lockKey, lockTimeKey)
        FailAction(candidate, failure, IsUnexpectedActionFailure(failure))
        Return
    EndIf

    MMELog.Diagnostic("[MME Extensions Create Milk Maid] Skyrim.Net action committed | target=" + GetActorIdentity(candidate))
    HandleBreastfeedingCompleted(Game.GetPlayer(), candidate, "CreateMilkMaidAction", False)

    Bool assigned = MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
    Bool initialized = assigned && MME_Storage.getLactacidCurrent(candidate) >= 1.0
    ReleaseActionLock(lockKey, lockTimeKey)
    If assigned && initialized
        Debug.Notification(GetActorName(candidate) + " is now a Milk Maid.")
        MMELog.Diagnostic("[MME Extensions Create Milk Maid] COMPLETE | target=" + GetActorIdentity(candidate))
    ElseIf assigned
        ; Roll back through MME's own complete single-actor reset. Never edit
        ; its array, faction, body nodes, or StorageUtil state independently.
        milkController.SingleMaidReset(candidate)
        Utility.Wait(0.1)
        If MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
            FailAction(candidate, "MME assigned a partial Milk Maid state and its native rollback failed. Check the Papyrus log.", True)
        Else
            FailAction(candidate, "MME did not initialize Lactacid; its partial conversion was rolled back.", True)
        EndIf
    Else
        FailAction(candidate, "MME did not assign a Milk Maid slot. Its capacity may be too low or its registry may be full. Check the Papyrus log.", True)
    EndIf
EndFunction

; Returns a player-facing failure, with no writes. Do not inspect MilkMaid[]
; here: MME 2022 exposes that auto-property as None to some external scripts,
; even while MilkLactacidScr and AssignSlotMaid use the live array internally.
; MME's native Lactacid effect owns the exact Find(None, 1) slot/capacity check;
; this adapter verifies the public faction/StorageUtil postcondition afterward.
String Function GetActionEligibilityFailure(Actor candidate, MilkQUEST milkController) Global
    If candidate == None
        Return "No target NPC was selected."
    ElseIf candidate == Game.GetPlayer()
        Return "The target must be a female NPC, not the player."
    ElseIf candidate.IsChild()
        Return "The target is a child and cannot become a Milk Maid."
    EndIf
    ActorBase candidateBase = candidate.GetLeveledActorBase()
    If candidateBase == None
        Return "The target's actor data is unavailable."
    ElseIf candidateBase.GetSex() != 1
        Return "The target is male; only female NPCs are supported."
    ElseIf candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        Return "The target must be alive, enabled, and currently loaded."
    EndIf
    If milkController == None || !milkController.IsRunning()
        Return "The required MME Milk Quest is unavailable or not running."
    ElseIf MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
        Return "The target is already a Milk Maid."
    ElseIf MMEArmorScript.IsMMEMilkSlave(candidate, milkController)
        Return "The target is a Milk Slave and cannot be converted directly."
    ElseIf milkController.MilkQC == None
        Return "Required MME quest condition data is unavailable."
    ElseIf milkController.MilkMaidFaction == None
        Return "The required MME Milk Maid faction property is unavailable."
    ElseIf milkController.MME_Util_Potions == None
        Return "The required MME potion data is unavailable."
    ElseIf Game.GetModByName("ZaZAnimationPack.esm") == 255
        Return "The required ZaZ animation dependency is unavailable."
    EndIf

    Potion lactacid = milkController.MME_Util_Potions.GetAt(0) as Potion
    If lactacid == None || lactacid.GetNthEffectMagicEffect(0) == None
        Return "The required MME Lactacid conversion effect is unavailable."
    ElseIf milkController.SexLab == None
        Return "MME's SexLab animation dependency is unavailable."
    ElseIf candidate.IsInCombat()
        Return "The target is in combat."
    ElseIf candidate.IsOnMount()
        Return "The target is mounted."
    ElseIf MMEOStimIntegration.IsActorBusy(candidate)
        Return "The target is already in an animation scene."
    ElseIf MMEAlertsController.IsFreeArmAnimationBlocked(candidate)
        Return "The target's restraints prevent the required animation."
    EndIf
    Int sitState = candidate.GetSitState()
    If sitState > 0 && sitState <= 3
        Return "The target must be standing for the conversion animation."
    EndIf

    Return ""
EndFunction

Bool Function IsUnexpectedActionFailure(String failure) Global
    Return StringUtil.Find(failure, "unavailable") >= 0 || StringUtil.Find(failure, "did not") >= 0
EndFunction

Function ReleaseActionLock(String lockKey, String lockTimeKey) Global
    StorageUtil.UnsetIntValue(None, lockKey)
    StorageUtil.UnsetFloatValue(None, lockTimeKey)
EndFunction

Function FailAction(Actor candidate, String failure, Bool unexpected) Global
    Debug.Notification("Create Milk Maid: " + failure)
    String detail = failure + " | target=" + GetActorIdentity(candidate)
    If unexpected
        MMELog.Alarm("[MME Extensions Create Milk Maid] FAILURE | " + detail)
    Else
        MMELog.Diagnostic("[MME Extensions Create Milk Maid] rejected | " + detail)
    EndIf
EndFunction

Bool Function ValidateSexLabRequest(Actor milkSource, Actor candidate) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkSource != Game.GetPlayer() || !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, False) || MME_Storage.getMilkCurrent(milkSource) < 1.0
        TraceSexLabStop(2, "player/source is not currently eligible", False, True)
        Return False
    EndIf
    TraceSexLabStop(2, "player/source valid")

    String eligibilityFailure = GetEligibilityFailure(candidate, milkController)
    If eligibilityFailure != ""
        TraceSexLabStop(3, eligibilityFailure, False, True)
        Return False
    EndIf
    TraceSexLabStop(3, "candidate eligible")

    If MMEOStimBreastfeeding.IsBreastfeedingEnabled()
        TraceSexLabStop(4, "SexLab route not applicable while OStim breastfeeding is ON", False, True)
        Return False
    EndIf
    TraceSexLabStop(4, "OStim OFF")

    If !MMEAlertsController.IsExtensionsEnabled() || !MMEDebug.IsOriginalMMESexLabBreastfeedingAvailable(milkController)
        TraceSexLabStop(5, "original MME SexLab route is not currently available", False, True)
        Return False
    EndIf
    Return ValidateDialoguePresentation(candidate, False)
EndFunction

Bool Function ValidateOStimBusRequest(Actor milkSource, Actor candidate) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkSource != Game.GetPlayer() || !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, False) || MME_Storage.getMilkCurrent(milkSource) < 1.0
        TraceSexLabStop(2, "backend=OStim | player/source is not currently eligible", False, True)
        Return False
    EndIf
    TraceSexLabStop(2, "backend=OStim | player/source valid")

    String eligibilityFailure = GetEligibilityFailure(candidate, milkController)
    If eligibilityFailure != ""
        TraceSexLabStop(3, "backend=OStim | " + eligibilityFailure, False, True)
        Return False
    EndIf
    TraceSexLabStop(3, "backend=OStim | candidate eligible")

    If !MMEOStimBreastfeeding.IsBreastfeedingEnabled()
        TraceSexLabStop(4, "backend=OStim | OStim breastfeeding is OFF", False, True)
        Return False
    EndIf
    TraceSexLabStop(4, "backend=OStim | OStim breastfeeding is ON")

    GlobalVariable dialogueGate = MMEAlertsController.GetOStimDialogueAvailabilityGlobal()
    If dialogueGate == None || dialogueGate.GetValue() < 1.0
        TraceSexLabStop(5, "backend=OStim | dialogue gate is missing or closed", True)
        MMELog.Alarm("[MME Extensions New Milkmaid] ROUTE CLOG | OStim enabled but its dialogue gate is missing or closed")
        Return False
    EndIf
    Return ValidateDialoguePresentation(candidate, True)
EndFunction

Bool Function ValidateDialoguePresentation(Actor candidate, Bool ostimRoute) Global
    String backend = "SexLab"
    String infoEditorID = "MMEExt_SexLabNewMilkMaid"
    If ostimRoute
        backend = "OStim"
        infoEditorID = "MMEExt_NewMilkMaid"
    EndIf

    Form dialogueInfo = MMEExtensionsNative.GetFormByEditorID(infoEditorID)
    If dialogueInfo == None
        TraceSexLabStop(5, "backend=" + backend + " | live INFO did not resolve", True)
        MMELog.Alarm("[MME Extensions New Milkmaid] ROUTE CLOG | " + backend + " INFO did not resolve in Skyrim's loaded dialogue graph")
        Return False
    EndIf

    Form parentTopic = MMEExtensionsNative.GetParentTopic(dialogueInfo)
    If parentTopic == None
        TraceSexLabStop(5, "backend=" + backend + " | live INFO has no parent topic", True)
        MMELog.Alarm("[MME Extensions New Milkmaid] ROUTE CLOG | " + backend + " INFO has no live parent topic")
        Return False
    EndIf

    Form[] loadedInfos = MMEExtensionsNative.GetTopicInfos(parentTopic)
    Bool infoListed = False
    Int infoIndex = 0
    While infoIndex < loadedInfos.Length && !infoListed
        infoListed = loadedInfos[infoIndex] == dialogueInfo
        infoIndex += 1
    EndWhile
    If !infoListed
        TraceSexLabStop(5, "backend=" + backend + " | parent topic omitted the INFO", True)
        MMELog.Alarm("[MME Extensions New Milkmaid] ROUTE CLOG | " + backend + " parent topic omitted its INFO from the loaded response list")
        Return False
    EndIf

    If !MMEExtensionsNative.EvaluateTopicInfo(dialogueInfo, candidate, Game.GetPlayer())
        TraceSexLabStop(5, "backend=" + backend + " | Skyrim rejected the live INFO conditions", True)
        MMELog.Alarm("[MME Extensions New Milkmaid] ROUTE CLOG | " + backend + " eligibility passed but Skyrim rejected the live INFO conditions")
        Return False
    EndIf

    TraceSexLabStop(5, "backend=" + backend + " | live INFO loaded, linked, and condition-valid; select the dialogue for stops 06-16")
    Return True
EndFunction

Function RunSexLabBusPreflight(Actor candidate) Global
    TraceSexLabStop(1, "ENTRY | crosshair=" + GetActorIdentity(candidate))
    If ValidateSexLabRequest(Game.GetPlayer(), candidate)
        TraceSexLabMessage("PRE-FLIGHT COMPLETE | select the SexLab New Milk Maid dialogue for stops 06-16")
    EndIf
EndFunction

Function RunOStimBusPreflight(Actor candidate) Global
    TraceSexLabStop(1, "ENTRY | backend=OStim | crosshair=" + GetActorIdentity(candidate))
    ValidateOStimBusRequest(Game.GetPlayer(), candidate)
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
    ; Extensions deliberately supports female Milk Maid conversion only. MME's
    ; optional MaleMaids setting must not broaden this dialogue route.
    If candidateSex != 1
        Return "target is not female; male Milk Maid conversion is unsupported"
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

Function TraceSexLabStop(Int stopNumber, String traceText, Bool failed = False, Bool blocked = False) Global
    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service != None
        service.RecordNewMilkMaidSexLabBusStop(stopNumber, traceText, failed, blocked)
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
    ElseIf blocked
        line = "NMM SexLab " + stopLabel + " BLOCKED: " + traceText
    EndIf
    MMELog.Diagnostic("[MME Extensions New Milkmaid SexLab] " + line)
    ; Rapid one-line notifications overwrite one another. Report grouped route
    ; boundaries in game while preserving every stop in the persistent report
    ; and Papyrus trace.
    If failed || blocked || stopNumber == 7 || stopNumber == 9 || stopNumber == 12 || stopNumber == 16
        Debug.Notification(line)
    EndIf
EndFunction

Function TraceSexLabMessage(String traceText) Global
    If IsSexLabTraceEnabled()
        MMELog.Diagnostic("[MME Extensions New Milkmaid SexLab] " + traceText)
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
    MMELog.Diagnostic("[MME Extensions New Milkmaid] " + line)
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
    MMELog.Diagnostic("[MME Extensions New Milk Maid] " + reportText)
    If showNotification
        Debug.Notification("New Milk Maid: " + reportText)
    EndIf
EndFunction
