Scriptname MMEOStimIntegration Hidden

; NoFurniture is the newest API used by this route and requires OStim 7.2.
Bool Function IsSupportedVersion() Global
    Return SKSE.GetPluginVersion("OStim") >= 0x07020000
EndFunction

; Keeps direct OStim API calls in one optional integration boundary. Nothing in
; this source is installed in place of OStim's real scripts.
String Function FindSemanticScene(Actor[] actors, Int actorPosition, Int targetPosition, String actionType, Bool diagnostic = False, String context = "") Global
    If actors == None || !OActor.VerifyActors(actors)
        Report(diagnostic, context + "OStim rejected one or more actors")
        Return ""
    EndIf

    String sceneID = OLibrary.GetRandomSceneWithActionForActorAndTarget(actors, actorPosition, targetPosition, actionType)
    If sceneID == ""
        Report(diagnostic, context + "no compatible OStim " + actionType + " scene found")
    EndIf
    Return sceneID
EndFunction

Int Function StartManualScene(Actor[] actors, String sceneID, String metadata, Bool diagnostic = False, String context = "") Global
    ; Validate the already-resolved semantic request before allocating a builder.
    If actors == None || sceneID == ""
        Report(diagnostic, context + "invalid actors or scene passed to OStim")
        Return -1
    EndIf
    If !ValidatePairForCommit(actors, diagnostic, True, context)
        Return -1
    EndIf

    Int builderID = OThreadBuilder.Create(actors)
    If builderID < 0
        Report(diagnostic, context + "OStim scene builder rejected the actors")
        Return -1
    EndIf

    ; Configure a deliberately manual, furniture-free thread. NoAutoMode is an
    ; ownership invariant used by MMEOStimBreastfeeding: if auto mode later
    ; becomes active, this integration treats the thread as externally adopted.
    OThreadBuilder.SetStartingAnimation(builderID, sceneID)
    OThreadBuilder.NoFurniture(builderID)
    ; Prevent OStim's normal automatic progression without blocking deliberate
    ; player navigation or another integration taking control of the thread.
    OThreadBuilder.NoAutoMode(builderID)
    If metadata != ""
        OThreadBuilder.SetMetadataCSV(builderID, metadata)
    EndIf

    ; Start is the external API commit point. Cancel only an unstarted builder;
    ; a successfully returned thread is managed by the breastfeeding owner.
    Int threadID = OThreadBuilder.Start(builderID)
    If threadID < 0
        OThreadBuilder.Cancel(builderID)
        Report(diagnostic, context + "OStim scene start rejected for " + sceneID)
    EndIf
    Return threadID
EndFunction

Bool Function IsThreadRunning(Int threadID) Global
    Return threadID >= 0 && OThread.IsRunning(threadID)
EndFunction

String Function GetThreadScene(Int threadID) Global
    If threadID < 0
        Return ""
    EndIf
    Return OThread.GetScene(threadID)
EndFunction

Bool Function OwnsManualScene(Int threadID, String expectedSceneID) Global
    ; Ownership requires all three facts: running thread, unchanged scene, and
    ; manual mode. Thread identity alone is unsafe because OStim reuses a live
    ; thread while other integrations or the player change its contents.
    Return threadID >= 0 && expectedSceneID != "" && OThread.IsRunning(threadID) && OThread.GetScene(threadID) == expectedSceneID && !OThread.IsInAutoMode(threadID)
EndFunction

Bool Function OwnsManualSceneForActors(Int threadID, String expectedSceneID, Actor firstActor, Actor secondActor) Global
    If !OwnsManualScene(threadID, expectedSceneID) || firstActor == None || secondActor == None
        Return False
    EndIf
    Actor[] threadActors = OThread.GetActors(threadID)
    Return threadActors != None && threadActors.Length == 2 && threadActors.Find(firstActor) >= 0 && threadActors.Find(secondActor) >= 0
EndFunction

Bool Function IsThreadInAutoMode(Int threadID) Global
    Return threadID >= 0 && OThread.IsRunning(threadID) && OThread.IsInAutoMode(threadID)
EndFunction

Function StopThread(Int threadID) Global
    If threadID >= 0 && OThread.IsRunning(threadID)
        OThread.Stop(threadID)
    EndIf
EndFunction

; Optional actor-level scene check. Never touch OStim's native API unless its
; plugin is active, so the compile-time declaration is not a runtime dependency.
Bool Function IsActorInScene(Actor target) Global
    If target == None || Game.GetModByName("OStim.esp") == 255
        Return False
    EndIf
    Return OActor.IsInOStim(target)
EndFunction

Bool Function IsActorInSexLab(Actor target) Global
    If target == None || Game.GetModByName("SexLab.esm") == 255
        Return False
    EndIf
    Faction animatingFaction = Game.GetFormFromFile(0x000E50F, "SexLab.esm") as Faction
    Return animatingFaction != None && target.IsInFaction(animatingFaction)
EndFunction

Bool Function IsActorBusy(Actor target) Global
    Return IsActorInScene(target) || IsActorInSexLab(target)
EndFunction

; Rechecked at the final framework commit boundary. OStimNet uses the same
; same-cell and cross-framework rules to prevent delayed Skyrim.Net actions
; from stealing actors whose world state changed after action selection.
Bool Function ValidatePairForCommit(Actor[] actors, Bool diagnostic = False, Bool requireOStimVerification = False, String context = "") Global
    If actors == None || actors.Length != 2 || actors[0] == None || actors[1] == None || actors[0] == actors[1]
        Report(diagnostic, context + "invalid source/drinker pair at scene commit")
        Return False
    EndIf
    If actors[0].IsDead() || actors[0].IsDisabled() || !actors[0].Is3DLoaded() || actors[1].IsDead() || actors[1].IsDisabled() || !actors[1].Is3DLoaded()
        Report(diagnostic, context + "source or drinker became unavailable before scene commit")
        Return False
    EndIf
    If actors[0].IsChild() || actors[1].IsChild()
        Report(diagnostic, context + "OStim/SexLab breastfeeding does not accept child actors")
        Return False
    EndIf
    Cell firstCell = actors[0].GetParentCell()
    If firstCell == None || actors[1].GetParentCell() != firstCell
        Report(diagnostic, context + "source and drinker are no longer in the same cell")
        Return False
    EndIf
    If actors[0].IsInCombat() || actors[1].IsInCombat()
        Report(diagnostic, context + "source or drinker entered combat before scene commit")
        Return False
    EndIf
    If IsActorBusy(actors[0]) || IsActorBusy(actors[1])
        Report(diagnostic, context + "source or drinker is already controlled by OStim or SexLab")
        Return False
    EndIf
    If requireOStimVerification && !OActor.VerifyActors(actors)
        Report(diagnostic, context + "OStim rejected source or drinker during final verification")
        Return False
    EndIf
    Return True
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MME Extensions OStim] " + reportText)
    If showNotification
        Debug.Notification("OStim Debug: " + reportText)
    EndIf
EndFunction
