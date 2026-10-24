;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname JUGs_TIF__03015CF7 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
actor[] sexActors = new actor[2]
sexActors[0] = Game.GetPlayer()
sexActors[1] = akSpeaker
sslBaseAnimation[] anims
anims = new sslBaseAnimation[1]
anims[0] = SexLab.GetAnimationByName("3J Straight Breastfeeding")
MMEJugsSafety.TryStart(SexLab, sexActors, anims, "JUGs_TIF__03015CF7")
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SexLabFramework Property SexLab  Auto
JugsMain Property Jugs Auto
