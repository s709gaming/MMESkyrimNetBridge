Scriptname ELV_MMNPC_Scene_milk Extends TopicInfo Hidden

Function Fragment_0(ObjectReference akSpeakerRef)
    Actor milkSource = akSpeakerRef as Actor
    Actor drinker = None
    If Alias_Customer != None
        drinker = Alias_Customer.GetActorReference()
    EndIf
    MMEElsieBreastfeeding.StartAutonomousFeed(milkSource, drinker, "ELV_MMNPC_Scene_milk")
EndFunction

ELVMain Property ELV Auto Conditional
SexLabFramework Property SexLab Auto Conditional
ReferenceAlias Property Alias_Customer Auto
