Scriptname MMEThoughts extends Quest

; Stateless, non-LLM Milk Maid Thought selection and rendering. The established
; controller quest owns scheduling so upgrades work in existing saves where a
; newly attached quest script would not receive a live VM instance.

; Fast visible testing only. The caller must pass the array returned by an
; existing scan; this function never scans and never schedules an update.
Function RunFastDebug(Actor[] alreadyScannedActors) Global
    If !IsExtensionsEnabled()
        ReportFailure("MME Extensions is disabled")
        Return
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkMaidThoughtsDebug", 0) != 1
        ReportFailure("15 Second Thoughts is disabled")
        Return
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "traceMilkMaidThoughtsLogic", 0) == 1
        Int scannedCount = 0
        If alreadyScannedActors != None
            scannedCount = alreadyScannedActors.Length
        EndIf
        Debug.Notification("Thoughts trace: 15-second check fired; scanned " + scannedCount + " actor(s)")
    EndIf
    GenerateAndShowThought(alreadyScannedActors, False)
EndFunction

Bool Function IsExtensionsEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1
EndFunction

Bool Function IsNormalThoughtsEnabled() Global
    Return IsExtensionsEnabled() && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkMaidThoughts", 1) == 1
EndFunction

Bool Function IsDebugEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkMaidThoughtsDebug", 0) == 1
EndFunction

; effectiveRandomness = Min(randomness, baseInterval - 2). Defensive clamps
; preserve the MCM's 2..48 and 0..12 contracts if JSON is edited by hand.
Float Function CalculateNextInterval(Float baseInterval, Float randomness) Global
    If baseInterval < 2.0
        baseInterval = 2.0
    ElseIf baseInterval > 48.0
        baseInterval = 48.0
    EndIf
    If randomness < 0.0
        randomness = 0.0
    ElseIf randomness > 12.0
        randomness = 12.0
    EndIf

    Float effectiveRandomness = randomness
    Float allowedRandomness = baseInterval - 2.0
    If effectiveRandomness > allowedRandomness
        effectiveRandomness = allowedRandomness
    EndIf

    Float nextInterval = baseInterval
    If effectiveRandomness > 0.0
        nextInterval = baseInterval + Utility.RandomFloat(-effectiveRandomness, effectiveRandomness)
    EndIf
    If nextInterval < 2.0
        nextInterval = 2.0
    EndIf
    Return nextInterval
EndFunction

; The one shared normal/debug content pipeline. It performs no gameplay writes:
; one valid actor, one authoritative fullness read, one armor classification,
; one JSON roll, one placeholder render, and one notification.
Bool Function GenerateAndShowThought(Actor[] scannedActors, Bool allowNarration) Global
    If scannedActors == None || scannedActors.Length == 0
        ReportFailure("nearby scan returned no actors")
        Return False
    EndIf
    If !JsonUtil.JsonExists("/MMEAlerts/Thoughts")
        ReportFailure("Thoughts.json is missing (/MMEAlerts/Thoughts)")
        Return False
    EndIf
    If !JsonUtil.IsGood("/MMEAlerts/Thoughts")
        ReportFailure("Thoughts.json failed to parse (/MMEAlerts/Thoughts)")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        ReportFailure("MME_MilkQUEST is unavailable")
        Return False
    EndIf

    ; Count the logical candidate list first, then select its random ordinal in a
    ; second pass. This stays uniform without introducing a fixed-size Papyrus
    ; candidate array or silently truncating a large native result.
    Int validCount = CountValidCandidates(scannedActors, milkController)
    If validCount <= 0
        ReportFailure("scan found " + scannedActors.Length + " actor(s), but none are loaded valid MME Milk Maids")
        Return False
    EndIf
    Actor selectedActor = SelectRandomCandidate(scannedActors, milkController, validCount)
    If selectedActor == None
        ReportFailure("random Milk Maid selection failed after finding " + validCount + " candidate(s)")
        Return False
    EndIf

    Float maximum = MME_Storage.getMilkMaximum(selectedActor)
    If maximum <= 0.0
        ReportFailure(ResolveActorName(selectedActor) + " has invalid maximum milk: " + maximum)
        Return False
    EndIf
    Float current = MME_Storage.getMilkCurrent(selectedActor)
    Bool halfPlus = current >= maximum * 0.5

    Armor wornArmor = selectedActor.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "thought", selectedActor)
    String poolName = GetPoolName(halfPlus, armorClass)
    If poolName == ""
        ReportFailure("unsupported armor class " + armorClass + " for " + ResolveActorName(selectedActor))
        Return False
    EndIf

    ; Thoughts.json is ordinary JSON, not a PapyrusUtil StringList database.
    ; PathStringElements resolves the hand-written array at .<poolName>.
    String[] entries = JsonUtil.PathStringElements("/MMEAlerts/Thoughts", "." + poolName)
    If entries == None || entries.Length == 0
        ReportFailure("Thoughts.json pool is missing or empty: " + poolName)
        Return False
    EndIf
    Int entryIndex = Utility.RandomInt(0, entries.Length - 1)
    String template = entries[entryIndex]
    If template == ""
        ReportFailure("blank Thoughts.json entry in " + poolName + " at index " + entryIndex)
        Return False
    EndIf

    String actorName = ResolveActorName(selectedActor)
    String selectedComment = RenderActorToken(template, actorName)
    If selectedComment == ""
        ReportFailure("{actor} replacement failed in " + poolName + " at index " + entryIndex)
        Return False
    EndIf

    If IsDebugEnabled()
        String fullnessState = "belowHalf"
        If halfPlus
            fullnessState = "halfPlus"
        EndIf
        Debug.Trace("[MMEThoughts] actor=" + actorName + " | current=" + current + " | maximum=" + maximum + " | fullness=" + fullnessState + " | armorClass=" + armorClass + " | pool=" + poolName + " | comment=" + selectedComment)
    EndIf

    Debug.Notification(selectedComment)
    If allowNarration && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMilkMaidThoughtNarration", 1) == 1
        ; Skyrim.Net receives semantic state, not the prewritten HUD line, and
        ; generates its own direct narration. Rapid debug passes False here.
        MMEAlertsSkyrimNet.NarrateMilkMaidThought(selectedActor, halfPlus, armorClass)
    EndIf
    Return True
EndFunction

Int Function CountValidCandidates(Actor[] scannedActors, MilkQUEST milkController) Global
    Int validCount = 0
    Int i = 0
    While i < scannedActors.Length
        If IsValidCandidate(scannedActors[i], milkController)
            validCount += 1
        EndIf
        i += 1
    EndWhile
    Return validCount
EndFunction

Actor Function SelectRandomCandidate(Actor[] scannedActors, MilkQUEST milkController, Int validCount) Global
    If validCount <= 0
        Return None
    EndIf
    Int selectedOrdinal = Utility.RandomInt(0, validCount - 1)
    Int validOrdinal = 0
    Int i = 0
    While i < scannedActors.Length
        Actor candidate = scannedActors[i]
        If IsValidCandidate(candidate, milkController)
            If validOrdinal == selectedOrdinal
                Return candidate
            EndIf
            validOrdinal += 1
        EndIf
        i += 1
    EndWhile
    Return None
EndFunction

Bool Function IsValidCandidate(Actor candidate, MilkQUEST milkController) Global
    If candidate == None || !candidate.Is3DLoaded()
        Return False
    EndIf
    ; Reuse the existing authoritative MME-list validator. It also rejects dead
    ; and disabled actors, while the native scanner supplies loaded nearby refs.
    Return MMEArmorScript.IsValidMilkMaid(candidate, milkController)
EndFunction

String Function GetPoolName(Bool halfPlus, Int armorClass) Global
    If halfPlus
        If armorClass == 0
            Return "halfPlus_noArmor"
        ElseIf armorClass == 1
            Return "halfPlus_milkingArmor"
        ElseIf armorClass == 2
            Return "halfPlus_livingArmor"
        ElseIf armorClass == 3
            Return "halfPlus_parasiteArmor"
        EndIf
    Else
        If armorClass == 0
            Return "belowHalf_noArmor"
        ElseIf armorClass == 1
            Return "belowHalf_milkingArmor"
        ElseIf armorClass == 2
            Return "belowHalf_livingArmor"
        ElseIf armorClass == 3
            Return "belowHalf_parasiteArmor"
        EndIf
    EndIf
    Return ""
EndFunction

String Function ResolveActorName(Actor candidate) Global
    If candidate == None
        Return "The Milk Maid"
    EndIf
    String actorName = candidate.GetDisplayName()
    If actorName == ""
        ActorBase baseActor = candidate.GetLeveledActorBase()
        If baseActor != None
            actorName = baseActor.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "The Milk Maid"
    EndIf
    Return actorName
EndFunction

; Every shipped entry contains exactly one {actor}. Missing placeholders are
; treated as malformed content rather than showing unresolved or unrelated text.
String Function RenderActorToken(String template, String actorName) Global
    Int tokenIndex = StringUtil.Find(template, "{actor}")
    If tokenIndex < 0
        Return ""
    EndIf
    String beforeToken = ""
    If tokenIndex > 0
        beforeToken = StringUtil.Substring(template, 0, tokenIndex)
    EndIf
    String afterToken = StringUtil.Substring(template, tokenIndex + StringUtil.GetLength("{actor}"))
    Return beforeToken + actorName + afterToken
EndFunction

Function TraceDebug(String traceText) Global
    If IsDebugEnabled()
        Debug.Trace("[MMEThoughts] " + traceText)
    EndIf
EndFunction

Function ReportFailure(String reason) Global
    TraceDebug("thought skipped | " + reason)
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "traceMilkMaidThoughtsLogic", 0) == 1
        Debug.Notification("Thoughts trace: " + reason)
    EndIf
EndFunction
