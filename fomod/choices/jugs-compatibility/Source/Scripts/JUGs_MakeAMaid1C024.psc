Scriptname JUGs_MakeAMaid1C024 Extends TopicInfo Hidden

Function Fragment_0(ObjectReference akSpeakerRef)
    Actor target = akSpeakerRef as Actor
    If target == None
        MMELog.Alarm("[MME Extensions JUGS] make-a-maid request rejected: dialogue target missing")
        Return
    EndIf
    If MMEExtensionsAPI.IsMilkMaid(target)
        MMELog.MasterDiagnostic("[MME Extensions JUGS] make-a-maid request ignored: already a Milk Maid | actor=" + target.GetDisplayName())
        Return
    EndIf

    Bool created = MMEExtensionsAPI.TryCreateMilkMaidForcedAnimated(target)
    MMELog.MasterDiagnostic("[MME Extensions JUGS] make-a-maid result=" + created + " | actor=" + target.GetDisplayName())
EndFunction

SexLabFramework Property SexLab Auto
JugsMain Property Jugs Auto
