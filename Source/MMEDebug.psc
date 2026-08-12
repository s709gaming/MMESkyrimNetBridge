Scriptname MMEDebug extends Quest

; Debug-only MME event listener. Attach to a running quest.

; Register the listener when its quest first initializes.
Event OnInit()
    RegisterMilkEvents()
EndEvent

; Restore the registrations whenever the quest is reset.
Event OnReset()
    RegisterMilkEvents()
EndEvent

; Subscribe this quest to MME's milking start and completion events.
Function RegisterMilkEvents()
    RegisterForModEvent("MilkQuest.StartMilkingMachine", "OnMilkStart")
    RegisterForModEvent("MME_MilkingDone", "OnMilkEnd")

    ; Confirm in-game that the debug listener initialized successfully.
    ShowMessage("ready")
EndFunction

; Report the actor supplied by MME when a milking session begins.
Event OnMilkStart(Form actorForm, Int mpas, Int milkingType)
    ; MME sends a generic Form, so convert it to an Actor before using it.
    Actor akActor = actorForm as Actor

    ; Stop safely if the event did not contain a valid actor reference.
    If akActor == None
        ShowMessage("START: <invalid actor>")
        Return
    EndIf

    ; Show the resolved actor name in-game and in the Papyrus log.
    ShowMessage("START: " + GetActorName(akActor))
EndEvent

; Report the actor and bottle count when a milking session completes.
Event OnMilkEnd(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    ; MME sends a generic Form, so convert it to an Actor before using it.
    Actor akActor = actorForm as Actor

    ; Stop safely if the event did not contain a valid actor reference.
    If akActor == None
        ShowMessage("END: <invalid actor>")
        Return
    EndIf

    ; Show who finished milking and how many bottles MME reported.
    ShowMessage("END: " + GetActorName(akActor) + " (" + bottles + " bottles)")
EndEvent

; Convert an Actor reference into safe, readable debug text.
String Function GetActorName(Actor akActor)
    ; Protect callers that pass an empty actor reference.
    If akActor == None
        Return "<None>"
    EndIf

    ; Read the actor's display name and provide a fallback when it is blank.
    String actorName = akActor.GetName()
    If actorName == ""
        Return "<Unnamed>"
    EndIf

    Return actorName
EndFunction

; Send the same identified MMEAlert message to the HUD and Papyrus log.
Function ShowMessage(String text)
    Debug.Notification("MMEAlert - " + text)
    Debug.Trace("[MMEAlert] " + text)
EndFunction
