Scriptname MMEOStimBreastfeeding extends TopicInfo Hidden

Int ActiveThreadID = -1
String ActiveSceneID = ""
Actor ActiveMilkSource = None
Spell ActivePassiveSpell = None
Bool ActiveSession = False
Bool ActiveOwnsThread = False
Bool ActiveMMERequested = False
Bool ActiveMMEStarted = False
Bool ActiveMMECompleted = False
Bool ActiveLaunching = False
Bool ActiveDiagnostic = False

; MME Fragment_01 parity: the player drinks from the dialogue speaker.
Function Fragment_PlayerDrinks(ObjectReference akSpeakerRef)
    StartBreastfeeding(akSpeakerRef as Actor, Game.GetPlayer())
EndFunction

; MME Fragment_02 parity: the dialogue speaker drinks from the player.
Function Fragment_NPCDrinks(ObjectReference akSpeakerRef)
    StartBreastfeeding(Game.GetPlayer(), akSpeakerRef as Actor)
EndFunction

Bool Function IsOStimDetected() Global
    Return Game.GetModByName("OStim.esp") != 255
EndFunction

Bool Function IsDialogueEnabled() Global
    Return MMEAlertsController.IsExtensionsEnabled() && IsOStimDetected() && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) == 1
EndFunction

Bool Function StartBreastfeeding(Actor milkSource, Actor drinker)
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimDebug", 0) == 1

    If ActiveSession
        Report(diagnostic, "this OStim breastfeeding route is already active")
        Return False
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled()
        Report(diagnostic, "MME Extensions is disabled")
        Return False
    EndIf
    If !IsOStimDetected()
        Report(diagnostic, "OStim not detected")
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

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, "MME backend unavailable")
        Return False
    EndIf
    If milkController.MilkMaid == None || milkController.MilkMaid.Find(milkSource) == -1
        Report(diagnostic, GetActorName(milkSource) + " is not an MME Milk Maid")
        Return False
    EndIf
    ActorBase milkSourceBase = milkSource.GetLeveledActorBase()
    If milkSourceBase == None || (milkSourceBase.GetSex() != 1 && !(milkSourceBase.GetSex() == 0 && milkController.MaleMaids))
        Report(diagnostic, GetActorName(milkSource) + " is not eligible under MME's Milk Maid sex settings")
        Return False
    EndIf
    If milkController.BeingMilkedPassive == None
        Report(diagnostic, "MME passive-milking state spell is unavailable")
        Return False
    EndIf
    If milkSource.HasSpell(milkController.BeingMilkedPassive)
        Report(diagnostic, GetActorName(milkSource) + " is already being milked")
        Return False
    EndIf

    Actor[] actors = new Actor[2]
    ; OStim action actor 0 drinks from target 1. MME Mode 4 receives target 1.
    actors[0] = drinker
    actors[1] = milkSource
    String sceneID = MMEOStimIntegration.FindSemanticScene(actors, 0, 1, "suckingnipples", diagnostic)
    If sceneID == ""
        Return False
    EndIf

    BeginSession(milkSource, milkController.BeingMilkedPassive, sceneID, diagnostic)
    Int threadID = MMEOStimIntegration.StartManualScene(actors, sceneID, "MMEExtensions,Breastfeeding", diagnostic)
    If threadID < 0
        EndSession()
        Return False
    EndIf
    ActiveThreadID = threadID

    If !WaitForExpectedScene()
        If ActiveOwnsThread
            MMEOStimIntegration.StopThread(ActiveThreadID)
        EndIf
        Report(diagnostic, "OStim did not enter the selected breastfeeding scene")
        EndSession()
        Return False
    EndIf

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

    ActiveLaunching = False
    ; MME has a few valid Mode 4 early exits that remove its passive spell but
    ; return before MME_MilkingDone. This temporary watchdog is only active for
    ; the interaction and supplies cleanup if either mod event is missed.
    RegisterForSingleUpdate(1.0)
    Debug.Trace("[MME Extensions OStim] started " + sceneID + " | drinker=" + GetActorName(drinker) + " | milk source=" + GetActorName(milkSource) + " | thread=" + threadID)
    Return True
EndFunction

Function BeginSession(Actor milkSource, Spell passiveSpell, String sceneID, Bool diagnostic)
    ActiveSession = True
    ActiveOwnsThread = True
    ActiveMMERequested = False
    ActiveMMEStarted = False
    ActiveMMECompleted = False
    ActiveLaunching = True
    ActiveDiagnostic = diagnostic
    ; Every current dialogue route includes the player, whose OStim thread ID is
    ; documented as 0. The builder's returned ID replaces this provisional ID.
    ActiveThreadID = 0
    ActiveSceneID = sceneID
    ActiveMilkSource = milkSource
    ActivePassiveSpell = passiveSpell
    RegisterForModEvent("ostim_thread_scenechanged", "OnOStimThreadSceneChanged")
    RegisterForModEvent("ostim_thread_end", "OnOStimThreadEnd")
    ; Main-thread fallbacks retain compatibility with OStim versions predating
    ; the thread-specific scene-change event.
    RegisterForModEvent("ostim_scenechanged", "OnOStimSceneChanged")
    RegisterForModEvent("ostim_end", "OnOStimEnd")
    RegisterForModEvent("MME_MilkingDone", "OnMMEMilkingDone")
EndFunction

Function EndSession()
    UnregisterForModEvent("ostim_thread_scenechanged")
    UnregisterForModEvent("ostim_thread_end")
    UnregisterForModEvent("ostim_scenechanged")
    UnregisterForModEvent("ostim_end")
    UnregisterForModEvent("MME_MilkingDone")
    UnregisterForUpdate()
    ActiveThreadID = -1
    ActiveSceneID = ""
    ActiveMilkSource = None
    ActivePassiveSpell = None
    ActiveSession = False
    ActiveOwnsThread = False
    ActiveMMERequested = False
    ActiveMMEStarted = False
    ActiveMMECompleted = False
    ActiveLaunching = False
    ActiveDiagnostic = False
EndFunction

Bool Function WaitForExpectedScene()
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
    Return MMEOStimIntegration.OwnsManualScene(ActiveThreadID, ActiveSceneID)
EndFunction

Function RelinquishOwnership(String reason)
    If !ActiveSession
        Return
    EndIf
    Bool wasOwned = ActiveOwnsThread
    ActiveOwnsThread = False
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
    If ActiveSession && ActiveThreadID == 0 && sceneID != ActiveSceneID
        RelinquishOwnership("OStim player thread changed to " + sceneID)
    EndIf
EndEvent

Event OnOStimThreadEnd(String eventName, String json, Float threadID, Form sender)
    If ActiveSession && threadID as Int == ActiveThreadID
        RelinquishOwnership("OStim breastfeeding thread ended")
    EndIf
EndEvent

Event OnOStimEnd(String eventName, String json, Float numArg, Form sender)
    If ActiveSession && ActiveThreadID == 0
        RelinquishOwnership("OStim breastfeeding thread ended")
    EndIf
EndEvent

Event OnMMEMilkingDone(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    If !ActiveSession || !ActiveMMERequested || actorForm as Actor != ActiveMilkSource
        Return
    EndIf

    ActiveMMECompleted = True
    ActiveMMEStarted = False
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

Event OnUpdate()
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

    If ActiveOwnsThread && !StillOwnsThread()
        RelinquishOwnership("OStim breastfeeding scene ended, changed, or entered auto mode")
    EndIf
    If ActiveSession && ActiveOwnsThread && ActiveMMEStarted
        RegisterForSingleUpdate(1.0)
    Else
        EndSession()
    EndIf
EndEvent

Bool Function IsActorAvailable(Actor target) Global
    Return target != None && !target.IsDead() && !target.IsDisabled() && target.Is3DLoaded()
EndFunction

; Mirrors MME's SexLab breastfeeding hook behavior that Mode 4 itself omits.
Function ApplyMMEBreastfeedingParity(Actor milkSource, Actor drinker, MilkQUEST milkController) Global
    If MME_Storage.getMilkCurrent(milkSource) < 1.0
        Return
    EndIf

    If milkController.MME_Milk_Basic != None
        Form basicMilk = milkController.MME_Milk_Basic.GetAt(0)
        If basicMilk != None
            drinker.EquipItem(basicMilk, True, True)
        EndIf
    EndIf

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
