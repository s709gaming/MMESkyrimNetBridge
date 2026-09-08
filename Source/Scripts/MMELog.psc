Scriptname MMELog Hidden

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

Bool Function IsDiagnosticEnabled() Global
    String settingsFile = GetSettingsFile()
    If JsonUtil.GetIntValue(settingsFile, "enablePapyrusTrace", 0) != 1
        Return False
    EndIf
    Return JsonUtil.GetIntValue(settingsFile, "enableSpecificDiagnosticTrace", 0) == 1
EndFunction

Function Diagnostic(String reportText, Int severity = 0) Global
    If IsDiagnosticEnabled()
        Debug.Trace(reportText, severity)
    EndIf
EndFunction

Function Status(String reportText, Int severity = 0) Global
    Debug.Trace(reportText, severity)
EndFunction

Function Alarm(String reportText, Int severity = 2) Global
    Debug.Trace(reportText, severity)
EndFunction
