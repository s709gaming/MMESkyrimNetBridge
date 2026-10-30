Scriptname MMENarrationOverrides Hidden

; Memory-only personal overlay. Gameplay readers retain their rolls/renderers/fallbacks.
String[] Function Values(String entryId) Global
    If SKSE.GetPluginVersion("MMEExtensions") >= 0
        String failure = MMEExtensionsNative.GetNarrationEditorFailure()
        String reportKey = "MMEExtensions.Narration.RuntimeFailure"
        If StorageUtil.GetStringValue(None, reportKey, "") != failure
            StorageUtil.SetStringValue(None, reportKey, failure)
            If failure != ""
                MMELog.Alarm("[MME Narration Editor] operation=resolve | actor=N/A | reason=" + failure)
            EndIf
        EndIf
        Return MMEExtensionsNative.GetNarrationOverrideValues(entryId)
    EndIf
    Return Utility.CreateStringArray(0)
EndFunction

String Function FileKey(String fileName) Global
    String result = fileName
    If StringUtil.Find(result, "/MMEAlerts/") == 0
        result = StringUtil.Substring(result, StringUtil.GetLength("/MMEAlerts/"))
    ElseIf StringUtil.Find(result, "MMEAlerts/") == 0
        result = StringUtil.Substring(result, StringUtil.GetLength("MMEAlerts/"))
    EndIf
    Int extension = StringUtil.Find(result, ".json")
    If extension > 0
        result = StringUtil.Substring(result, 0, extension)
    EndIf
    Return result
EndFunction

Bool Function HasFileOverrides(String fileName) Global
    If SKSE.GetPluginVersion("MMEExtensions") >= 0
        Return MMEExtensionsNative.HasNarrationPoolOverrides(FileKey(fileName))
    EndIf
    Return False
EndFunction

Bool Function FileAvailable(String fileName) Global
    Return HasFileOverrides(fileName) || (JsonUtil.JsonExists(fileName) && JsonUtil.IsGood(fileName))
EndFunction

String[] Function PersonalPool(String fileName, String poolName, Actor subject = None) Global
    If StringUtil.Find(poolName, ".") == 0
        poolName = StringUtil.Substring(poolName, 1)
    EndIf
    String entryId = "Pools." + FileKey(fileName) + "." + poolName
    String[] encoded = Values(entryId)
    Int count = encoded.Length - 1
    If count < 1
        Return Utility.CreateStringArray(0)
    EndIf
    String[] result = Utility.CreateStringArray(count)
    Int index = 0
    While index < count
        result[index] = encoded[index + 1]
        index += 1
    EndWhile
    TraceSource(entryId, "personal", count, subject)
    Return result
EndFunction

String[] Function Pool(String fileName, String poolPath, Actor subject = None) Global
    String[] personal = PersonalPool(fileName, poolPath, subject)
    If personal.Length > 0
        Return personal
    EndIf
    String[] baseValues = JsonUtil.PathStringElements(fileName, poolPath)
    TraceSource("Pools." + FileKey(fileName) + poolPath, "base", baseValues.Length, subject)
    Return baseValues
EndFunction

Function TraceSource(String entryId, String sourceKind, Int count, Actor subject = None) Global
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePapyrusTrace", 0) != 1
        Return
    EndIf
    String revision = "native-absent"
    If SKSE.GetPluginVersion("MMEExtensions") >= 0
        revision = MMEExtensionsNative.GetNarrationRevision()
    EndIf
    String reportKey = "MMEExtensions.Narration.Source." + entryId
    String sourceStamp = sourceKind + revision
    If StorageUtil.GetStringValue(subject, reportKey, "") == sourceStamp
        Return
    EndIf
    StorageUtil.SetStringValue(subject, reportKey, sourceStamp)
    MMELog.MasterDiagnostic("[MME Narration Editor] operation=resolve | entry=" + entryId + " | source=" + sourceKind + " | variants=" + count + " | actor=" + subject + " | revision=" + revision)
EndFunction
