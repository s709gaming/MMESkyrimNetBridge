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
; to prove ownership before stopping a scene or performing guarded MME cleanup.
; MME owns normal Mode 4 cleanup; this service intervenes only after a confirmed
; first deduction or a positively attributed stale-request deadline.
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
Float ActiveMilkBefore = 0.0
Float ActiveMMEDeadline = 0.0
Bool ActiveLaunching = False
Bool ActiveDiagnostic = False
Int AttemptSequence = 0
Int ActiveSessionID = 0
String ActiveCaller = ""

; SexLab uses short-lived, actor-scoped startup locks. SexLab's own active
; state becomes authoritative as soon as StartThread succeeds.
String SexLabLockKey = "MME.Extensions.SexLabBreastfeeding.Lock"
String SexLabLockTimeKey = "MME.Extensions.SexLabBreastfeeding.LockTime"
Int SexLabAttemptSequence = 0

; Quest startup delegates normal scheduling to the controller.
Event OnInit()
    RegisterForModEvent("AnimationEnd", "OnSexLabBreastfeedingEnd")
    UpdateDebugLoop()
EndEvent

Function UpdateDebugLoop()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.UpdatePolling()
    EndIf
EndFunction

; Save/load can restore either a live OStim transaction or the intentionally
; retained MME tail after OStim ended. Resume the latter only when this request
; was positively observed starting and its exact source still has the passive.
Function RecoverAfterLoad()
    RegisterForModEvent("AnimationEnd", "OnSexLabBreastfeedingEnd")
    If !ActiveSession
        Return
    EndIf
    UnregisterSessionEvents()
    Bool ownsOStim = StillOwnsThread()
    Bool observedMMEActive = ActiveMMERequested && ActiveMMEStarted && ActiveMilkSource != None && ActivePassiveSpell != None && ActiveMilkSource.HasSpell(ActivePassiveSpell)
    If ownsOStim
        If ActiveMMEStarted && !observedMMEActive
            ActiveMMEStarted = False
            ActiveMMECompleted = True
        EndIf
        ActiveLaunching = False
        If observedMMEActive
            ResetMMEDeadline()
        EndIf
        RegisterSessionEvents()
        RequestWatchdog()
        TraceActive("resumed owned OStim breastfeeding session after load")
    ElseIf observedMMEActive
        ; The OStim scene may have ended before the save while this transaction
        ; deliberately waited for MME's first deduction. Do not trust the saved
        ; real-time deadline because GetCurrentRealTime restarts with Skyrim.
        ActiveOwnsThread = False
        ActiveLaunching = False
        ResetMMEDeadline()
        RegisterSessionEvents()
        RequestWatchdog()
        TraceActive("resumed positively observed MME tail after load without OStim ownership")
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
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.SexLab == None || threadID < 0
        Return
    EndIf
    sslThreadController thread = milkController.SexLab.GetController(threadID)
    If thread == None || thread.Positions == None
        Return
    EndIf
    Int index = 0
    While index < thread.Positions.Length
        MMEAlertsSkyrimNet.ClearBreastfeedingPromptState(thread.Positions[index], threadID)
        index += 1
    EndWhile
EndEvent

String Function SexLabPairFailure(Actor milkSource, Actor drinker, MilkQUEST milkController)
    If milkSource == None
        Return "source actor is None"
    ElseIf drinker == None
        Return "drinker actor is None"
    ElseIf milkSource == drinker
        Return "source and drinker are the same actor"
    ElseIf milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None
        Return "MME/SexLab framework unavailable"
    ElseIf milkController.MilkMaid == None || milkController.MilkMaid.Find(milkSource) < 0
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
    BeginSession(attemptID, caller, milkSource, drinker, passiveSpell, sceneID, diagnostic)
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

    ; MME is an optional gameplay sidecar. Its eligibility, startup, completion,
    ; or failure never determines the lifetime of the valid OStim animation.
    Bool isMilkMaid = milkController != None && milkController.MilkMaid != None && milkController.MilkMaid.Find(milkSource) >= 0
    Bool mmeEligible = IsMMEProcessingEligible(milkSource, milkController)
    Float sourceMilk = 0.0
    If milkController != None
        sourceMilk = MME_Storage.getMilkCurrent(milkSource)
    EndIf
    ActiveMilkBefore = sourceMilk
    TraceActive("milk before=" + sourceMilk + " | MME is Milk Maid=" + isMilkMaid + " | processing=" + mmeEligible)
    If mmeEligible
        ApplyMMEBreastfeedingParity(milkSource, drinker, milkController)
        If RequestMMEMilking(milkSource)
            ActiveMMERequested = True
            ; Keep a short observation window even if MME's ModEvent handler is
            ; delayed beyond WaitForMMEStart or the OStim scene ends unusually
            ; early. A detected passive replaces this with the full cycle limit.
            ActiveMMEDeadline = Utility.GetCurrentRealTime() + 30.0
            TraceActive("MME request sent | source=" + GetActorName(milkSource) + " " + milkSource + " | mode=4 | pump type=0")
            If WaitForMMEStart()
                If ActiveMMEStarted
                    TraceActive("MME passive detected | source=" + GetActorName(milkSource) + " " + milkSource)
                ElseIf ActiveMMECompleted
                    TraceActive("MME completed during startup; OStim continues")
                EndIf
            Else
                TraceActive("MME passive not detected; OStim continues")
            EndIf
        Else
            TraceActive("MME request failed; OStim continues")
        EndIf
    Else
        TraceActive("MME processing skipped; OStim continues")
    EndIf

    ActiveLaunching = False
    RequestWatchdog()
    Return True
EndFunction

Function BeginSession(Int sessionID, String caller, Actor milkSource, Actor drinker, Spell passiveSpell, String sceneID, Bool diagnostic)
    ; Initialize every state flag as one atomic logical session before events
    ; are registered. ActiveLaunching prevents asynchronous completion from
    ; clearing fields while StartBreastfeeding is still on its startup stack.
    ActiveSession = True
    ActiveOwnsThread = True
    ActiveMMERequested = False
    ActiveMMEStarted = False
    ActiveMMECompleted = False
    ActiveMilkBefore = 0.0
    ActiveMMEDeadline = 0.0
    ActiveLaunching = True
    ActiveDiagnostic = diagnostic
    ActiveSessionID = sessionID
    ActiveCaller = caller
    ; No provisional thread ID: wait for the positive ID returned by OStim.
    ActiveThreadID = -1
    ActiveSceneID = sceneID
    ActiveMilkSource = milkSource
    ActiveDrinker = drinker
    ActivePassiveSpell = passiveSpell
    RegisterSessionEvents()
EndFunction

Function RegisterSessionEvents()
    RegisterForModEvent("ostim_thread_scenechanged", "OnOStimThreadSceneChanged")
    RegisterForModEvent("ostim_thread_end", "OnOStimThreadEnd")
    RegisterForModEvent("MME_MilkingDone", "OnMMEMilkingDone")
EndFunction

Function UnregisterSessionEvents()
    UnregisterForModEvent("ostim_thread_scenechanged")
    UnregisterForModEvent("ostim_thread_end")
    ; Clear registrations persisted by versions that listened to the redundant
    ; player-only legacy events. New sessions use thread-specific events only.
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
    ActiveMilkBefore = 0.0
    ActiveMMEDeadline = 0.0
    ActiveLaunching = False
    ActiveDiagnostic = False
    ActiveSessionID = 0
    ActiveCaller = ""
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
            If currentScene == ActiveSceneID && !MMEOStimIntegration.IsThreadInAutoMode(ActiveThreadID)
                Return True
            ElseIf currentScene != "" && currentScene != ActiveSceneID
                RelinquishOwnership("OStim entered a different scene during startup: " + currentScene)
                Return False
            ElseIf currentScene == ActiveSceneID && MMEOStimIntegration.IsThreadInAutoMode(ActiveThreadID)
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
            ResetMMEDeadline()
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

Function ResetMMEDeadline()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Float cycleDuration = 300.0
    If milkController != None
        cycleDuration = milkController.Milking_Duration as Float
        If cycleDuration < 1.0
            cycleDuration = 1.0
        ElseIf cycleDuration > 300.0
            cycleDuration = 300.0
        EndIf
    EndIf
    ; Always rebuild from this process's clock. Utility.GetCurrentRealTime
    ; restarts with Skyrim, so an absolute deadline must never cross a load.
    ActiveMMEDeadline = Utility.GetCurrentRealTime() + cycleDuration + 30.0
EndFunction

Bool Function StillOwnsThread()
    If !ActiveSession || !ActiveOwnsThread
        Return False
    EndIf
    Return MMEOStimIntegration.OwnsManualSceneForActors(ActiveThreadID, ActiveSceneID, ActiveMilkSource, ActiveDrinker)
EndFunction

Function RelinquishOwnership(String reason)
    If !ActiveSession
        Return
    EndIf
    Bool wasOwned = ActiveOwnsThread
    ActiveOwnsThread = False
    ; OStim ownership and MME processing are independent after the request.
    ; Never clear MME's loop guard merely because OStim ownership ended.
    If wasOwned
        TraceActive("ownership relinquished: " + reason + "; external OStim thread left alone")
    EndIf
EndFunction

Event OnOStimThreadSceneChanged(String eventName, String sceneID, Float threadID, Form sender)
    If ActiveSession && threadID as Int == ActiveThreadID && sceneID != ActiveSceneID
        TraceActive("OStim thread_scenechanged received | scene=" + sceneID)
        RelinquishOwnership("OStim thread changed to " + sceneID)
        If !ActiveLaunching
            FinishOrWatchMME("OStim scene changed")
        EndIf
    EndIf
EndEvent

Event OnOStimThreadEnd(String eventName, String json, Float threadID, Form sender)
    If ActiveSession && threadID as Int == ActiveThreadID
        TraceActive("OStim thread_end received | thread=" + (threadID as Int))
        RelinquishOwnership("OStim breastfeeding thread ended")
        If !ActiveLaunching
            FinishOrWatchMME("OStim thread ended normally")
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
    Float milkAfter = MME_Storage.getMilkCurrent(ActiveMilkSource)
    TraceActive("MME_MilkingDone bottles=" + bottles + " | boobgasms=" + boobgasmCount + " | milk after=" + milkAfter + " | OStim continues")
EndEvent

Function HandleWatchdogUpdate()
    ; This one-second watchdog covers both the OStim interaction and a retained
    ; MME tail. MME state never determines the OStim animation lifetime.
    If !ActiveSession || ActiveLaunching
        Return
    EndIf

    Bool passivePresent = ActiveMilkSource != None && ActivePassiveSpell != None && ActiveMilkSource.HasSpell(ActivePassiveSpell)
    If ActiveMMERequested && !ActiveMMEStarted && !ActiveMMECompleted && passivePresent
        ; ModEvent delivery can be delayed beyond WaitForMMEStart's bounded
        ; three-second startup observation. Promote a late passive while this
        ; exact request transaction is still retained; never issue a retry.
        ActiveMMEStarted = True
        ResetMMEDeadline()
        TraceActive("MME passive detected late by watchdog; request tracking promoted")
    EndIf

    If ActiveMMEStarted
        If !passivePresent
            ActiveMMEStarted = False
            ActiveMMECompleted = True
            TraceActive("MME passive ended without MME_MilkingDone; OStim continues")
        ElseIf !ActiveOwnsThread
            Float milkNow = MME_Storage.getMilkCurrent(ActiveMilkSource)
            If milkNow < ActiveMilkBefore
                ; We observed no passive before our request and observed MME add
                ; it afterward. Once the first deduction is visible, ending the
                ; loop matches MME's own animation-end lifecycle without risking
                ; cancellation before the requested gameplay effect occurs.
                TraceActive("milk deduction confirmed after OStim end | before=" + ActiveMilkBefore + " | after=" + milkNow + " | ending owned MME loop")
                ActiveMilkSource.RemoveSpell(ActivePassiveSpell)
            ElseIf ActiveMMEDeadline > 0.0 && Utility.GetCurrentRealTime() >= ActiveMMEDeadline
                ; MME exposes a 1..300 second cycle. Continuous ownership beyond
                ; a full configured cycle plus 30 seconds indicates a stale call.
                TraceActive("MME passive exceeded owned request deadline without milk deduction; clearing stale passive")
                ActiveMilkSource.RemoveSpell(ActivePassiveSpell)
            EndIf
        EndIf
    EndIf

    ; Revalidate ownership before scheduling another watchdog tick. Cleanup is
    ; final as soon as OStim or MME no longer belongs to this transaction.
    If ActiveOwnsThread && !StillOwnsThread()
        RelinquishOwnership("OStim breastfeeding scene ended, changed, or entered auto mode")
    EndIf
    Bool awaitingLateMMEStart = ActiveMMERequested && !ActiveMMEStarted && !ActiveMMECompleted && ActiveMMEDeadline > Utility.GetCurrentRealTime()
    If ActiveSession && (ActiveOwnsThread || ActiveMMEStarted || awaitingLateMMEStart)
        RequestWatchdog()
    Else
        EndSession("OStim ownership ended or changed")
    EndIf
EndFunction

Function FinishOrWatchMME(String reason)
    Bool awaitingLateMMEStart = ActiveMMERequested && !ActiveMMEStarted && !ActiveMMECompleted && ActiveMMEDeadline > Utility.GetCurrentRealTime()
    If (ActiveMMEStarted && !ActiveMMECompleted) || awaitingLateMMEStart
        TraceActive(reason + "; retaining transaction for MME startup/first cycle")
        RequestWatchdog()
    Else
        EndSession(reason)
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
    If milkSource == None || milkController == None || milkController.MilkMaid == None || milkController.MilkMaid.Find(milkSource) < 0
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
