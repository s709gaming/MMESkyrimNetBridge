Scriptname MMEStoryPopup Hidden

; Shared, backend-neutral presentation facade for MME-style, game-pausing
; story boxes. Callers own feature eligibility, timing, and MCM policy.

Bool Function ShowStoryPopup(Actor subject, String storyText, String sourceLabel = "Internal") Global
    If subject == None
        Report("request rejected: subject is missing | source=" + sourceLabel)
        Return False
    EndIf
    If storyText == ""
        Report("request rejected: story text is blank | source=" + sourceLabel + " | subject=" + GetActorName(subject))
        Return False
    EndIf

    String renderedStory = RenderActorTokens(storyText, GetActorName(subject))
    If renderedStory == ""
        MMELog.Alarm("[MME Extensions Story Popup] rendered story was blank | source=" + sourceLabel + " | subject=" + GetActorName(subject))
        Return False
    EndIf

    Debug.MessageBox(renderedStory)
    Report("story displayed | source=" + sourceLabel + " | subject=" + GetActorName(subject))
    Return True
EndFunction

Bool Function ShowRandomStoryPopup(Actor subject, String configFile, String poolName, String fallbackText = "", String sourceLabel = "Internal") Global
    If subject == None
        Report("pool request rejected: subject is missing | source=" + sourceLabel)
        Return False
    EndIf
    If configFile == "" || poolName == ""
        Report("pool request rejected: file or pool is blank | source=" + sourceLabel + " | subject=" + GetActorName(subject))
        Return False
    EndIf

    If !JsonUtil.JsonExists(configFile)
        MMELog.Alarm("[MME Extensions Story Popup] story JSON is missing | source=" + sourceLabel + " | file=" + configFile + " | pool=" + poolName)
        Return ShowFallback(subject, fallbackText, sourceLabel, poolName)
    EndIf
    If !JsonUtil.IsGood(configFile)
        MMELog.Alarm("[MME Extensions Story Popup] story JSON is malformed | source=" + sourceLabel + " | file=" + configFile + " | pool=" + poolName)
        Return ShowFallback(subject, fallbackText, sourceLabel, poolName)
    EndIf

    Int entryCount = JsonUtil.StringListCount(configFile, poolName)
    If entryCount <= 0
        MMELog.Alarm("[MME Extensions Story Popup] story pool is missing or empty | source=" + sourceLabel + " | file=" + configFile + " | pool=" + poolName)
        Return ShowFallback(subject, fallbackText, sourceLabel, poolName)
    EndIf

    String selectedStory = JsonUtil.StringListGet(configFile, poolName, Utility.RandomInt(0, entryCount - 1))
    If selectedStory == ""
        MMELog.Alarm("[MME Extensions Story Popup] selected story is blank | source=" + sourceLabel + " | file=" + configFile + " | pool=" + poolName)
        Return ShowFallback(subject, fallbackText, sourceLabel, poolName)
    EndIf

    Report("story pool selected | source=" + sourceLabel + " | file=" + configFile + " | pool=" + poolName + " | entries=" + entryCount + " | subject=" + GetActorName(subject))
    Return ShowStoryPopup(subject, selectedStory, sourceLabel)
EndFunction

Bool Function ShowFallback(Actor subject, String fallbackText, String sourceLabel, String poolName) Global
    If fallbackText == ""
        Report("story request ended without fallback | source=" + sourceLabel + " | pool=" + poolName + " | subject=" + GetActorName(subject))
        Return False
    EndIf
    Report("using fallback story | source=" + sourceLabel + " | pool=" + poolName + " | subject=" + GetActorName(subject))
    Return ShowStoryPopup(subject, fallbackText, sourceLabel)
EndFunction

String Function RenderActorTokens(String storyText, String actorName) Global
    String rendered = ReplaceToken(storyText, "{actor}", actorName)
    rendered = ReplaceToken(rendered, "{ActorName}", actorName)
    Return rendered
EndFunction

String Function ReplaceToken(String sourceText, String token, String replacement) Global
    If sourceText == "" || token == ""
        Return sourceText
    EndIf

    String rendered = sourceText
    Int tokenIndex = StringUtil.Find(rendered, token)
    Int replacements = 0
    While tokenIndex >= 0 && replacements < 16
        String beforeToken = ""
        If tokenIndex > 0
            beforeToken = StringUtil.Substring(rendered, 0, tokenIndex)
        EndIf
        String afterToken = StringUtil.Substring(rendered, tokenIndex + StringUtil.GetLength(token))
        rendered = beforeToken + replacement + afterToken
        replacements += 1
        tokenIndex = StringUtil.Find(rendered, token, tokenIndex + StringUtil.GetLength(replacement))
    EndWhile
    Return rendered
EndFunction

String Function GetActorName(Actor subject) Global
    If subject == None
        Return "Unknown actor"
    EndIf
    String actorName = subject.GetDisplayName()
    If actorName == ""
        ActorBase actorBaseInfo = subject.GetLeveledActorBase()
        If actorBaseInfo != None
            actorName = actorBaseInfo.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

Function Report(String reportText) Global
    MMELog.MasterDiagnostic("[MME Extensions Story Popup] " + reportText)
EndFunction
