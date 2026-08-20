Scriptname MMEOStimIntegration Hidden

; Keeps direct OStim API calls in one optional integration boundary. Nothing in
; this source is installed in place of OStim's real scripts.
String Function FindSemanticScene(Actor[] actors, Int actorPosition, Int targetPosition, String actionType, Bool diagnostic = False) Global
    If actors == None || !OActor.VerifyActors(actors)
        Report(diagnostic, "OStim rejected one or more actors")
        Return ""
    EndIf

    String sceneID = OLibrary.GetRandomSceneWithActionForActorAndTarget(actors, actorPosition, targetPosition, actionType)
    If sceneID == ""
        Report(diagnostic, "no compatible OStim " + actionType + " scene found")
    EndIf
    Return sceneID
EndFunction

Int Function StartManualScene(Actor[] actors, String sceneID, String metadata, Bool diagnostic = False) Global
    If actors == None || sceneID == ""
        Report(diagnostic, "invalid actors or scene passed to OStim")
        Return -1
    EndIf

    Int builderID = OThreadBuilder.Create(actors)
    If builderID < 0
        Report(diagnostic, "OStim scene builder rejected the actors")
        Return -1
    EndIf

    OThreadBuilder.SetStartingAnimation(builderID, sceneID)
    OThreadBuilder.NoFurniture(builderID)
    ; Prevent OStim's normal automatic progression without blocking deliberate
    ; player navigation or another integration taking control of the thread.
    OThreadBuilder.NoAutoMode(builderID)
    If metadata != ""
        OThreadBuilder.SetMetadataCSV(builderID, metadata)
    EndIf

    Int threadID = OThreadBuilder.Start(builderID)
    If threadID < 0
        OThreadBuilder.Cancel(builderID)
        Report(diagnostic, "OStim scene start rejected for " + sceneID)
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
    Return threadID >= 0 && expectedSceneID != "" && OThread.IsRunning(threadID) && OThread.GetScene(threadID) == expectedSceneID && !OThread.IsInAutoMode(threadID)
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

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MME Extensions OStim] " + reportText)
    If showNotification
        Debug.Notification("OStim Debug: " + reportText)
    EndIf
EndFunction
