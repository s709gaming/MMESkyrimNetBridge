Scriptname MMEDebug extends Quest

; Persistent shared OStim breastfeeding service. Dialogue INFO fragments and
; Skyrim.Net both call this one quest-owned session implementation.
String SettingsFile = "/MMEAlerts/Settings"

; ---------------------------------------------------------------------------
; OStim breastfeeding session ownership
; ---------------------------------------------------------------------------
; This persistent quest script is the complete OStim lane. It intentionally does not
; replace, override, or call through MME's original SexLab dialogue INFOs.
; One script instance owns at most one manual OStim thread and one matching MME
; Mode 4 milking request. The fields below are a small transaction record used
; to prove ownership before stopping a scene or removing MME's passive state.
Int ActiveThreadID = -1
String ActiveSceneID = ""
Actor ActiveMilkSource = None
Actor ActiveDrinker = None
Spell ActivePassiveSpell = None
Bool ActiveSession = False
Bool ActiveOwnsThread = False
Bool ActiveMMERequested = False
Bool ActiveMMEStarted = False
Bool ActiveMMECompleted = False
Bool ActiveLaunching = False
Bool ActiveDiagnostic = False
Bool ActiveIncludesPlayer = False
Int AttemptSequence = 0
Int ActiveSessionID = 0
String ActiveCaller = ""
String ActiveSemanticIntent = ""

; SexLab uses short-lived, actor-scoped startup locks. SexLab's own active
; state becomes authoritative as soon as StartThread succeeds.
String SexLabLockKey = "MME.Extensions.SexLabBreastfeeding.Lock"
String SexLabLockTimeKey = "MME.Extensions.SexLabBreastfeeding.LockTime"
String SexLabRoleKey = "MME.Extensions.SexLabBreastfeeding.Role"
String SexLabThreadKey = "MME.Extensions.SexLabBreastfeeding.Thread"
Int SexLabAttemptSequence = 0

; A special SexLab request carries a persistent, exact transaction identity.
; Ordinary breastfeeding never populates these fields and therefore cannot
; reach the Milk Maid conversion callback.
Int ActiveSexLabIntentThreadID = -1
Actor ActiveSexLabIntentSource = None
Actor ActiveSexLabIntentDrinker = None
String ActiveSexLabSemanticIntent = ""
Bool ActiveSexLabMMEStarted = False
Int ActiveSexLabIntentRequestID = 0
Float SexLabIntentClaimTimeout = 30.0

; Persistent route report. Unlike transient notifications, these fields survive
; long scenes and can be read from Troubleshoot after the animation finishes.
Int LastNewMilkMaidSexLabBusStop = 0
String LastNewMilkMaidSexLabBusState = "IDLE"
String LastNewMilkMaidSexLabBusMessage = "No SexLab New Milk Maid test has run"
String LastNewMilkMaidSexLabBusFailure = "none"
Int LastNewMilkMaidSexLabBusThreadID = -1

; Quest startup delegates normal scheduling to the controller.
Event OnInit()
    EnsureNewMilkMaidSexLabListeners()
    UpdateDebugLoop()
EndEvent

Function UpdateDebugLoop()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.UpdatePolling()
    EndIf
EndFunction

; Save/load can restore Papyrus fields after OStim's runtime thread has ended.
; Resume only an exact owned transaction; otherwise discard our bookkeeping
; without stopping a thread or removing a spell we can no longer prove we own.
Function RecoverAfterLoad()
    EnsureNewMilkMaidSexLabListeners()
    RecoverSexLabIntentAfterLoad()
    If !ActiveSession
        Return
    EndIf
    UnregisterSessionEvents()
    If StillOwnsThread()
        If ActiveMMEStarted && (ActivePassiveSpell == None || ActiveMilkSource == None || !ActiveMilkSource.HasSpell(ActivePassiveSpell))
            ActiveMMEStarted = False
            ActiveMMECompleted = True
        EndIf
        ActiveLaunching = False
        RegisterSessionEvents()
        RequestWatchdog()
        TraceActive("resumed owned OStim breastfeeding session after load")
    Else
        EndSession("discarded stale state after load without touching external OStim/MME state")
    EndIf
EndFunction

Bool Function StartSexLabBreastfeeding(Actor milkSource, Actor drinker, String caller = "Unknown")
    SexLabAttemptSequence += 1
    Int requestID = SexLabAttemptSequence
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0) == 1
    If caller == "Skyrim.Net"
        diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", 0) == 1
    EndIf
    SexLabTrace(requestID, diagnostic, "REQUEST RECEIVED | ENTRY ROUTE=" + caller + " | source=" + GetActorName(milkSource) + " " + milkSource + " | drinker=" + GetActorName(drinker) + " " + drinker)

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String failure = SexLabPairFailure(milkSource, drinker, milkController)
    If failure != ""
        SexLabTrace(requestID, diagnostic, "INITIAL VALIDATION FAIL: " + failure)
        Return False
    EndIf
    SexLabTrace(requestID, diagnostic, "INITIAL VALIDATION PASS")

    If !AcquireSexLabActor(milkSource, requestID)
        SexLabTrace(requestID, diagnostic, "ACTOR ACQUIRE FAIL: source owned by request #" + StorageUtil.GetIntValue(milkSource, SexLabLockKey, 0))
        Return False
    EndIf
    If !AcquireSexLabActor(drinker, requestID)
        ReleaseSexLabActor(milkSource, requestID)
        SexLabTrace(requestID, diagnostic, "ACTOR ACQUIRE FAIL: drinker owned by request #" + StorageUtil.GetIntValue(drinker, SexLabLockKey, 0) + " | source released")
        Return False
    EndIf
    SexLabTrace(requestID, diagnostic, "ACTOR ACQUIRE PASS")

    failure = SexLabPairFailure(milkSource, drinker, milkController)
    If failure != ""
        ReleaseSexLabPair(milkSource, drinker, requestID)
        SexLabTrace(requestID, diagnostic, "PRE-COMMIT VALIDATION FAIL: " + failure + " | actors released")
        Return False
    EndIf
    SexLabTrace(requestID, diagnostic, "PRE-COMMIT VALIDATION PASS | SEXLAB AVAILABLE")

    ActorBase drinkerBase = drinker.GetLeveledActorBase()
    String animationName = "zjBreastFeeding"
    If drinkerBase != None && drinkerBase.GetSex() == 0
        animationName = "zjBreastFeedingVar"
    EndIf
    sslBaseAnimation animation = milkController.SexLab.AnimSlots.GetbyRegistrar(animationName)
    If animation == None
        ReleaseSexLabPair(milkSource, drinker, requestID)
        SexLabTrace(requestID, diagnostic, "FAIL: no compatible animation selected | registrar=" + animationName + " | actors released")
        Return False
    EndIf
    sslBaseAnimation[] animations = new sslBaseAnimation[1]
    animations[0] = animation
    SexLabTrace(requestID, diagnostic, "ANIMATION SELECTED | registrar=" + animationName + " | animation=" + animation)

    sslThreadModel model = milkController.SexLab.NewThread()
    If model == None
        ReleaseSexLabPair(milkSource, drinker, requestID)
        SexLabTrace(requestID, diagnostic, "FAIL: SexLab NewThread returned None | actors released")
        Return False
    EndIf
    SexLabTrace(requestID, diagnostic, "THREAD CREATED | model=" + model)
    If model.AddActor(milkSource) < 0
        model.Initialize()
        ReleaseSexLabPair(milkSource, drinker, requestID)
        SexLabTrace(requestID, diagnostic, "FAIL: source AddActor rejected | actors released | SexLab slot initialized")
        Return False
    EndIf
    SexLabTrace(requestID, diagnostic, "SOURCE ADDED")
    If model.AddActor(drinker) < 0
        model.Initialize()
        ReleaseSexLabPair(milkSource, drinker, requestID)
        SexLabTrace(requestID, diagnostic, "FAIL: drinker AddActor rejected | actors released | SexLab slot initialized")
        Return False
    EndIf
    SexLabTrace(requestID, diagnostic, "DRINKER ADDED")
    model.SetAnimations(animations)
    model.SetHook("MMEExtensionsBreastfeeding")
    SexLabTrace(requestID, diagnostic, "SEXLAB START REQUESTED")
    sslThreadController thread = model.StartThread()
    If thread == None
        model.Initialize()
        ReleaseSexLabPair(milkSource, drinker, requestID)
        SexLabTrace(requestID, diagnostic, "FAIL: SexLab StartThread returned None | actors released | SexLab slot initialized")
        Return False
    EndIf
    Int threadID = model.tid
    SexLabTrace(requestID, diagnostic, "SEXLAB START REQUESTED | thread=" + threadID)

    Int checks = 0
    While checks < 20 && (!milkController.SexLab.IsActorActive(milkSource) || !milkController.SexLab.IsActorActive(drinker))
        Utility.Wait(0.1)
        checks += 1
    EndWhile
    If !milkController.SexLab.IsActorActive(milkSource) || !milkController.SexLab.IsActorActive(drinker)
        thread.EndAnimation(True)
        ReleaseSexLabPair(milkSource, drinker, requestID)
        SexLabTrace(requestID, diagnostic, "FAIL: SexLab startup not confirmed | thread=" + threadID + " | owned thread ended | actors released")
        Return False
    EndIf
    ReleaseSexLabPair(milkSource, drinker, requestID)
    SexLabTrace(requestID, diagnostic, "SEXLAB START CONFIRMED | SESSION ACTIVE | thread=" + threadID + " | startup locks released")
    MMEAlertsSkyrimNet.SetBreastfeedingPromptState(milkSource, "source", threadID)
    MMEAlertsSkyrimNet.SetBreastfeedingPromptState(drinker, "drinker", threadID)
    Spell passive = milkController.BeingMilkedPassive
    checks = 0
    While checks < 30 && passive != None && !milkSource.HasSpell(passive)
        Utility.Wait(0.1)
        checks += 1
    EndWhile
    If passive != None && milkSource.HasSpell(passive)
        SexLabTrace(requestID, diagnostic, "MME START CONFIRMED | Mode4 passive active")
    Else
        SexLabTrace(requestID, diagnostic, "FAIL: MME Mode4 did not begin after SexLab startup | thread=" + threadID)
    EndIf
    Return True
EndFunction

; Two-phase semantic ownership for the dedicated New Milk Maid INFO. The INFO
; arms this persistent quest and calls MME_Dialogues.Fragment_02. SexLab's
; AnimationEnding event is the last boundary where the completed thread still
; exposes its ordered actors and animation, so ownership is claimed there.
Bool Function ArmMMENewMilkMaidSexLab(Actor milkSource, Actor drinker)
    EnsureNewMilkMaidSexLabListeners()
    SexLabAttemptSequence += 1
    Int requestID = SexLabAttemptSequence
    If ActiveSexLabSemanticIntent != ""
        If SexLabIntentStillOwned()
            MMENewMilkMaid.TraceSexLabStop(6, "another semantic SexLab transaction owns thread " + ActiveSexLabIntentThreadID, True)
            Return False
        EndIf
        ClearSexLabIntent()
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String failure = SexLabPairFailure(milkSource, drinker, milkController)
    If failure != ""
        MMENewMilkMaid.TraceSexLabStop(6, failure, True)
        Return False
    EndIf
    If !IsOriginalMMESexLabBreastfeedingAvailable(milkController)
        MMENewMilkMaid.TraceSexLabStop(6, "MME breastfeeding registrars unavailable", True)
        Return False
    EndIf
    If !AcquireSexLabActor(milkSource, requestID)
        MMENewMilkMaid.TraceSexLabStop(6, "player/source startup lock unavailable", True)
        Return False
    EndIf
    If !AcquireSexLabActor(drinker, requestID)
        ReleaseSexLabActor(milkSource, requestID)
        MMENewMilkMaid.TraceSexLabStop(6, "candidate startup lock unavailable", True)
        Return False
    EndIf

    ActiveSexLabIntentThreadID = -1
    ActiveSexLabIntentSource = milkSource
    ActiveSexLabIntentDrinker = drinker
    ActiveSexLabSemanticIntent = "CreateMilkMaidSexLab"
    ActiveSexLabMMEStarted = False
    ActiveSexLabIntentRequestID = requestID
    SendModEvent("MMEExtensionsNewMilkMaidSexLabTimeout", requestID as String)
    MMENewMilkMaid.TraceSexLabStop(6, "CreateMilkMaid intent armed")
    Return True
EndFunction

; A custom event creates an independent timeout stack without borrowing this
; quest form's OnUpdate scheduler, which is shared with MMEAlertsController.
Event OnNewMilkMaidSexLabTimeout(String eventName, String requestIDText, Float numArg, Form sender)
    Int requestID = requestIDText as Int
    Utility.WaitMenuMode(SexLabIntentClaimTimeout)
    If ActiveSexLabSemanticIntent == "CreateMilkMaidSexLab" && ActiveSexLabIntentThreadID < 0 && ActiveSexLabIntentRequestID == requestID
        MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
        If milkController != None && milkController.SexLab != None && ActiveSexLabIntentSource != None && ActiveSexLabIntentDrinker != None && milkController.SexLab.IsActorActive(ActiveSexLabIntentSource) && milkController.SexLab.IsActorActive(ActiveSexLabIntentDrinker)
            ; SexLab scenes can be user-extended. Keep the intent alive while the
            ; exact expected pair remains active, then check again later.
            SendModEvent("MMEExtensionsNewMilkMaidSexLabTimeout", requestID as String)
        Else
            MMENewMilkMaid.TraceSexLabStop(8, "matching MME breastfeeding scene never reached AnimationEnding", True)
            ClearSexLabIntent()
        EndIf
    EndIf
EndEvent

; Claim only the exact MME-started scene at the final event before SexLab resets
; Positions. Nonmatching scenes cannot consume or cancel the armed request.
Event OnNewMilkMaidSexLabEnding(String eventName, String threadIDText, Float numArg, Form sender)
    Int threadID = threadIDText as Int
    If threadID < 0
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.SexLab == None
        Return
    EndIf
    ; SexLab sends this event from the live thread controller itself. Prefer the
    ; sender so claim does not depend on a registry lookup during teardown.
    sslThreadController thread = sender as sslThreadController
    If thread == None
        thread = milkController.SexLab.GetController(threadID)
    EndIf
    If thread == None
        Return
    EndIf
    Actor[] positions = thread.Positions
    If positions == None || positions.Length < 2
        Return
    EndIf
    If ActiveSexLabSemanticIntent == "CreateMilkMaidSexLab" && ActiveSexLabIntentThreadID < 0 && ActiveSexLabIntentSource != None && ActiveSexLabIntentDrinker != None
        Actor milkSource = ActiveSexLabIntentSource
        Actor drinker = ActiveSexLabIntentDrinker
        If positions[0] == milkSource && positions[1] == drinker
            sslBaseAnimation straightAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar")
            sslBaseAnimation lesbianAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding")
            If thread.Animation == straightAnimation || thread.Animation == lesbianAnimation || thread.HasTag("Breastfeeding")
                Int requestID = ActiveSexLabIntentRequestID
                ActiveSexLabIntentThreadID = threadID
                ReleaseSexLabPair(milkSource, drinker, requestID)
                ActiveSexLabIntentRequestID = 0
                MMEAlertsSkyrimNet.SetBreastfeedingPromptState(milkSource, "source", ActiveSexLabIntentThreadID)
                MMEAlertsSkyrimNet.SetBreastfeedingPromptState(drinker, "drinker", ActiveSexLabIntentThreadID)
                LastNewMilkMaidSexLabBusThreadID = threadID
                MMENewMilkMaid.TraceSexLabStop(8, "AnimationEnding claimed | thread=" + ActiveSexLabIntentThreadID)
                MMENewMilkMaid.TraceSexLabStop(9, "source/drinker and breastfeeding animation confirmed")
                ObserveNewMilkMaidSexLabMode4(milkController)
            EndIf
        EndIf
    EndIf

    ; Ordinary breastfeeding role cleanup also belongs here because Positions
    ; are deliberately unavailable by AnimationEnd in SexLab 1.66b.
    Actor ordinaryDrinker = None
    Int index = 0
    While index < positions.Length
        Actor participant = positions[index]
        If participant != None && StorageUtil.GetStringValue(participant, SexLabRoleKey, "") == "drinker" && StorageUtil.GetIntValue(participant, SexLabThreadKey, -1) == threadID
            ordinaryDrinker = participant
        EndIf
        MMEAlertsSkyrimNet.ClearBreastfeedingPromptState(participant, threadID)
        index += 1
    EndWhile
    If ordinaryDrinker != None
        ApplyBreastfeedingDrinkEffects(ordinaryDrinker)
    EndIf
EndEvent

Function ObserveNewMilkMaidSexLabMode4(MilkQUEST milkController)
    If ActiveSexLabMMEStarted || milkController == None || ActiveSexLabIntentSource == None
        Return
    EndIf
    Spell passive = milkController.BeingMilkedPassive
    If passive != None && ActiveSexLabIntentSource.HasSpell(passive)
        ActiveSexLabMMEStarted = True
        MMENewMilkMaid.TraceSexLabStop(10, "MME Mode 4 observed")
    EndIf
EndFunction

; The original MME dialogue fragment remains the known-good owner of its
; StartSex call. Observe its result without replacing or invoking it again.
Function ObserveDialogueSexLabBreastfeeding(Actor milkSource, Actor drinker)
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0) == 1
    SexLabAttemptSequence += 1
    Int requestID = SexLabAttemptSequence
    SexLabTrace(requestID, diagnostic, "REQUEST RECEIVED | ENTRY ROUTE=DIALOGUE | source=" + GetActorName(milkSource) + " " + milkSource + " | drinker=" + GetActorName(drinker) + " " + drinker)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkSource == None || drinker == None
        SexLabTrace(requestID, diagnostic, "FAIL: dialogue source or drinker did not resolve")
        Return
    ElseIf milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None
        SexLabTrace(requestID, diagnostic, "FAIL: MME/SexLab framework unavailable")
        Return
    EndIf
    SexLabTrace(requestID, diagnostic, "SOURCE RESOLVED | DRINKER RESOLVED | SEXLAB AVAILABLE")
    String animationName = "zjBreastFeeding"
    ActorBase drinkerBase = drinker.GetLeveledActorBase()
    If drinkerBase != None && drinkerBase.GetSex() == 0
        animationName = "zjBreastFeedingVar"
    EndIf
    sslBaseAnimation animation = milkController.SexLab.AnimSlots.GetbyRegistrar(animationName)
    If animation == None
        SexLabTrace(requestID, diagnostic, "FAIL: no compatible animation selected | registrar=" + animationName)
        Return
    EndIf
    SexLabTrace(requestID, diagnostic, "ANIMATION SELECTED | registrar=" + animationName + " | animation=" + animation)
    Int checks = 0
    While checks < 20 && (!milkController.SexLab.IsActorActive(milkSource) || !milkController.SexLab.IsActorActive(drinker))
        Utility.Wait(0.1)
        checks += 1
    EndWhile
    If !milkController.SexLab.IsActorActive(milkSource) || !milkController.SexLab.IsActorActive(drinker)
        SexLabTrace(requestID, diagnostic, "FAIL: dialogue SexLab startup not confirmed")
        Return
    EndIf
    sslThreadController thread = milkController.SexLab.GetActorController(milkSource)
    If thread == None || thread.Positions == None || thread.Positions.Find(drinker) < 0
        SexLabTrace(requestID, diagnostic, "FAIL: dialogue SexLab controller did not contain expected pair")
        Return
    EndIf
    Int threadID = thread.tid
    MMEAlertsSkyrimNet.SetBreastfeedingPromptState(milkSource, "source", threadID)
    MMEAlertsSkyrimNet.SetBreastfeedingPromptState(drinker, "drinker", threadID)
    SexLabTrace(requestID, diagnostic, "SEXLAB START CONFIRMED | SESSION ACTIVE | thread=" + threadID)
    Spell passive = milkController.BeingMilkedPassive
    checks = 0
    While checks < 30 && passive != None && !milkSource.HasSpell(passive)
        Utility.Wait(0.1)
        checks += 1
    EndWhile
    If passive != None && milkSource.HasSpell(passive)
        SexLabTrace(requestID, diagnostic, "MME START CONFIRMED | Mode4 passive active")
    Else
        SexLabTrace(requestID, diagnostic, "FAIL: MME Mode4 did not begin after dialogue SexLab startup")
    EndIf
EndFunction

Event OnSexLabBreastfeedingEnd(String eventName, String threadIDText, Float numArg, Form sender)
    Int threadID = threadIDText as Int
    If threadID < 0 || ActiveSexLabSemanticIntent == "" || threadID != ActiveSexLabIntentThreadID
        Return
    EndIf

    ; Ownership was proven at AnimationEnding. AnimationEnd runs only after
    ; SexLab resets Positions, so consume the stored transaction identity and
    ; never ask the dead controller for actors here.
    Actor semanticSource = ActiveSexLabIntentSource
    Actor semanticDrinker = ActiveSexLabIntentDrinker
    String semanticIntent = ActiveSexLabSemanticIntent
    Bool mmeProcessed = ActiveSexLabMMEStarted
    MMENewMilkMaid.TraceSexLabStop(11, "exact AnimationEnd received | thread=" + threadID)
    MMENewMilkMaid.TraceSexLabStop(12, "stored completion ownership confirmed")
    ; Clear before handoff so a duplicate event cannot reuse this completion.
    ClearSexLabIntent()
    If semanticIntent == "CreateMilkMaid"
        MMENewMilkMaid.TraceStep("scene complete")
    EndIf
    MMENewMilkMaid.HandleBreastfeedingCompleted(semanticSource, semanticDrinker, semanticIntent, mmeProcessed)
EndEvent

Bool Function SexLabIntentStillOwned()
    If ActiveSexLabSemanticIntent == "" || ActiveSexLabIntentThreadID < 0
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.SexLab == None
        Return False
    EndIf
    Return milkController.SexLab.GetController(ActiveSexLabIntentThreadID) != None && ActiveSexLabIntentSource != None && ActiveSexLabIntentDrinker != None
EndFunction

Function RecoverSexLabIntentAfterLoad()
    If ActiveSexLabSemanticIntent == ""
        Return
    EndIf
    If !SexLabIntentStillOwned()
        MMENewMilkMaid.TraceStep("discarded stale SexLab transaction after load", True)
        ClearSexLabIntent()
        Return
    EndIf
    MMEAlertsSkyrimNet.SetBreastfeedingPromptState(ActiveSexLabIntentSource, "source", ActiveSexLabIntentThreadID)
    MMEAlertsSkyrimNet.SetBreastfeedingPromptState(ActiveSexLabIntentDrinker, "drinker", ActiveSexLabIntentThreadID)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Spell passive = milkController.BeingMilkedPassive
    ActiveSexLabMMEStarted = passive != None && ActiveSexLabIntentSource.HasSpell(passive)
    MMENewMilkMaid.TraceStep("resumed owned SexLab transaction after load")
EndFunction

; Existing saves do not rerun this quest's OnInit after a script upgrade. Every
; entry and load therefore repairs the three listeners idempotently.
Function EnsureNewMilkMaidSexLabListeners(Bool report = False)
    UnregisterForModEvent("AnimationEnding")
    UnregisterForModEvent("AnimationEnd")
    UnregisterForModEvent("MMEExtensionsNewMilkMaidSexLabTimeout")
    RegisterForModEvent("AnimationEnding", "OnNewMilkMaidSexLabEnding")
    RegisterForModEvent("AnimationEnd", "OnSexLabBreastfeedingEnd")
    RegisterForModEvent("MMEExtensionsNewMilkMaidSexLabTimeout", "OnNewMilkMaidSexLabTimeout")
    If report
        Debug.Notification("NMM SexLab bus listeners refreshed")
        Debug.Trace("[MME Extensions New Milkmaid SexLab] listeners refreshed: AnimationEnding + AnimationEnd + timeout")
    EndIf
EndFunction

Function RecordNewMilkMaidSexLabBusStop(Int stopNumber, String busMessage, Bool failed = False)
    If stopNumber == 1
        LastNewMilkMaidSexLabBusThreadID = -1
        LastNewMilkMaidSexLabBusFailure = "none"
    EndIf
    LastNewMilkMaidSexLabBusStop = stopNumber
    LastNewMilkMaidSexLabBusMessage = busMessage
    If failed
        LastNewMilkMaidSexLabBusState = "FAILED"
        LastNewMilkMaidSexLabBusFailure = "stop " + stopNumber + ": " + busMessage
    ElseIf stopNumber >= 16
        LastNewMilkMaidSexLabBusState = "COMPLETE"
    Else
        LastNewMilkMaidSexLabBusState = "RUNNING"
    EndIf
EndFunction

String Function GetNewMilkMaidSexLabBusState()
    Return LastNewMilkMaidSexLabBusState
EndFunction

String Function GetNewMilkMaidSexLabBusStop()
    If LastNewMilkMaidSexLabBusStop <= 0
        Return "none"
    EndIf
    Return LastNewMilkMaidSexLabBusStop + " | " + LastNewMilkMaidSexLabBusMessage
EndFunction

String Function GetNewMilkMaidSexLabBusFailure()
    Return LastNewMilkMaidSexLabBusFailure
EndFunction

Function ShowNewMilkMaidSexLabBusReport()
    String report = "NMM Bus " + LastNewMilkMaidSexLabBusState + " | stop " + LastNewMilkMaidSexLabBusStop + " | " + LastNewMilkMaidSexLabBusMessage
    If LastNewMilkMaidSexLabBusState == "FAILED"
        report = "NMM Bus FAILED | " + LastNewMilkMaidSexLabBusFailure
    EndIf
    Debug.Notification(report)
    Debug.Trace("[MME Extensions New Milkmaid SexLab] " + report + " | thread=" + LastNewMilkMaidSexLabBusThreadID)
EndFunction

Function ClearSexLabIntent()
    If ActiveSexLabIntentRequestID > 0
        ReleaseSexLabPair(ActiveSexLabIntentSource, ActiveSexLabIntentDrinker, ActiveSexLabIntentRequestID)
    EndIf
    ActiveSexLabIntentThreadID = -1
    ActiveSexLabIntentSource = None
    ActiveSexLabIntentDrinker = None
    ActiveSexLabSemanticIntent = ""
    ActiveSexLabMMEStarted = False
    ActiveSexLabIntentRequestID = 0
EndFunction

Bool Function IsOriginalMMESexLabBreastfeedingAvailable(MilkQUEST milkController) Global
    If milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None
        Return False
    EndIf
    Return milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar") != None && milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding") != None
EndFunction

; The native MME SexLab hook and the OStim parity adapter equip basic milk at
; scene start. Suppress that equip from the ordinary drink transaction so it
; cannot add the Extensions bonus early or trigger narration, animation, or a
; drink notification. The validated scene-end path below owns the two effects.
Bool Function ShouldSuppressBreastfeedingDrink(Actor drinker)
    If drinker == None
        Return False
    EndIf
    If ActiveSession && ActiveDrinker == drinker
        Return True
    EndIf
    ; The dialogue observer may still be waiting for SexLab startup when MME's
    ; AnimationStart hook equips the milk. Inspect the live animation as a
    ; race-free fallback instead of depending only on our later role marker.
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController != None && milkController.SexLab != None && milkController.SexLab.IsActorActive(drinker)
        sslThreadController thread = milkController.SexLab.GetActorController(drinker)
        If thread != None
            If thread.HasTag("Breastfeeding")
                Return True
            EndIf
            If milkController.SexLab.AnimSlots != None && (thread.Animation == milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding") || thread.Animation == milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar"))
                Return True
            EndIf
        EndIf
    EndIf
    Return StorageUtil.GetStringValue(drinker, SexLabRoleKey, "") == "drinker" && StorageUtil.GetIntValue(drinker, SexLabThreadKey, -1) >= 0
EndFunction

; Applies only the two requested actor-safe effects. It deliberately bypasses
; MMEDrinkTracker's full transaction (sound, dialogue, narration, animation,
; notifications, publication, and deferred post-drink processing).
Function ApplyBreastfeedingDrinkEffects(Actor drinker) Global
    String configFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(configFile, "enableBreastfeedingMilkEffectsDebug", 0) == 1
    If JsonUtil.GetIntValue(configFile, "enableBreastfeedingMilkEffects", 1) != 1
        BreastfeedingDrinkReport(diagnostic, "skipped | toggle off")
        Return
    EndIf
    If drinker == None
        BreastfeedingDrinkReport(diagnostic, "skipped | no drinker")
        Return
    EndIf

    ; Breastfeeding counts as ordinary MME milk, never Lactacid. Disabling the
    ; drink-attempt marker prevents armor/overflow follow-up outside this scope.
    Bool isMilkMaid = StorageUtil.HasFloatValue(drinker, "MME.MilkMaid.Level")
    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(drinker, 1, False, False)
    Int arousalBefore = MMEArousalBridge.GetCurrentArousal(drinker)
    Bool arousalSent = MMEArousalBridge.ApplyMilkDrinkArousalForActor(drinker, None, False)
    Float arousalAdded = 0.0
    If arousalSent
        arousalAdded = JsonUtil.GetFloatValue(configFile, "milkDrinkArousal", 10.0)
        If arousalAdded < 0.0
            arousalAdded = 0.0
        ElseIf arousalAdded > 100.0
            arousalAdded = 100.0
        EndIf
        If arousalBefore >= 0 && arousalBefore as Float + arousalAdded > 100.0
            arousalAdded = 100.0 - arousalBefore as Float
        EndIf
    EndIf

    String actorLabel = "NPC"
    If drinker == Game.GetPlayer()
        actorLabel = "Player"
    EndIf
    String result = actorLabel + " | milk +" + milkAdded
    If !isMilkMaid
        result += " | not Milk Maid"
    EndIf
    result += " | arousal +" + arousalAdded
    BreastfeedingDrinkReport(diagnostic, result)
EndFunction

Function BreastfeedingDrinkReport(Bool enabled, String result) Global
    If enabled
        Debug.Trace("[MME Extensions BF Drink] " + result)
        Debug.Notification("BF Drink: " + result)
    EndIf
EndFunction

String Function SexLabPairFailure(Actor milkSource, Actor drinker, MilkQUEST milkController)
    If milkSource == None
        Return "source actor is None"
    ElseIf drinker == None
        Return "drinker actor is None"
    ElseIf milkSource == drinker
        Return "source and drinker are the same actor"
    ElseIf milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None
        Return "MME/SexLab framework unavailable"
    ElseIf !StorageUtil.HasFloatValue(milkSource, "MME.MilkMaid.Level")
        Return "source is not an authoritative MME Milk Maid"
    ElseIf milkSource.IsDead() || milkSource.IsDisabled() || !milkSource.Is3DLoaded()
        Return "source is dead, disabled, or unloaded"
    ElseIf drinker.IsDead() || drinker.IsDisabled() || !drinker.Is3DLoaded()
        Return "drinker is dead, disabled, or unloaded"
    ElseIf milkSource.IsChild()
        Return "source is a child actor"
    ElseIf drinker.IsChild()
        Return "drinker is a child actor"
    ElseIf milkSource.GetParentCell() == None || milkSource.GetParentCell() != drinker.GetParentCell()
        Return "source and drinker are not in the same valid cell"
    ElseIf milkSource.IsInCombat()
        Return "source is in combat"
    ElseIf drinker.IsInCombat()
        Return "drinker is in combat"
    ElseIf milkController.SexLab.IsActorActive(milkSource)
        Return "source already active in SexLab"
    ElseIf milkController.SexLab.IsActorActive(drinker)
        Return "drinker already active in SexLab"
    ElseIf MMEOStimIntegration.IsActorInScene(milkSource)
        Return "source already active in OStim"
    ElseIf MMEOStimIntegration.IsActorInScene(drinker)
        Return "drinker already active in OStim"
    EndIf
    Return ""
EndFunction

Bool Function AcquireSexLabActor(Actor target, Int requestID)
    If target == None
        Return False
    EndIf
    If StorageUtil.HasIntValue(target, SexLabLockKey)
        Float now = Utility.GetCurrentRealTime()
        Float lockedAt = StorageUtil.GetFloatValue(target, SexLabLockTimeKey, -1.0)
        ; Real-time resets across game sessions. Also expire an interrupted
        ; startup after ten seconds so save/load or a killed stack cannot strand it.
        If lockedAt < 0.0 || now < lockedAt || now - lockedAt > 10.0
            StorageUtil.UnsetIntValue(target, SexLabLockKey)
            StorageUtil.UnsetFloatValue(target, SexLabLockTimeKey)
        Else
            Return False
        EndIf
    EndIf
    StorageUtil.SetIntValue(target, SexLabLockKey, requestID)
    StorageUtil.SetFloatValue(target, SexLabLockTimeKey, Utility.GetCurrentRealTime())
    Return StorageUtil.GetIntValue(target, SexLabLockKey, 0) == requestID
EndFunction

Function ReleaseSexLabActor(Actor target, Int requestID)
    If target != None && StorageUtil.GetIntValue(target, SexLabLockKey, 0) == requestID
        StorageUtil.UnsetIntValue(target, SexLabLockKey)
        StorageUtil.UnsetFloatValue(target, SexLabLockTimeKey)
    EndIf
EndFunction

Function ReleaseSexLabPair(Actor milkSource, Actor drinker, Int requestID)
    ReleaseSexLabActor(milkSource, requestID)
    ReleaseSexLabActor(drinker, requestID)
EndFunction

Function SexLabTrace(Int requestID, Bool enabled, String traceText)
    If enabled
        Debug.Trace("[MME SexLab #" + requestID + "] " + traceText)
    EndIf
EndFunction

Bool Function StartBreastfeeding(Actor milkSource, Actor drinker, Bool callerDiagnostic = False, String caller = "Unknown", String semanticIntent = "")
    Bool diagnostic = callerDiagnostic || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    AttemptSequence += 1
    Int attemptID = AttemptSequence
    String requestTrace = "caller=" + caller
    If semanticIntent != ""
        requestTrace += " | semantic intent=" + semanticIntent
    EndIf
    TraceAttempt(attemptID, diagnostic, requestTrace + " | normalized source=" + GetActorName(milkSource) + " | normalized drinker=" + GetActorName(drinker))

    ; Reject duplicate requests before any scene or MME work begins.
    If ActiveSession
        TraceAttempt(attemptID, diagnostic, "rejected: breastfeeding session already active | active session=#" + ActiveSessionID)
        Return False
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled()
        TraceAttempt(attemptID, diagnostic, "rejected: MME Extensions is disabled")
        Return False
    EndIf
    If !MMEOStimBreastfeeding.IsOStimDetected()
        TraceAttempt(attemptID, diagnostic, "rejected: OStim not detected")
        Return False
    EndIf
    If !MMEOStimIntegration.IsSupportedVersion()
        TraceAttempt(attemptID, diagnostic, "rejected: OStim 7.2 or newer is required")
        Return False
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableOStimBreastfeeding", 0) != 1
        TraceAttempt(attemptID, diagnostic, "rejected: OStim breastfeeding toggle is off")
        Return False
    EndIf
    If milkSource == None || drinker == None || milkSource == drinker
        TraceAttempt(attemptID, diagnostic, "OStim preflight actors valid=FAIL")
        Return False
    EndIf

    Actor[] actors = new Actor[2]
    ; OStim action actor 0 drinks from target actor 1.
    actors[0] = drinker
    actors[1] = milkSource
    Bool playerIsActor0 = actors[0] == Game.GetPlayer()
    Bool playerIsActor1 = actors[1] == Game.GetPlayer()
    Bool suppressPlayerControl = playerIsActor0 || playerIsActor1
    ; Match OStimNet's established default for a bounded nonsexual scene while
    ; allowing the dedicated duration to be configured independently of MME.
    Float sceneDuration = JsonUtil.GetFloatValue(SettingsFile, "ostimBreastfeedingDuration", 20.0)
    If sceneDuration < 5.0
        sceneDuration = 5.0
    ElseIf sceneDuration > 60.0
        sceneDuration = 60.0
    EndIf
    String traceContext = "BF #" + attemptID + " "
    TraceAttempt(attemptID, diagnostic, "roles actor0/drinker=" + GetActorName(actors[0]) + " | actor1/source=" + GetActorName(actors[1]) + " | player actor0=" + playerIsActor0 + " | player actor1=" + playerIsActor1)
    If !MMEOStimIntegration.ValidatePairForCommit(actors, diagnostic, True, traceContext)
        TraceAttempt(attemptID, diagnostic, "OStim preflight=FAIL; see preceding reason")
        Return False
    EndIf
    TraceAttempt(attemptID, diagnostic, "OStim preflight actors/same-cell/busy/combat/VerifyActors=PASS")

    String sceneID = MMEOStimIntegration.FindSemanticScene(actors, 0, 1, "suckingnipples", diagnostic, traceContext)
    If sceneID == ""
        TraceAttempt(attemptID, diagnostic, "scene selection=FAIL")
        Return False
    EndIf
    TraceAttempt(attemptID, diagnostic, "scene selected=" + sceneID)

    ; Recheck after scene search at the final builder commit boundary.
    If !MMEOStimIntegration.ValidatePairForCommit(actors, diagnostic, True, traceContext)
        TraceAttempt(attemptID, diagnostic, "commit revalidation=FAIL")
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Spell passiveSpell = None
    If milkController != None
        passiveSpell = milkController.BeingMilkedPassive
    EndIf
    BeginSession(attemptID, caller, semanticIntent, milkSource, drinker, passiveSpell, sceneID, diagnostic)
    Int threadID = MMEOStimIntegration.StartManualScene(actors, sceneID, "MMEExtensions,Breastfeeding", suppressPlayerControl, sceneDuration, diagnostic, traceContext)
    If threadID < 0
        EndSession("OStim builder start rejected")
        Return False
    EndIf
    ActiveThreadID = threadID
    TraceActive("OStim builder returned thread=" + threadID + " | NoPlayerControl applied=" + suppressPlayerControl + " | OStim duration=" + sceneDuration + " seconds")

    If !WaitForExpectedScene()
        If StillOwnsThread()
            StopOwnedThread("startup verification failed")
        EndIf
        TraceActive("started=false; expected scene was not confirmed")
        EndSession("OStim startup verification failed")
        Return False
    EndIf
    String finalSceneID = MMEOStimIntegration.GetThreadScene(threadID)
    TraceActive("OStim thread started | thread=" + threadID + " | selected scene=" + sceneID + " | final current scene=" + finalSceneID + " | NoPlayerControl applied=" + suppressPlayerControl)
    If semanticIntent == "CreateMilkMaid"
        MMENewMilkMaid.TraceStep("scene started")
    EndIf

    ; MME is an optional gameplay sidecar. Its eligibility, startup, completion,
    ; or failure never determines the lifetime of the valid OStim animation.
    Bool isMilkMaid = milkController != None && StorageUtil.HasFloatValue(milkSource, "MME.MilkMaid.Level")
    Bool mmeEligible = IsMMEProcessingEligible(milkSource, milkController)
    Float sourceMilk = 0.0
    If milkController != None
        sourceMilk = MME_Storage.getMilkCurrent(milkSource)
    EndIf
    TraceActive("MME is Milk Maid=" + isMilkMaid + " | milk=" + sourceMilk + " | processing=" + mmeEligible)
    If mmeEligible
        ApplyMMEBreastfeedingParity(milkSource, drinker, milkController)
        If semanticIntent == "CreateMilkMaid"
            MMENewMilkMaid.TraceStep("Mode 4 requested")
        EndIf
        If RequestMMEMilking(milkSource)
            ActiveMMERequested = True
            TraceActive("MME request sent")
            If WaitForMMEStart()
                If ActiveMMEStarted
                    TraceActive("MME passive detected")
                ElseIf ActiveMMECompleted
                    TraceActive("MME completed during startup; OStim continues")
                EndIf
            Else
                TraceActive("MME passive not detected; OStim continues")
                If semanticIntent == "CreateMilkMaid"
                    MMENewMilkMaid.TraceStep("Mode 4 did not start; creation continues", True)
                EndIf
            EndIf
        Else
            TraceActive("MME request failed; OStim continues")
            If semanticIntent == "CreateMilkMaid"
                MMENewMilkMaid.TraceStep("Mode 4 request failed; creation continues", True)
            EndIf
        EndIf
    Else
        TraceActive("MME processing skipped; OStim continues")
        If semanticIntent == "CreateMilkMaid"
            MMENewMilkMaid.TraceStep("Mode 4 skipped; creation continues")
        EndIf
    EndIf

    ActiveLaunching = False
    RequestWatchdog()
    Return True
EndFunction

Function BeginSession(Int sessionID, String caller, String semanticIntent, Actor milkSource, Actor drinker, Spell passiveSpell, String sceneID, Bool diagnostic)
    ; Initialize every state flag as one atomic logical session before events
    ; are registered. ActiveLaunching prevents asynchronous completion from
    ; clearing fields while StartBreastfeeding is still on its startup stack.
    ActiveSession = True
    ActiveOwnsThread = True
    ActiveMMERequested = False
    ActiveMMEStarted = False
    ActiveMMECompleted = False
    ActiveLaunching = True
    ActiveDiagnostic = diagnostic
    ActiveSessionID = sessionID
    ActiveCaller = caller
    ActiveSemanticIntent = semanticIntent
    ; No provisional player-thread ID: NPC-only Skyrim.Net pairs must wait for
    ; the positive ID returned by OStim and ignore legacy player-thread events.
    ActiveThreadID = -1
    ActiveSceneID = sceneID
    ActiveMilkSource = milkSource
    ActiveDrinker = drinker
    ActivePassiveSpell = passiveSpell
    ActiveIncludesPlayer = milkSource == Game.GetPlayer() || drinker == Game.GetPlayer()

    RegisterSessionEvents()
EndFunction

Function RegisterSessionEvents()
    RegisterForModEvent("ostim_thread_scenechanged", "OnOStimThreadSceneChanged")
    RegisterForModEvent("ostim_thread_end", "OnOStimThreadEnd")
    If ActiveIncludesPlayer
        RegisterForModEvent("ostim_scenechanged", "OnOStimSceneChanged")
        RegisterForModEvent("ostim_end", "OnOStimEnd")
    EndIf
    RegisterForModEvent("MME_MilkingDone", "OnMMEMilkingDone")
EndFunction

Function UnregisterSessionEvents()
    UnregisterForModEvent("ostim_thread_scenechanged")
    UnregisterForModEvent("ostim_thread_end")
    UnregisterForModEvent("ostim_scenechanged")
    UnregisterForModEvent("ostim_end")
    UnregisterForModEvent("MME_MilkingDone")
EndFunction

Function ClearSessionState()
    ActiveThreadID = -1
    ActiveSceneID = ""
    ActiveMilkSource = None
    ActiveDrinker = None
    ActivePassiveSpell = None
    ActiveSession = False
    ActiveOwnsThread = False
    ActiveMMERequested = False
    ActiveMMEStarted = False
    ActiveMMECompleted = False
    ActiveLaunching = False
    ActiveDiagnostic = False
    ActiveIncludesPlayer = False
    ActiveSessionID = 0
    ActiveCaller = ""
    ActiveSemanticIntent = ""
EndFunction

Function EndSession(String reason = "completed")
    ; Cleanup is deliberately idempotent and local. Never stop an OStim thread
    ; here: callers must first prove StillOwnsThread, then stop it explicitly.
    TraceActive("cleanup reason=" + reason)
    UnregisterSessionEvents()
    ClearSessionState()
EndFunction

Bool Function WaitForExpectedScene()
    ; Bounded polling is startup confirmation, not a permanent gameplay poll.
    ; Five seconds covers asynchronous OStim construction while guaranteeing a
    ; failed scene cannot leave this TopicInfo stack waiting indefinitely.
    Int attempt = 0
    While ActiveSession && ActiveOwnsThread && attempt < 20
        If MMEOStimIntegration.IsThreadRunning(ActiveThreadID)
            String currentScene = MMEOStimIntegration.GetThreadScene(ActiveThreadID)
            If MMEOStimIntegration.OwnsManualThreadForActors(ActiveThreadID, ActiveMilkSource, ActiveDrinker)
                If currentScene != ActiveSceneID
                    TraceActive("OStim startup accepted live scene ID=" + currentScene + " | selected scene ID=" + ActiveSceneID + " | ownership confirmed by thread actors/manual mode")
                EndIf
                Return True
            ElseIf MMEOStimIntegration.IsThreadInAutoMode(ActiveThreadID)
                RelinquishOwnership("another integration enabled OStim auto mode during startup")
                Return False
            EndIf
        EndIf
        Utility.Wait(0.25)
        attempt += 1
    EndWhile
    Return False
EndFunction

Bool Function WaitForMMEStart()
    ; MME does not return a request handle for MME_Milking. Its passive spell
    ; and completion event are therefore the authoritative startup outcomes.
    Int attempt = 0
    While ActiveSession && attempt < 12
        If ActiveMMECompleted
            Return True
        EndIf
        If ActiveMilkSource != None && ActivePassiveSpell != None && ActiveMilkSource.HasSpell(ActivePassiveSpell)
            ActiveMMEStarted = True
            If ActiveSemanticIntent == "CreateMilkMaid"
                MMENewMilkMaid.TraceStep("Mode 4 started")
            EndIf
            If !StillOwnsThread()
                RelinquishOwnership("OStim breastfeeding ended or changed before MME startup completed")
                Return False
            EndIf
            Return True
        EndIf
        Utility.Wait(0.25)
        attempt += 1
    EndWhile
    Return ActiveMMECompleted
EndFunction

Bool Function StillOwnsThread()
    If !ActiveSession || !ActiveOwnsThread
        Return False
    EndIf
    Return MMEOStimIntegration.OwnsManualThreadForActors(ActiveThreadID, ActiveMilkSource, ActiveDrinker)
EndFunction

Function RelinquishOwnership(String reason)
    If !ActiveSession
        Return
    EndIf
    Bool wasOwned = ActiveOwnsThread
    ActiveOwnsThread = False
    ; Remove only the MME state started for this route. The OStim scene is left
    ; alone because a changed scene/auto-mode flag means ownership moved away.
    If ActiveMMERequested && ActiveMilkSource != None && ActivePassiveSpell != None && ActiveMilkSource.HasSpell(ActivePassiveSpell)
        ActiveMilkSource.RemoveSpell(ActivePassiveSpell)
    EndIf
    If wasOwned
        TraceActive("ownership relinquished: " + reason + "; external OStim thread left alone")
    EndIf
EndFunction

Event OnOStimThreadSceneChanged(String eventName, String sceneID, Float threadID, Form sender)
    If ActiveSession && threadID as Int == ActiveThreadID && sceneID != ActiveSceneID
        TraceActive("OStim thread_scenechanged received | scene=" + sceneID)
        If ActiveLaunching
            ; Startup polling owns confirmation while OStim is still populating
            ; the thread, so a transitional event cannot race actor assignment.
            TraceActive("OStim startup scene transition deferred to actor/manual verification")
        ElseIf !MMEOStimIntegration.OwnsManualThreadForActors(ActiveThreadID, ActiveMilkSource, ActiveDrinker)
            RelinquishOwnership("OStim thread actors changed or thread entered auto mode at scene " + sceneID)
            EndSession("OStim thread ownership changed")
        Else
            TraceActive("OStim scene ID changed but actor/manual ownership remains confirmed")
        EndIf
    EndIf
EndEvent

Event OnOStimSceneChanged(String eventName, String sceneID, Float numArg, Form sender)
    If ActiveSession && ActiveIncludesPlayer && ActiveThreadID == 0 && sceneID != ActiveSceneID
        TraceActive("legacy OStim scenechanged received | scene=" + sceneID)
        RelinquishOwnership("OStim player thread changed to " + sceneID)
        If !ActiveLaunching
            EndSession("OStim player scene changed")
        EndIf
    EndIf
EndEvent

Event OnOStimThreadEnd(String eventName, String json, Float threadID, Form sender)
    If ActiveSession && threadID as Int == ActiveThreadID
        TraceActive("OStim thread_end received | thread=" + (threadID as Int))
        Bool completed = ActiveOwnsThread && !ActiveLaunching
        Bool mmeProcessed = ActiveMMERequested && (ActiveMMEStarted || ActiveMMECompleted)
        Actor milkSource = ActiveMilkSource
        Actor drinker = ActiveDrinker
        String semanticIntent = ActiveSemanticIntent
        RelinquishOwnership("OStim breastfeeding thread ended")
        If completed
            ApplyBreastfeedingDrinkEffects(drinker)
            If semanticIntent == "CreateMilkMaid"
                MMENewMilkMaid.TraceStep("scene complete")
            EndIf
            MMENewMilkMaid.HandleBreastfeedingCompleted(milkSource, drinker, semanticIntent, mmeProcessed)
        EndIf
        If !ActiveLaunching
            EndSession("OStim thread ended normally")
        EndIf
    EndIf
EndEvent

Event OnOStimEnd(String eventName, String json, Float numArg, Form sender)
    If ActiveSession && ActiveIncludesPlayer && ActiveThreadID == 0
        TraceActive("legacy OStim end received | thread=0")
        Bool completed = ActiveOwnsThread && !ActiveLaunching
        Bool mmeProcessed = ActiveMMERequested && (ActiveMMEStarted || ActiveMMECompleted)
        Actor milkSource = ActiveMilkSource
        Actor drinker = ActiveDrinker
        String semanticIntent = ActiveSemanticIntent
        RelinquishOwnership("OStim breastfeeding thread ended")
        If completed
            ApplyBreastfeedingDrinkEffects(drinker)
            If semanticIntent == "CreateMilkMaid"
                MMENewMilkMaid.TraceStep("scene complete")
            EndIf
            MMENewMilkMaid.HandleBreastfeedingCompleted(milkSource, drinker, semanticIntent, mmeProcessed)
        EndIf
        If !ActiveLaunching
            EndSession("OStim player thread ended normally")
        EndIf
    EndIf
EndEvent

Event OnMMEMilkingDone(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    ; MME_MilkingDone is global, so match both the active request and source.
    ; It completes only the optional gameplay sidecar; OStim owns scene lifetime.
    If !ActiveSession || !ActiveMMERequested || actorForm as Actor != ActiveMilkSource
        Return
    EndIf

    ActiveMMECompleted = True
    ActiveMMEStarted = False
    TraceActive("MME_MilkingDone bottles=" + bottles + " | boobgasms=" + boobgasmCount + " | OStim continues")
    If ActiveSemanticIntent == "CreateMilkMaid"
        MMENewMilkMaid.TraceStep("Mode 4 completed")
    EndIf
EndEvent

Function HandleWatchdogUpdate()
    ; This one-second watchdog exists only during an active interaction. OStim
    ; ownership drives its lifetime; MME passive loss is recorded but never
    ; treated as a reason to stop the animation.
    If !ActiveSession || ActiveLaunching
        Return
    EndIf

    If ActiveMMEStarted && (ActiveMilkSource == None || ActivePassiveSpell == None || !ActiveMilkSource.HasSpell(ActivePassiveSpell))
        ActiveMMEStarted = False
        ActiveMMECompleted = True
        TraceActive("MME passive ended without MME_MilkingDone; OStim continues")
        If ActiveSemanticIntent == "CreateMilkMaid"
            MMENewMilkMaid.TraceStep("Mode 4 completed")
        EndIf
    EndIf

    ; Revalidate ownership before scheduling another watchdog tick. Cleanup is
    ; final as soon as OStim or MME no longer belongs to this transaction.
    If ActiveOwnsThread && !StillOwnsThread()
        RelinquishOwnership("OStim breastfeeding scene ended, changed, or entered auto mode")
    EndIf
    If ActiveSession && ActiveOwnsThread
        RequestWatchdog()
    Else
        EndSession("OStim ownership ended or changed")
    EndIf
EndFunction

Function RequestWatchdog()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RequestOStimBreastfeedingWatchdog()
    EndIf
EndFunction

Function TraceAttempt(Int attemptID, Bool showNotification, String traceText)
    String line = "BF #" + attemptID + " " + traceText
    Debug.Trace("[MME Extensions OStim] " + line)
    If showNotification
        Debug.Notification(line)
    EndIf
EndFunction

Function TraceActive(String traceText)
    TraceAttempt(ActiveSessionID, ActiveDiagnostic, traceText)
EndFunction

Bool Function IsMMEProcessingEligible(Actor milkSource, MilkQUEST milkController)
    If milkSource == None || milkController == None || !StorageUtil.HasFloatValue(milkSource, "MME.MilkMaid.Level")
        Return False
    EndIf
    ActorBase milkSourceBase = milkSource.GetLeveledActorBase()
    If milkSourceBase == None || (milkSourceBase.GetSex() != 1 && !(milkSourceBase.GetSex() == 0 && milkController.MaleMaids))
        Return False
    EndIf
    Return milkController.BeingMilkedPassive != None && !milkSource.HasSpell(milkController.BeingMilkedPassive)
EndFunction

Function StopOwnedThread(String reason)
    If !StillOwnsThread()
        TraceActive("NOT stopping OStim; ownership could not be proven | reason=" + reason)
        Return
    EndIf
    TraceActive("STOPPING OStim thread | reason=" + reason + " | thread=" + ActiveThreadID + " | scene=" + ActiveSceneID)
    MMEOStimIntegration.StopThread(ActiveThreadID)
EndFunction

Bool Function IsActorAvailable(Actor target) Global
    Return target != None && !target.IsDead() && !target.IsDisabled() && target.Is3DLoaded()
EndFunction

; Mirrors MME's SexLab breastfeeding hook behavior that Mode 4 itself omits.
Function ApplyMMEBreastfeedingParity(Actor milkSource, Actor drinker, MilkQUEST milkController) Global
    ; MME's original hook grants/uses a basic milk item only when the source has
    ; at least one unit available. Mode 4 itself does not perform this hook.
    If MME_Storage.getMilkCurrent(milkSource) < 1.0
        Return
    EndIf

    If milkController.MME_Milk_Basic != None
        Form basicMilk = milkController.MME_Milk_Basic.GetAt(0)
        If basicMilk != None
            drinker.EquipItem(basicMilk, True, True)
        EndIf
    EndIf

    ; Preserve MME's Khajiit compatibility side effect exactly. Although the
    ; destination looks surprising, changing it would diverge from SexLab lane
    ; behavior and belongs in an explicit gameplay change, not this adapter.
    ActorBase drinkerBase = drinker.GetLeveledActorBase()
    Race khajiitRace = Game.GetFormFromFile(0x013745, "Skyrim.esm") as Race
    If drinkerBase != None && drinkerBase.GetRace() == khajiitRace && milkController.MME_Util_Potions != None
        Form lactacid = milkController.MME_Util_Potions.GetAt(0)
        If lactacid != None
            milkSource.AddItem(lactacid, 1, True)
        EndIf
    EndIf
EndFunction

Bool Function RequestMMEMilking(Actor milkSource) Global
    ; MME's public ModEvent protocol is positional: source, mode, machine slot.
    ; Mode 4 is the original breastfeeding mode; the final zero is intentional.
    Int handle = ModEvent.Create("MME_Milking")
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, milkSource)
    ModEvent.PushInt(handle, 4)
    ModEvent.PushInt(handle, 0)
    Return ModEvent.Send(handle)
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
    Debug.Trace("[MME Extensions OStim] " + reportText)
    If showNotification
        Debug.Notification("OStim Debug: " + reportText)
    EndIf
EndFunction
