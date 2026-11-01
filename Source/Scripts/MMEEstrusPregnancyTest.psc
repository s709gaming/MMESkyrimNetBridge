Scriptname MMEEstrusPregnancyTest Hidden

String Function TypeName(Int kind) Global
    If kind == 1
        Return "Spider"
    ElseIf kind == 2
        Return "Dwemer"
    EndIf
    Return "Chaurus"
EndFunction

String Function RunTest(Int kind) Global
    MMELog.MasterDiagnostic("[MME Extensions Estrus Test] entry/skip | player-only | compatibility option not installed")
    Debug.Notification("Estrus test: install Estrus Unified pregnancy support in the FOMOD.")
    Return "Compatibility option missing"
EndFunction
