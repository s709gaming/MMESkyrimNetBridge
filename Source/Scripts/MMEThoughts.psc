Scriptname MMEThoughts extends Quest

; Lightweight, non-LLM ambient Milk Maid observations. Normal scheduling uses
; game-time hours and is deliberately separate from the controller's real-time
; deadline scheduler. Rapid debug calls enter through RunFastDebug with the
; controller's already-scanned actor array.

String SettingsFile = "/MMEAlerts/Settings"
String ThoughtsFile = "/MMEAlerts/Thoughts"
Float NearbyRange = 2000.0

Event OnInit()
    UpdateSchedule()
EndEvent

; Replaces the one pending game-time registration. Calling this repeatedly is
; safe because unregister happens before every optional re-registration.
Function UpdateSchedule()
    UnregisterForUpdateGameTime()
    If !IsNormalThoughtsEnabled()
        TraceDebug("normal schedule disabled")
        Return
    EndIf

    Float baseInterval = JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsInterval", 12.0)
    Float randomness = JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsRandomness", 4.0)
    Float nextInterval = CalculateNextInterval(baseInterval, randomness)
    RegisterForSingleUpdateGameTime(nextInterval)
    TraceDebug("normal schedule armed | next=" + nextInterval + " game hours")
EndFunction

; A single update consumes its registration. Poll first, then calculate and arm
; a fresh randomized interval even when no valid actor or JSON line is found.
Event OnUpdateGameTime()
    If IsNormalThoughtsEnabled()
        Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(NearbyRange)
        GenerateAndShowThought(nearbyActors, True)
    EndIf
    UpdateSchedule()
EndEvent

; Fast visible testing only. The caller must pass the array returned by an
; existing scan; this function never scans and never schedules an update.
Function RunFastDebug(Actor[] alreadyScannedActors)
    If !IsExtensionsEnabled() || JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0) != 1
        Return
    EndIf
    GenerateAndShowThought(alreadyScannedActors, False)
EndFunction

Bool Function IsExtensionsEnabled()
    Return JsonUtil.GetIntValue(SettingsFile, "enableMMEExtensions", 1) == 1
EndFunction

Bool Function IsNormalThoughtsEnabled()
    Return IsExtensionsEnabled() && JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughts", 1) == 1
EndFunction

Bool Function IsDebugEnabled()
    Return JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0) == 1
EndFunction

; effectiveRandomness = Min(randomness, baseInterval - 2). Defensive clamps
; preserve the MCM's 2..48 and 0..12 contracts if JSON is edited by hand.
Float Function CalculateNextInterval(Float baseInterval, Float randomness)
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
Bool Function GenerateAndShowThought(Actor[] scannedActors, Bool allowMirror)
    If scannedActors == None || scannedActors.Length == 0
        TraceDebug("thought skipped | nearby actor array empty")
        Return False
    EndIf
    If !JsonUtil.JsonExists(ThoughtsFile)
        TraceDebug("thought skipped | JSON file missing=" + ThoughtsFile)
        Return False
    EndIf
    If !JsonUtil.IsGood(ThoughtsFile)
        TraceDebug("thought skipped | JSON file failed to parse=" + ThoughtsFile)
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        TraceDebug("thought skipped | MME controller unavailable")
        Return False
    EndIf

    ; Count the logical candidate list first, then select its random ordinal in a
    ; second pass. This stays uniform without introducing a fixed-size Papyrus
    ; candidate array or silently truncating a large native result.
    Int validCount = CountValidCandidates(scannedActors, milkController)
    If validCount <= 0
        TraceDebug("thought skipped | no valid nearby Milk Maids")
        Return False
    EndIf
    Actor selectedActor = SelectRandomCandidate(scannedActors, milkController, validCount)
    If selectedActor == None
        TraceDebug("thought skipped | random candidate did not resolve")
        Return False
    EndIf

    Float maximum = MME_Storage.getMilkMaximum(selectedActor)
    If maximum <= 0.0
        TraceDebug("thought skipped | actor=" + ResolveActorName(selectedActor) + " | invalid maximum=" + maximum)
        Return False
    EndIf
    Float current = MME_Storage.getMilkCurrent(selectedActor)
    Bool halfPlus = current >= maximum * 0.5

    Armor wornArmor = selectedActor.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "thought", selectedActor)
    String poolName = GetPoolName(halfPlus, armorClass)
    If poolName == ""
        TraceDebug("thought skipped | unsupported armor class=" + armorClass)
        Return False
    EndIf

    Int entryCount = JsonUtil.StringListCount(ThoughtsFile, poolName)
    If entryCount <= 0
        TraceDebug("thought skipped | JSON pool missing or empty=" + poolName)
        Return False
    EndIf
    Int entryIndex = Utility.RandomInt(0, entryCount - 1)
    String template = JsonUtil.StringListGet(ThoughtsFile, poolName, entryIndex)
    If template == ""
        TraceDebug("thought skipped | invalid JSON value | pool=" + poolName + " | index=" + entryIndex)
        Return False
    EndIf

    String actorName = ResolveActorName(selectedActor)
    String selectedComment = RenderActorToken(template, actorName)
    If selectedComment == ""
        TraceDebug("thought skipped | actor placeholder replacement failed | pool=" + poolName + " | index=" + entryIndex)
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
    If allowMirror && JsonUtil.GetIntValue(SettingsFile, "mirrorMilkMaidThoughtsToSkyrimNet", 1) == 1
        ; The already-resolved string is the only payload. Skyrim.Net never rolls
        ; or renders a second line, and its helper safely gates API availability.
        MMEAlertsSkyrimNet.SendMilkMaidThought(selectedActor, selectedComment)
    EndIf
    Return True
EndFunction

Int Function CountValidCandidates(Actor[] scannedActors, MilkQUEST milkController)
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

Actor Function SelectRandomCandidate(Actor[] scannedActors, MilkQUEST milkController, Int validCount)
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

Bool Function IsValidCandidate(Actor candidate, MilkQUEST milkController)
    If candidate == None || !candidate.Is3DLoaded()
        Return False
    EndIf
    ; Reuse the existing authoritative MME-list validator. It also rejects dead
    ; and disabled actors, while the native scanner supplies loaded nearby refs.
    Return MMEArmorScript.IsValidMilkMaid(candidate, milkController)
EndFunction

String Function GetPoolName(Bool halfPlus, Int armorClass)
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

String Function ResolveActorName(Actor candidate)
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
String Function RenderActorToken(String template, String actorName)
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

Function TraceDebug(String traceText)
    If IsDebugEnabled()
        Debug.Trace("[MMEThoughts] " + traceText)
    EndIf
EndFunction
