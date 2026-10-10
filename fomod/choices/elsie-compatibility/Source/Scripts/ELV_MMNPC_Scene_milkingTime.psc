Scriptname ELV_MMNPC_Scene_milkingTime Extends TopicInfo Hidden

Function Fragment_2(ObjectReference akSpeakerRef)
    Actor milkSource = akSpeakerRef as Actor
    Actor drinker = None
    If Alias_Customer != None
        drinker = Alias_Customer.GetActorReference()
    EndIf
    MMEElsieBreastfeeding.StartAutonomousFeed(milkSource, drinker, "ELV_MMNPC_Scene_milkingTime")
EndFunction

Function Fragment_0(ObjectReference akSpeakerRef)
EndFunction

ELVMain Property ELV Auto Conditional
SexLabFramework Property SexLab Auto Conditional
ReferenceAlias Property Alias_Customer Auto
ReferenceAlias Property Alias_Maid1 Auto
