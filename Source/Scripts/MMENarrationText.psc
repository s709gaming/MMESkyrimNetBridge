Scriptname MMENarrationText Hidden

; Pure text/configuration boundary. No SkyrimNetApi import or gameplay mutation.
String Function FilePath(String fileKey) Global
    Return "MMEAlerts/Narration/" + fileKey
EndFunction

String Function StateKey(String fileKey) Global
    Return "MMEExtensions.Narration.Load." + fileKey
EndFunction

Function Report(String fileKey, String routeKey, String reason, Bool failure = False) Global
    String reportKey = "MMEExtensions.Narration.Report." + fileKey
    Int level = 1
    If failure
        level = 2
    EndIf
    If StorageUtil.GetIntValue(None, reportKey, 0) >= level
        Return
    EndIf
    StorageUtil.SetIntValue(None, reportKey, level)
    String detail = "[MME Narration JSON] operation=load/render | file=" + fileKey + " | route=" + routeKey + " | " + reason
    If failure
        MMELog.Alarm(detail)
    Else
        MMELog.MasterDiagnostic(detail)
    EndIf
EndFunction

Int Function LoadFile(String fileKey) Global
    Int loadState = StorageUtil.GetIntValue(None, StateKey(fileKey), 0)
    If loadState != 0
        Return loadState
    EndIf
    String path = FilePath(fileKey)
    loadState = -1
    If JsonUtil.JsonExists(path)
        Bool loaded = JsonUtil.Load(path)
        If loaded && JsonUtil.IsGood(path) && JsonUtil.GetPathIntValue(path, ".schemaVersion", 0) == 1
            loadState = 1
        Else
            loadState = -2
            Report(fileKey, "", "malformed JSON or unsupported schema; using defaults | " + JsonUtil.GetErrors(path), True)
        EndIf
    Else
        Report(fileKey, "", "customization file absent; using compiled defaults")
    EndIf
    StorageUtil.SetIntValue(None, StateKey(fileKey), loadState)
    Return loadState
EndFunction

String Function CanonicalToken(String token) Global
    If token == "ACTOR" || token == "ActorName"
        Return "actor"
    EndIf
    Return token
EndFunction

Bool Function IsBlank(String value) Global
    Int charIndex = 0
    While charIndex < StringUtil.GetLength(value)
        Int code = StringUtil.AsOrd(StringUtil.Substring(value, charIndex, 1))
        If code != 32 && code != 9 && code != 10 && code != 13
            Return False
        EndIf
        charIndex += 1
    EndWhile
    Return True
EndFunction

; Skyrim interns strings case-insensitively. See EditingGuide's import caveat.
Bool Function SameText(String first, String second) Global
    Return first == second
EndFunction

Bool Function ValidTemplate(String fileKey, String routeKey, String value) Global
    String allowed = MMENarrationDefaults.Tokens(fileKey, routeKey)
    If IsBlank(value) || allowed == ""
        Return False
    EndIf
    String seen = "|"
    Int strayClose = StringUtil.Find(value, "}")
    Int position = 0
    Int openIndex = StringUtil.Find(value, "{", position)
    While openIndex >= 0
        If strayClose >= 0 && strayClose < openIndex
            Return False
        EndIf
        Int closeIndex = StringUtil.Find(value, "}", openIndex + 1)
        If closeIndex < 0
            Return False
        EndIf
        String token = CanonicalToken(StringUtil.Substring(value, openIndex + 1, closeIndex - openIndex - 1))
        If token == "" || StringUtil.Find(allowed, "|" + token + "|") < 0
            Return False
        EndIf
        If StringUtil.Find(seen, "|" + token + "|") < 0
            seen += token + "|"
        EndIf
        position = closeIndex + 1
        strayClose = StringUtil.Find(value, "}", position)
        openIndex = StringUtil.Find(value, "{", position)
    EndWhile
    If strayClose >= 0
        Return False
    EndIf
    ; Require every fact/identity placeholder in the documented default.
    position = 1
    Int delimiter = StringUtil.Find(allowed, "|", position)
    While delimiter >= 0
        ; Substring length=0 means "to end", so skip empty token fields explicitly.
        If delimiter > position
            String required = StringUtil.Substring(allowed, position, delimiter - position)
            If StringUtil.Find(seen, "|" + required + "|") < 0
                Return False
            EndIf
        EndIf
        position = delimiter + 1
        delimiter = StringUtil.Find(allowed, "|", position)
    EndWhile
    Return True
EndFunction

String Function DefaultText(String fileKey, String routeKey) Global
    Int count = MMENarrationDefaults.PoolCount(fileKey, routeKey)
    Int index = 0
    If count > 0
        index = Utility.RandomInt(0, count - 1)
    EndIf
    Return MMENarrationDefaults.Template(fileKey, routeKey, index)
EndFunction

Bool Function ValidateRoute(String fileKey, String routeKey) Global
    String path = FilePath(fileKey)
    String keyPath = ".routes." + routeKey + ".template"
    If !JsonUtil.CanResolvePath(path, keyPath)
        Report(fileKey, routeKey, "entry absent; using compiled default")
        Return False
    EndIf
    Bool valid = False
    If JsonUtil.IsPathString(path, keyPath)
        valid = ValidTemplate(fileKey, routeKey, JsonUtil.GetPathStringValue(path, keyPath))
    ElseIf JsonUtil.IsPathArray(path, keyPath)
        String[] entries = JsonUtil.PathStringElements(path, keyPath)
        valid = entries.Length > 0 && entries.Length == JsonUtil.PathCount(path, keyPath)
        Int item = 0
        While valid && item < entries.Length
            valid = ValidTemplate(fileKey, routeKey, entries[item])
            item += 1
        EndWhile
    EndIf
    If !valid
        Report(fileKey, routeKey, "empty/wrong-type template or invalid placeholders; using default", True)
    EndIf
    Return valid
EndFunction

String Function GetRaw(String fileKey, String routeKey) Global
    If MMENarrationDefaults.Tokens(fileKey, routeKey) == ""
        Report(fileKey, routeKey, "unknown required route", True)
        Return ""
    EndIf
    If LoadFile(fileKey) != 1 || !ValidateRoute(fileKey, routeKey)
        Return DefaultText(fileKey, routeKey)
    EndIf
    String path = FilePath(fileKey)
    String keyPath = ".routes." + routeKey + ".template"
    If JsonUtil.IsPathArray(path, keyPath)
        String[] entries = JsonUtil.PathStringElements(path, keyPath)
        Return entries[Utility.RandomInt(0, entries.Length - 1)]
    EndIf
    Return JsonUtil.GetPathStringValue(path, keyPath)
EndFunction

; Single pass over the TEMPLATE. Inserted actor names/text are never reparsed.
String Function Render(String value, String k1 = "", String v1 = "", String k2 = "", String v2 = "", String k3 = "", String v3 = "", String k4 = "", String v4 = "", String k5 = "", String v5 = "", String k6 = "", String v6 = "") Global
    String output = ""
    Int position = 0
    Int textLength = StringUtil.GetLength(value)
    Int openIndex = StringUtil.Find(value, "{", position)
    While openIndex >= 0
        Int closeIndex = StringUtil.Find(value, "}", openIndex + 1)
        If closeIndex < 0
            Return ""
        EndIf
        String token = CanonicalToken(StringUtil.Substring(value, openIndex + 1, closeIndex - openIndex - 1))
        String replacement = ""
        If token == k1 && k1 != ""
            replacement = v1
        ElseIf token == k2 && k2 != ""
            replacement = v2
        ElseIf token == k3 && k3 != ""
            replacement = v3
        ElseIf token == k4 && k4 != ""
            replacement = v4
        ElseIf token == k5 && k5 != ""
            replacement = v5
        ElseIf token == k6 && k6 != ""
            replacement = v6
        Else
            Report("renderer", token, "required placeholder has no supplied value", True)
            Return ""
        EndIf
        If openIndex > position
            output += StringUtil.Substring(value, position, openIndex - position)
        EndIf
        output += replacement
        position = closeIndex + 1
        openIndex = StringUtil.Find(value, "{", position)
    EndWhile
    If position < textLength
        output += StringUtil.Substring(value, position)
    EndIf
    Return output
EndFunction

String Function Text(String fileKey, String routeKey, String k1 = "", String v1 = "", String k2 = "", String v2 = "", String k3 = "", String v3 = "", String k4 = "", String v4 = "", String k5 = "", String v5 = "", String k6 = "", String v6 = "") Global
    Return Render(GetRaw(fileKey, routeKey), k1, v1, k2, v2, k3, v3, k4, v4, k5, v5, k6, v6)
EndFunction

Int Function ReloadAll() Global
    Int index = 0
    Int valid = 0
    While index < MMENarrationDefaults.FileCount()
        String fileKey = MMENarrationDefaults.FileName(index)
        ; Never use Unload's default saveChanges=True on player-editable files.
        JsonUtil.Unload(FilePath(fileKey), False, False)
        StorageUtil.UnsetIntValue(None, StateKey(fileKey))
        StorageUtil.UnsetIntValue(None, "MMEExtensions.Narration.Report." + fileKey)
        If LoadFile(fileKey) == 1
            Bool complete = True
            Int routeIndex = 0
            While routeIndex < MMENarrationDefaults.RouteCount(fileKey)
                If !ValidateRoute(fileKey, MMENarrationDefaults.RouteKey(fileKey, routeIndex))
                    complete = False
                EndIf
                routeIndex += 1
            EndWhile
            If complete
                valid += 1
            EndIf
        EndIf
        index += 1
    EndWhile
    StorageUtil.UnsetIntValue(None, "MMEExtensions.Narration.Report.renderer")
    MMELog.MasterDiagnostic("[MME Narration JSON] reload complete | valid files=" + valid + "/" + index)
    Return valid
EndFunction

Bool Function IsUnchangedDefault(String fileKey, String routeKey) Global
    String path = FilePath(fileKey)
    String keyPath = ".routes." + routeKey + ".template"
    If !JsonUtil.CanResolvePath(path, keyPath)
        Return True
    EndIf
    Int count = MMENarrationDefaults.PoolCount(fileKey, routeKey)
    If count == 0
        Return JsonUtil.IsPathString(path, keyPath) && SameText(JsonUtil.GetPathStringValue(path, keyPath), MMENarrationDefaults.Template(fileKey, routeKey))
    EndIf
    String[] values = JsonUtil.PathStringElements(path, keyPath)
    If values.Length != count || JsonUtil.PathCount(path, keyPath) != count
        Return False
    EndIf
    Int index = 0
    While index < count
        If !SameText(values[index], MMENarrationDefaults.Template(fileKey, routeKey, index))
            Return False
        EndIf
        index += 1
    EndWhile
    Return True
EndFunction

; Explicit user action only. Never overwrite an already customized destination.
String Function ImportLegacy() Global
    Int index = 0
    Int imported = 0
    Int conflicts = 0
    Int invalid = 0
    While index < MMENarrationDefaults.LegacyCount()
        String fileKey = MMENarrationDefaults.TargetFile(index)
        String routeKey = MMENarrationDefaults.TargetRoute(index)
        String oldFile = "/MMEAlerts/" + MMENarrationDefaults.LegacyFile(index)
        String oldPath = MMENarrationDefaults.LegacyPath(index)
        String newPath = ".routes." + routeKey + ".template"
        If JsonUtil.JsonExists(oldFile) && !JsonUtil.IsGood(oldFile) && !JsonUtil.IsPendingSave(oldFile)
            JsonUtil.Load(oldFile)
        EndIf
        If JsonUtil.JsonExists(oldFile) && JsonUtil.IsGood(oldFile)
            If LoadFile(fileKey) != 1
                invalid += 1
            ElseIf !IsUnchangedDefault(fileKey, routeKey)
                conflicts += 1
            Else
                String value = ""
                String[] pool = JsonUtil.PathStringElements(oldFile, oldPath)
                Bool accepted = False
                If JsonUtil.IsPathArray(oldFile, oldPath) && pool.Length > 0 && JsonUtil.PathCount(oldFile, oldPath) == pool.Length
                    Int item = 0
                    accepted = True
                    While item < pool.Length
                        If !ValidTemplate(fileKey, routeKey, pool[item])
                            accepted = False
                        EndIf
                        item += 1
                    EndWhile
                    If accepted
                        JsonUtil.SetPathStringArray(FilePath(fileKey), newPath, pool, False)
                    EndIf
                Else
                    value = JsonUtil.GetPathStringValue(oldFile, oldPath, "")
                    If value == ""
                        value = JsonUtil.GetStringValue(oldFile, MMENarrationDefaults.LegacyKey(index), "")
                    EndIf
                    accepted = ValidTemplate(fileKey, routeKey, value)
                    If accepted
                        JsonUtil.SetPathStringValue(FilePath(fileKey), newPath, value)
                    EndIf
                EndIf
                If accepted
                    Bool saved = JsonUtil.Save(FilePath(fileKey), False)
                    JsonUtil.Unload(FilePath(fileKey), False, False)
                    StorageUtil.UnsetIntValue(None, StateKey(fileKey))
                    Bool verified = False
                    If saved && LoadFile(fileKey) == 1
                        If pool.Length > 0 && accepted && JsonUtil.IsPathArray(oldFile, oldPath)
                            String[] readback = JsonUtil.PathStringElements(FilePath(fileKey), newPath)
                            verified = readback.Length == pool.Length
                            Int checkIndex = 0
                            While verified && checkIndex < pool.Length
                                verified = SameText(readback[checkIndex], pool[checkIndex])
                                checkIndex += 1
                            EndWhile
                        Else
                            verified = SameText(JsonUtil.GetPathStringValue(FilePath(fileKey), newPath), value)
                        EndIf
                    EndIf
                    If verified
                        imported += 1
                        MMELog.MasterDiagnostic("[MME Narration JSON] legacy import saved | file=" + fileKey + " | route=" + routeKey)
                    Else
                        invalid += 1
                        Report(fileKey, routeKey, "legacy import save/readback failed; discarding pending edits", True)
                        JsonUtil.Unload(FilePath(fileKey), False, False)
                        StorageUtil.UnsetIntValue(None, StateKey(fileKey))
                    EndIf
                Else
                    invalid += 1
                    Report(fileKey, routeKey, "legacy text was invalid; import skipped", True)
                EndIf
            EndIf
        EndIf
        index += 1
    EndWhile
    Return "Imported " + imported + " routes. Kept " + conflicts + " customized routes. Skipped " + invalid + " invalid/unavailable entries. Old files were preserved."
EndFunction

