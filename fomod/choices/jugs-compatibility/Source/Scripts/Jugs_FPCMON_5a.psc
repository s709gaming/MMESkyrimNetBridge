;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname Jugs_FPCMON_5a Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
actor[] sexActors = new actor[2] 
sexActors[0] = Game.GetPlayer()
sexActors[1] = akSpeaker
sslBaseAnimation[] anims
anims = SexLab.GetAnimationsByTags(2, "Cowgirl, RCowgirl", "Aggressive, Anal", false)
MMEJugsSafety.TryStart(SexLab, sexActors, anims, "Jugs_FPCMON_5a")
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SexLabFramework Property SexLab  Auto
JugsMain Property Jugs Auto

