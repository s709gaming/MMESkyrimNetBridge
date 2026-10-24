;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 3
Scriptname JUGs_SGO__0301ADED Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_2
Function Fragment_2(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
actor[] sexActors = new actor[2]
sexActors[0] = akSpeaker
sexActors[1] = Game.GetPlayer()
sslBaseAnimation[] anims
anims = new sslBaseAnimation[1]
anims[0] = SexLab.AnimSlots.GetbyRegistrar("zjBreastfeedingVar")
If MMEJugsSafety.TryStart(SexLab, sexActors, anims, "JUGs_SGO__0301ADED")
    Jugs.JugsSGOMilker(akSpeaker, Game.getPlayer())
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
SexLabFramework Property SexLab  Auto
JugsMain Property Jugs Auto

