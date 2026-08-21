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

; Quest startup delegates normal scheduling to the controller.
Event OnInit()
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

Bool Function StartBreastfeeding(Actor milkSource, Actor drinker, Bool callerDiagnostic = False, String caller = "Unknown")
    Bool diagnostic = callerDiagnostic || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1
    AttemptSequence += 1
    Int attemptID = AttemptSequence
    TraceAttempt(attemptID, diagnostic, "caller=" + caller + " | source=" + GetActorName(milkSource) + " | drinker=" + GetActorName(drinker))

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
    String traceContext = "BF #" + attemptID + " "
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
    Int threadID = MMEOStimIntegration.StartManualScene(actors, sceneID, "MMEExtensions,Breastfeeding", diagnostic, traceContext)
    If threadID < 0
        EndSession("OStim builder start rejected")
        Return False
    EndIf
    ActiveThreadID = threadID
    TraceActive("OStim builder returned thread=" + threadID)

    If !WaitForExpectedScene()
        If StillOwnsThread()
            StopOwnedThread("startup verification failed")
        EndIf
        TraceActive("started=false; expected scene was not confirmed")
        EndSession("OStim startup verification failed")
        Return False
    EndIf
    TraceActive("OStim thread started | thread=" + threadID + " | scene=" + sceneID)

    ; MME is an optional gameplay sidecar. Its eligibility, startup, completion,
    ; or failure never determines the lifetime of the valid OStim animation.
    Bool isMilkMaid = milkController != None && milkController.MilkMaid != None && milkController.MilkMaid.Find(milkSource) >= 0
    Bool mmeEligible = IsMMEProcessingEligible(milkSource, milkController)
    Float sourceMilk = 0.0
    If milkController != None
        sourceMilk = MME_Storage.getMilkCurrent(milkSource)
    EndIf
    TraceActive("MME is Milk Maid=" + isMilkMaid + " | milk=" + sourceMilk + " | processing=" + mmeEligible)
    If mmeEligible
        ApplyMMEBreastfeedingParity(milkSource, drinker, milkController)
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
    ActiveLaunching = True
    ActiveDiagnostic = diagnostic
    ActiveSessionID = sessionID
    ActiveCaller = caller
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
    Return MMEOStimIntegration.OwnsManualSceneForActors(ActiveThreadID, ActiveSceneID, ActiveMilkSource, ActiveDrinker)
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
        RelinquishOwnership("OStim thread changed to " + sceneID)
        If !ActiveLaunching
            EndSession("OStim scene changed")
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
        RelinquishOwnership("OStim breastfeeding thread ended")
        If !ActiveLaunching
            EndSession("OStim thread ended normally")
        EndIf
    EndIf
EndEvent

Event OnOStimEnd(String eventName, String json, Float numArg, Form sender)
    If ActiveSession && ActiveIncludesPlayer && ActiveThreadID == 0
        TraceActive("legacy OStim end received | thread=0")
        RelinquishOwnership("OStim breastfeeding thread ended")
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
