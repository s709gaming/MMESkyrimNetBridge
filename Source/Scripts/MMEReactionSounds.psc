Scriptname MMEReactionSounds Hidden

; Stable SOUN marker IDs authored by CreateMMEAlertMinimalSounds.pas.
Int Function GetMarkerFormID(Actor sourceActor, Int femaleMarkerFormID) Global
    If sourceActor == None
        Return femaleMarkerFormID
    EndIf

    ActorBase sourceBase = sourceActor.GetActorBase()
    If sourceBase == None || sourceBase.GetSex() != 0
        Return femaleMarkerFormID
    EndIf

    If femaleMarkerFormID == 0x000854
        Return 0x000899 ; Male Mild
    ElseIf femaleMarkerFormID == 0x000855
        Return 0x00089A ; Male Medium
    ElseIf femaleMarkerFormID == 0x000856
        Return 0x00089B ; Male Hot
    EndIf
    Return femaleMarkerFormID
EndFunction

Sound Function Resolve(Actor sourceActor, Int femaleMarkerFormID) Global
    Int localFormID = GetMarkerFormID(sourceActor, femaleMarkerFormID)
    Return Game.GetFormFromFile(localFormID, "MMEAlert.esp") as Sound
EndFunction
