Scriptname SexLabFramework extends Quest

; Compile-time shim only. The installed SexLab framework provides the runtime API.
sslAnimationSlots Property AnimSlots Auto

sslThreadModel Function NewThread(Float timeout = 30.0)
    Return None
EndFunction

Int Function StartSex(Actor[] positions, sslBaseAnimation[] animations, Actor victim = None, ObjectReference centerOn = None, Bool allowBed = True, String hook = "")
    Return -1
EndFunction

Bool Function IsStrippable(Form ItemRef)
    Return True
EndFunction

Bool Function IsActorActive(Actor ActorRef)
    Return False
EndFunction
