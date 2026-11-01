; Compile-only facade signatures; never packaged or compiled as runtime output.
; Keep paired with Source/Scripts/MMEOriginalSettings.psc.
Scriptname MMEOriginalSettings Hidden
Int Function GetMilkingMode(Actor candidate) Global
    Return -1
EndFunction
String Function MilkingModeBlockReason(Actor candidate) Global
    Return ""
EndFunction
Bool Function SetMilkingMode(Actor candidate, Int requestedMode) Global
    Return False
EndFunction
