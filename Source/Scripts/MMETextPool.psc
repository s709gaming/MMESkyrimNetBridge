Scriptname MMETextPool Hidden

; Read-only adapter for ordinary JSON arrays, with legacy typed-list support.
; A present canonical member is authoritative, even when malformed or empty.
Bool Function IsBlank(String value) Global
    Int index = 0
    While index < StringUtil.GetLength(value)
        If StringUtil.AsOrd(StringUtil.Substring(value, index, 1)) > 32
            Return False
        EndIf
        index += 1
    EndWhile
    Return True
EndFunction

Function ReportFailure(String fileName, String pool, Actor subject, String reason) Global
    String reportKey = "MMEExtensions.TextPool.Alarm." + fileName + "." + pool + "." + reason
    Float now = Utility.GetCurrentRealTime()
    Float last = StorageUtil.GetFloatValue(None, reportKey, -100.0)
    If now < last || now - last >= 60.0
        StorageUtil.SetFloatValue(None, reportKey, now)
        MMELog.Alarm("[MME Text Pool] operation=read | file=" + fileName + " | pool=" + pool + " | actor=" + subject + " | " + reason)
    EndIf
EndFunction

String Function Entry(String fileName, String pool, Int index, Bool ordinary) Global
    If ordinary
        String itemPath = "." + pool + "[" + index + "]"
        If JsonUtil.IsPathString(fileName, itemPath)
            Return JsonUtil.GetPathStringValue(fileName, itemPath, "")
        EndIf
        Return ""
    EndIf
    Return JsonUtil.StringListGet(fileName, pool, index)
EndFunction

Bool Function HasCanonicalMember(String fileName, String pool) Global
    String[] members = JsonUtil.PathMembers(fileName, ".")
    If members.Length == 0
        Return False
    EndIf
    Return members.Find(pool) >= 0
EndFunction

String Function Pick(String fileName, String pool, String fallbackText, Actor subject, String sourceLabel) Global
    String[] personal = MMENarrationOverrides.PersonalPool(fileName, pool, subject)
    If personal.Length > 0
        Return personal[Utility.RandomInt(0, personal.Length - 1)]
    EndIf
    String reason = ""
    String poolPath = "." + pool
    Bool ordinary = False
    String sourceKind = "unresolved"
    Int count = 0
    If !JsonUtil.JsonExists(fileName)
        reason = "JSON file missing"
    ElseIf !JsonUtil.IsGood(fileName)
        reason = "JSON parse failure: " + JsonUtil.GetErrors(fileName)
    ElseIf !JsonUtil.IsPathObject(fileName, ".")
        reason = "JSON root is not an object"
    ElseIf HasCanonicalMember(fileName, pool)
        ordinary = True
        sourceKind = "ordinary"
        If !JsonUtil.IsPathArray(fileName, poolPath)
            reason = "canonical member is not an array"
        Else
            count = JsonUtil.PathCount(fileName, poolPath)
        EndIf
    ElseIf JsonUtil.IsPathObject(fileName, ".stringList")
        sourceKind = "legacy"
        count = JsonUtil.StringListCount(fileName, pool)
    Else
        reason = "canonical pool absent and no valid legacy stringList section"
    EndIf
    Int validCount = 0
    Int index = 0
    If reason == "" && count > 0
        While index < count
            If !IsBlank(Entry(fileName, pool, index, ordinary))
                validCount += 1
            EndIf
            index += 1
        EndWhile
    EndIf
    Int selected = -1
    String result = fallbackText
    If reason == "" && validCount > 0
        Int rank = Utility.RandomInt(0, validCount - 1)
        index = 0
        While index < count && selected < 0
            String candidate = Entry(fileName, pool, index, ordinary)
            If !IsBlank(candidate)
                If rank == 0
                    selected = index
                    result = candidate
                EndIf
                rank -= 1
            EndIf
            index += 1
        EndWhile
        If selected < 0
            reason = "pool changed during selection"
        EndIf
    ElseIf reason == ""
        reason = "pool missing, empty, or without nonblank string entries"
    EndIf
    If reason != ""
        ReportFailure(fileName, pool, subject, reason)
    ElseIf validCount != count
        ReportFailure(fileName, pool, subject, "invalid entries skipped")
    EndIf
    MMELog.MasterDiagnostic("[MME Text Pool] source=" + sourceLabel + " | file=" + fileName + " | pool=" + pool + " | format=" + sourceKind + " | count=" + count + " | valid=" + validCount + " | index=" + selected + " | actor=" + subject + " | fallback reason=" + reason)
    Return result
EndFunction
