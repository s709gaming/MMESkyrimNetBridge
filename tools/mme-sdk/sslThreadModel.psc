Scriptname sslThreadModel extends Quest

Int Property tid Auto
Actor[] Property Positions Auto
sslBaseAnimation Property Animation Auto Hidden

Int Function AddActor(Actor actorRef, Bool isVictim = False)
    Return -1
EndFunction

Function SetAnimations(sslBaseAnimation[] animations)
EndFunction

Function SetHook(String hookName)
EndFunction

sslThreadController Function StartThread()
    Return None
EndFunction

Function Initialize()
EndFunction

Bool Function HasTag(String tag)
    Return False
EndFunction
