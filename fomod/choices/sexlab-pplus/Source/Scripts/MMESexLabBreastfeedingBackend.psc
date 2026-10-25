Scriptname MMESexLabBreastfeedingBackend Hidden

; SexLab P+ implementation selected manually through the FOMOD compatibility
; option. P+-only types stay in this facade.

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
        MMELog.Alarm("[MME Extensions SexLab P+] breastfeeding backend unavailable or received a missing actor | hook=" + hookName)
        Return -1
    EndIf
    String sceneID = GetLesbianScene()
    Int drinkerSex = SexlabRegistry.GetSex(drinker, False)
    If drinkerSex == 0 || drinkerSex == 2
        sceneID = GetStraightScene()
    EndIf
    Actor[] participants = new Actor[2]
    participants[0] = milkSource
    participants[1] = drinker
    String[] scenes = new String[1]
    scenes[0] = sceneID
    MMELog.MasterDiagnostic("[MME Extensions SexLab P+] backend request | milkSource=" + milkSource.GetDisplayName() + " | drinker=" + drinker.GetDisplayName() + " | drinkerSex=" + drinkerSex + " | scene=" + sceneID + " | hook=" + hookName)
    If !SexlabRegistry.ValidateScene(sceneID, participants, "", milkSource)
        MMELog.Alarm("[MME Extensions SexLab P+] scene validation failed | milkSource=" + milkSource.GetDisplayName() + " | drinker=" + drinker.GetDisplayName() + " | scene=" + sceneID + " | hook=" + hookName)
        Return -1
    EndIf
    SexLabThread thread = milkController.SexLab.StartSceneEx(participants, scenes, milkSource, "MME Extensions Breastfeeding", None, 0, hookName)
    If thread == None
        MMELog.Alarm("[MME Extensions SexLab P+] scene startup failed | milkSource=" + milkSource.GetDisplayName() + " | drinker=" + drinker.GetDisplayName() + " | scene=" + sceneID + " | hook=" + hookName)
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
