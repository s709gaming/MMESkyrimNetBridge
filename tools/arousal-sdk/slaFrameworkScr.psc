Scriptname slaFrameworkScr extends Quest

; Compile-only declaration for the compatibility API implemented by supported
; SexLab Aroused, OSL Aroused, and SLA NG installations. Never package this.
Int Function GetActorArousal(Actor akRef)
    Return -2
EndFunction

Int Function UpdateActorExposure(Actor akRef, Int modVal, String debugMsg = "")
    Return -2
EndFunction
