Scriptname SexLabFramework extends Quest

sslAnimationSlots Property AnimSlots Auto

Int Function StartSex(Actor[] positions, sslBaseAnimation[] animations, Actor victim = None, ObjectReference centerOn = None, Bool allowBed = True, String hook = "")
EndFunction

Bool Function IsValidActor(Actor actorRef)
EndFunction

sslBaseAnimation Function HookAnimation(Int threadID)
EndFunction

Actor[] Function HookActors(Int threadID)
EndFunction

sslBaseAnimation[] Function GetAnimationsByTags(Int actorCount, String tags, String suppress = "", Bool requireAll = True)
EndFunction

sslBaseAnimation Function GetAnimationByName(String animationName)
EndFunction
