Scriptname MMEDebug extends Quest

; Persistent shared OStim breastfeeding service. Dialogue INFO fragments and
; Skyrim.Net both call this one quest-owned session implementation.
String SettingsFile = "/MMEAlerts/Settings"

; ---------------------------------------------------------------------------
; OStim breastfeeding session ownership
; ---------------------------------------------------------------------------
; This TopicInfo script is the complete OStim lane. It intentionally does not
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
    If ActiveMMEStarted && ActiveMilkSource != None && ActivePassiveSpell != None && ActiveMilkSource.HasSpell(ActivePassiveSpell) && StillOwnsThread()
        ActiveLaunching = False
        RegisterSessionEvents()
        RequestWatchdog()
        Report(ActiveDiagnostic, "resumed owned OStim breastfeeding session after load")
    Else
        Debug.Trace("[MME Extensions OStim] discarded stale breastfeeding session after load without touching external OStim/MME state")
        ClearSessionState()
    EndIf
EndFunction

Bool Function StartBreastfeeding(Actor milkSource, Actor drinker, Bool callerDiagnostic = False)
    Bool diagnostic = callerDiagnostic || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1

    ; Phase 1: reject re-entry, disabled integrations, and unusable actors.
    ; Do these checks before touching either framework so a failed dialogue
    ; selection cannot leave a partial OStim thread or MME milking state.
    If ActiveSession
        Report(diagnostic, "this OStim breastfeeding route is already active")
        Return False
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled()
        Report(diagnostic, "MME Extensions is disabled")
        Return False
    EndIf
    If !MMEOStimBreastfeeding.IsOStimDetected()
        Report(diagnostic, "OStim not detected")
        Return False
    EndIf
    If !MMEOStimIntegration.IsSupportedVersion()
        Report(diagnostic, "OStim 7.2 or newer is required by the breastfeeding scene builder")
        Return False
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) != 1
        Report(diagnostic, "OStim breastfeeding support is disabled")
        Return False
    EndIf
    If milkSource == None || drinker == None || milkSource == drinker
        Report(diagnostic, "invalid or missing milk-source/drinker actor")
        Return False
    EndIf
    If !IsActorAvailable(milkSource) || !IsActorAvailable(drinker)
        Report(diagnostic, "actors unavailable, dead, disabled, or not loaded")
        Return False
    EndIf

    ; Phase 2: resolve MME and enforce MME's source-side gameplay rules.
    ; The milk source, not necessarily the player, must be the real Milk Maid.
    ; Do not weaken these checks merely because OStim can animate the actors.
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, diagnostic)
        Return False
    EndIf

    ; Phase 3: resolve a semantic OStim scene with explicit role ordering.
    ; OStim actor 0 performs the nipple-sucking action on actor 1; MME Mode 4
    ; later receives actor 1 as the milk source. Reversing this array silently
    ; swaps drinker/source behavior even though the scene may still start.
    Actor[] actors = new Actor[2]
    ; OStim action actor 0 drinks from target 1. MME Mode 4 receives target 1.
    actors[0] = drinker
    actors[1] = milkSource
    If !MMEOStimIntegration.ValidatePairForCommit(actors, diagnostic, True)
        Return False
    EndIf
    String sceneID = MMEOStimIntegration.FindSemanticScene(actors, 0, 1, "suckingnipples", diagnostic)
    If sceneID == ""
        Return False
    EndIf

    ; Phase 4: establish local ownership before starting the external thread.
    ; BeginSession registers every completion/change signal first, closing the
    ; race where OStim or MME could finish before this script starts listening.
    ; Scene search is synchronous. Revalidate again after it and immediately
    ; before establishing ownership/allocating the OStim builder.
    If !MMEOStimBreastfeeding.ValidateMilkSource(milkSource, milkController, diagnostic) || !MMEOStimIntegration.ValidatePairForCommit(actors, diagnostic, True)
        Return False
    EndIf
    BeginSession(milkSource, drinker, milkController.BeingMilkedPassive, sceneID, diagnostic)
    Int threadID = MMEOStimIntegration.StartManualScene(actors, sceneID, "MMEExtensions,Breastfeeding", diagnostic)
    If threadID < 0
        EndSession()
        Return False
    EndIf
    ActiveThreadID = threadID

    ; Phase 5: confirm OStim actually entered the exact manual scene requested.
    ; A valid thread ID alone is insufficient: another integration may replace
    ; the scene or enable auto mode during OStim startup.
    If !WaitForExpectedScene()
        If ActiveOwnsThread
            MMEOStimIntegration.StopThread(ActiveThreadID)
        EndIf
        Report(diagnostic, "OStim did not enter the selected breastfeeding scene")
        EndSession()
        Return False
    EndIf

    ; Phase 6: reproduce the non-animation side effects from MME's SexLab hook,
    ; then request MME Mode 4. Ordering is intentional: parity effects happen
    ; immediately before MME begins milking, as in the original route.
    ; Match MME's original SexLab hook: breastfeeding side effects happen
    ; immediately before the Mode 4 milking call.
    If !StillOwnsThread()
        RelinquishOwnership("OStim scene changed during breastfeeding startup")
        EndSession()
        Return False
    EndIf
    ApplyMMEBreastfeedingParity(milkSource, drinker, milkController)
    If !RequestMMEMilking(milkSource)
        If StillOwnsThread()
            MMEOStimIntegration.StopThread(ActiveThreadID)
        EndIf
        Report(diagnostic, "MME milking event could not be sent")
        EndSession()
        Return False
    EndIf
    ActiveMMERequested = True

    ; Phase 7: require positive MME startup evidence before declaring success.
    ; The passive spell is MME's live ownership signal. A fast completion event
    ; is also valid and is handled separately so short sessions are not failures.
    If !WaitForMMEStart()
        If StillOwnsThread()
            MMEOStimIntegration.StopThread(ActiveThreadID)
        EndIf
        Report(diagnostic, "MME milking did not become active (or ended during startup)")
        EndSession()
        Return False
    EndIf

    If ActiveMMECompleted
        Report(diagnostic, "MME breastfeeding completed during startup")
        EndSession()
        Return True
    EndIf

    ; Phase 8: hand the active pair to the temporary watchdog.
    ; From here, cleanup occurs on MME completion, an OStim ownership change,
    ; or disappearance of MME's passive spell.
    ActiveLaunching = False
    ; MME has a few valid Mode 4 early exits that remove its passive spell but
    ; return before MME_MilkingDone. This temporary watchdog is only active for
    ; the interaction and supplies cleanup if either mod event is missed.
    RequestWatchdog()
    Debug.Trace("[MME Extensions OStim] started " + sceneID + " | drinker=" + GetActorName(drinker) + " | milk source=" + GetActorName(milkSource) + " | thread=" + threadID)
    If diagnostic
        Debug.Notification("OStim BF DEBUG: scene STARTED; MME milking active")
    EndIf
    Return True
EndFunction

Function BeginSession(Actor milkSource, Actor drinker, Spell passiveSpell, String sceneID, Bool diagnostic)
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
EndFunction

Function EndSession()
    ; Cleanup is deliberately idempotent and local. Never stop an OStim thread
    ; here: callers must first prove StillOwnsThread, then stop it explicitly.
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
    If ActiveMilkSource != None && ActivePassiveSpell != None && ActiveMilkSource.HasSpell(ActivePassiveSpell)
        ActiveMilkSource.RemoveSpell(ActivePassiveSpell)
    EndIf
    If wasOwned
        Report(ActiveDiagnostic, reason + "; MME breastfeeding stopped and OStim thread left alone")
    EndIf
EndFunction

Event OnOStimThreadSceneChanged(String eventName, String sceneID, Float threadID, Form sender)
    If ActiveSession && threadID as Int == ActiveThreadID && sceneID != ActiveSceneID
        RelinquishOwnership("OStim thread changed to " + sceneID)
    EndIf
EndEvent

Event OnOStimSceneChanged(String eventName, String sceneID, Float numArg, Form sender)
    If ActiveSession && ActiveIncludesPlayer && ActiveThreadID == 0 && sceneID != ActiveSceneID
        RelinquishOwnership("OStim player thread changed to " + sceneID)
    EndIf
EndEvent

Event OnOStimThreadEnd(String eventName, String json, Float threadID, Form sender)
    If ActiveSession && threadID as Int == ActiveThreadID
        RelinquishOwnership("OStim breastfeeding thread ended")
    EndIf
EndEvent

Event OnOStimEnd(String eventName, String json, Float numArg, Form sender)
    If ActiveSession && ActiveIncludesPlayer && ActiveThreadID == 0
        RelinquishOwnership("OStim breastfeeding thread ended")
    EndIf
EndEvent

Event OnMMEMilkingDone(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    ; MME_MilkingDone is global, so match both the active request and source.
    ; Unrelated Milk Maids completing nearby must never end this OStim thread.
    If !ActiveSession || !ActiveMMERequested || actorForm as Actor != ActiveMilkSource
        Return
    EndIf

    ActiveMMECompleted = True
    ActiveMMEStarted = False
    ; Stop only the exact manual scene this script still owns. If ownership was
    ; lost, record completion but leave the replacement OStim activity intact.
    If StillOwnsThread()
        MMEOStimIntegration.StopThread(ActiveThreadID)
        Debug.Trace("[MME Extensions OStim] MME breastfeeding completed; stopped owned OStim thread " + ActiveThreadID)
    Else
        ActiveOwnsThread = False
        Debug.Trace("[MME Extensions OStim] MME breastfeeding completed after OStim ownership was relinquished")
    EndIf

    If !ActiveLaunching
        EndSession()
    EndIf
EndEvent

Function HandleWatchdogUpdate()
    ; This one-second watchdog exists only during an active interaction. It is
    ; a fallback for MME Mode 4 exits that remove the passive spell without
    ; publishing MME_MilkingDone; it is not a general-purpose polling loop.
    If !ActiveSession || ActiveLaunching
        Return
    EndIf

    If ActiveMMEStarted && (ActiveMilkSource == None || ActivePassiveSpell == None || !ActiveMilkSource.HasSpell(ActivePassiveSpell))
        If StillOwnsThread()
            MMEOStimIntegration.StopThread(ActiveThreadID)
            Debug.Trace("[MME Extensions OStim] MME passive state ended without a completion event; stopped owned OStim thread " + ActiveThreadID)
        EndIf
        EndSession()
        Return
    EndIf

    ; Revalidate ownership before scheduling another watchdog tick. Cleanup is
    ; final as soon as OStim or MME no longer belongs to this transaction.
    If ActiveOwnsThread && !StillOwnsThread()
        RelinquishOwnership("OStim breastfeeding scene ended, changed, or entered auto mode")
    EndIf
    If ActiveSession && ActiveOwnsThread && ActiveMMEStarted
        RequestWatchdog()
    Else
        EndSession()
    EndIf
EndFunction

Function RequestWatchdog()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RequestOStimBreastfeedingWatchdog()
    EndIf
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
