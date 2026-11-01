Scriptname MMEFlavorText Hidden

; Event-only wording facade. The caller already owns every gameplay decision.
String Function Select(String pool, Actor subject) Global
    String fileName = "/MMEAlerts/FlavorNotifications"
    String[] personal = MMENarrationOverrides.PersonalPool(fileName, pool, subject)
    If personal.Length == 1
        Return personal[0]
    EndIf
    ; Initial shipped pools contain one variant: do not consume a random roll.
    If personal.Length == 0 && JsonUtil.JsonExists(fileName) && JsonUtil.IsGood(fileName)
        String poolPath = "." + pool
        If JsonUtil.IsPathArray(fileName, poolPath) && JsonUtil.PathCount(fileName, poolPath) == 1
            If JsonUtil.IsPathString(fileName, poolPath + "[0]")
                String single = JsonUtil.GetPathStringValue(fileName, poolPath + "[0]", "")
                If !MMETextPool.IsBlank(single)
                    MMENarrationOverrides.TraceSource("Pools.FlavorNotifications." + pool, "base", 1, subject)
                    Return single
                EndIf
            EndIf
        EndIf
    EndIf
    ; Existing reader owns multi-variant weighting, legacy lists and file failures.
    Return MMETextPool.Pick(fileName, pool, "", subject, "FlavorNotifications." + pool)
EndFunction

Bool Function ValidTemplate(String template, String k1 = "", String k2 = "") Global
    If MMETextPool.IsBlank(template)
        Return False
    EndIf
    If k1 != "" && StringUtil.Find(template, "{" + k1 + "}") < 0
        Return False
    EndIf
    If k2 != "" && StringUtil.Find(template, "{" + k2 + "}") < 0
        Return False
    EndIf
    Int position = 0
    Int openIndex = StringUtil.Find(template, "{", position)
    Int closeIndex = StringUtil.Find(template, "}", position)
    While openIndex >= 0
        If closeIndex < openIndex
            Return False
        EndIf
        String token = StringUtil.Substring(template, openIndex + 1, closeIndex - openIndex - 1)
        If token == "" || (token != k1 && token != k2)
            Return False
        EndIf
        position = closeIndex + 1
        openIndex = StringUtil.Find(template, "{", position)
        closeIndex = StringUtil.Find(template, "}", position)
    EndWhile
    Return closeIndex < 0
EndFunction

String Function Text(String pool, String fallbackText, Actor subject = None, String k1 = "", String v1 = "", String k2 = "", String v2 = "") Global
    String template = Select(pool, subject)
    If ValidTemplate(template, k1, k2)
        String rendered = MMENarrationText.Render(template, k1, v1, k2, v2)
        If !MMETextPool.IsBlank(rendered)
            Return rendered
        EndIf
        MMETextPool.ReportFailure("/MMEAlerts/FlavorNotifications", pool, subject, "flavor rendering returned blank text")
    ElseIf !MMETextPool.IsBlank(template)
        MMETextPool.ReportFailure("/MMEAlerts/FlavorNotifications", pool, subject, "flavor template has missing, unsupported or malformed placeholders")
    EndIf
    MMENarrationOverrides.TraceSource("Pools.FlavorNotifications." + pool, "compiled fallback", 1, subject)
    If MMETextPool.IsBlank(fallbackText)
        MMETextPool.ReportFailure("/MMEAlerts/FlavorNotifications", pool, subject, "compiled flavor fallback is blank")
    EndIf
    ; Already rendered by the original caller. Never reinterpret braces in names.
    Return fallbackText
EndFunction
