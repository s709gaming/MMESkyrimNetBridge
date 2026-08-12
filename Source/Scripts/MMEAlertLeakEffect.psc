Scriptname MMEAlertLeakEffect extends ActiveMagicEffect

; MMEAlertLeakEffect.psc
; -----------------------
; Minimal debug magic effect for Milk Mod Economy leak detection.
; This script is attached to the leak spell's magic effect.
; It reports when the leak effect starts and ends,
; identifies the target actor, and shows the caster if known.

Event OnEffectStart(Actor akTarget, Actor akCaster)
    ; Called when the leak effect begins on an actor.
    ; Report the leak target and who caused it.

    ; Stop safely if Skyrim did not supply an effect target.
    If akTarget == None
        ShowMessage("LEAK START: <invalid target>")
        Return
    EndIf

    ; Resolve the target and caster into readable names for the message.
    String targetName = GetActorName(akTarget)
    String casterName = GetActorName(akCaster)
    String debugText = "LEAK START: " + targetName

    ; Include the caster when known, otherwise make its absence explicit.
    If akCaster != None
        debugText += " by " + casterName
    Else
        debugText += " by <unknown caster>"
    EndIf

    ; Display and log the completed leak-start message.
    ShowMessage(debugText)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    ; Called when the leak effect ends on an actor.
    ; This gives a clear start/end pair for debugging.

    ; Stop safely if Skyrim did not supply an effect target.
    If akTarget == None
        ShowMessage("LEAK END: <invalid target>")
        Return
    EndIf

    ; Resolve the target and caster into readable names for the message.
    String targetName = GetActorName(akTarget)
    String casterName = GetActorName(akCaster)
    String debugText = "LEAK END: " + targetName

    ; Include the caster when known, otherwise make its absence explicit.
    If akCaster != None
        debugText += " by " + casterName
    Else
        debugText += " by <unknown caster>"
    EndIf

    ; Display and log the completed leak-end message.
    ShowMessage(debugText)
EndEvent

String Function GetActorName(Actor akActor)
    ; Convert an actor reference to a readable name.
    ; Use fallback text for invalid or unnamed actors.

    ; Protect callers that pass an empty actor reference.
    If akActor == None
        Return "<None>"
    EndIf

    ; Read the actor's display name and provide a fallback when it is blank.
    String name = akActor.GetName()
    If name == ""
        Return "<Unnamed>"
    EndIf
    Return name
EndFunction

Function ShowMessage(String text)
    ; Display a short debug notification and log a trace line.

    ; Prefix every output so it is visibly owned by MMEAlert.
    String debugText = "MMEAlert - " + text

    ; Send the message both to the HUD and the persistent Papyrus log.
    Debug.Notification(debugText)
    Debug.Trace("[MMEAlert] " + text)
EndFunction
