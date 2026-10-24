;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname JUGS__03001358 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
actor[] sexActors = new actor[2]
sexActors[1] = Game.GetPlayer()
sexActors[0] = akSpeaker
sslBaseAnimation[] anims
anims = new sslBaseAnimation[1]
anims[0] = SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar")
MMEJugsSafety.TryStart(SexLab, sexActors, anims, "JUGS__03001358")
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SexLabFramework Property SexLab  Auto
JugsMain Property Jugs Auto

