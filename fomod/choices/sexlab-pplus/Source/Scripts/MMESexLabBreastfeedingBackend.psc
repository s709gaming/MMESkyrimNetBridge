Scriptname MMESexLabBreastfeedingBackend Hidden

; SexLab P+ implementation selected by the FOMOD when the converted 3jiou
; breastfeeding SLSB registry is present. P+-only types stay in this facade.

String Function GetBackendName() Global
    Return "SexLab P+"
EndFunction

Bool Function IsPPlus() Global
    Return True
EndFunction

String Function GetStraightScene() Global
    Return "e4j6zbhk"
EndFunction

String Function GetLesbianScene() Global
    Return "6otwp8mm"
EndFunction

Bool Function IsAvailable(MilkQUEST milkController) Global
    If milkController == None || milkController.SexLab == None
        Return False
    EndIf
    Return SexlabRegistry.SceneExists(GetStraightScene()) && SexlabRegistry.SceneExists(GetLesbianScene())
EndFunction

Int Function StartBreastfeeding(MilkQUEST milkController, Actor milkSource, Actor drinker, String hookName = "MMEExtensionsBreastfeeding") Global
    If !IsAvailable(milkController) || milkSource == None || drinker == None
        Return -1
    EndIf
    String sceneID = GetLesbianScene()
    ActorBase drinkerBase = drinker.GetLeveledActorBase()
    If drinkerBase != None && (SexlabRegistry.GetSex(drinker, False) == 0 || SexlabRegistry.GetSex(drinker, False) == 2)
        sceneID = GetStraightScene()
    EndIf
    Actor[] participants = new Actor[2]
    participants[0] = milkSource
    participants[1] = drinker
    String[] scenes = new String[1]
    scenes[0] = sceneID
    If !SexlabRegistry.ValidateScene(sceneID, participants, "", milkSource)
        Return -1
    EndIf
    SexLabThread thread = milkController.SexLab.StartSceneEx(participants, scenes, milkSource, "MME Extensions Breastfeeding", None, 0, hookName)
    If thread == None
        Return -1
    EndIf
    Return thread.GetThreadID()
EndFunction

Bool Function IsBreastfeedingThread(MilkQUEST milkController, sslThreadController legacyThread, Int threadID) Global
    If milkController == None || milkController.SexLab == None || threadID < 0
        Return False
    EndIf
    SexLabThread thread = milkController.SexLab.GetThread(threadID)
    If thread == None
        Return False
    EndIf
    String sceneID = thread.GetActiveScene()
    Return sceneID == GetStraightScene() || sceneID == GetLesbianScene()
EndFunction

Function EndOwnedScene(MilkQUEST milkController, Int threadID) Global
    If milkController == None || milkController.SexLab == None || threadID < 0
        Return
    EndIf
    SexLabThread thread = milkController.SexLab.GetThread(threadID)
    If thread != None
        thread.StopAnimation()
    EndIf
EndFunction
