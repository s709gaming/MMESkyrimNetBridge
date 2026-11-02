; Compile-only projection for the original MME override. Never shipped.
; The real helper is compiled separately from Source/Scripts/MMEMilkingSource.psc.
Scriptname MMEMilkingSource Hidden

Int Function Begin(Actor target, Int mode, Armor equipment) Global
    Return 0
EndFunction

Function Complete(Actor target, Int sessionId, Int bottles, Int boobgasms, Int cumCount) Global
EndFunction

; The completion publisher queries this existing public facade while the
; original MME override is compiled. Runtime implementation remains separate.
String Function MethodName(Int method) Global
    Return "Generic"
EndFunction
