Scriptname TIF_MMEExtFollowerArmorRescue extends TopicInfo Hidden

Function Fragment_RescueFollowerArmor(ObjectReference akSpeakerRef)
    MMELog.MasterDiagnostic("[MME Extensions Follower Armor Rescue] dedicated INFO begin fragment entered")
    GlobalVariable dialogueState = Game.GetFormFromFile(0x0008AA, "MMEAlert.esp") as GlobalVariable
    If dialogueState != None
        dialogueState.SetValue(0.0)
    Else
        MMELog.Alarm("[MME Extensions Follower Armor Rescue] FAILURE: dedicated INFO could not resolve dialogue-state Global")
    EndIf

    Actor blacksmith = akSpeakerRef as Actor
    Bool serviceSucceeded = False
    If blacksmith == None
        MMELog.Alarm("[MME Extensions Follower Armor Rescue] FAILURE: dedicated INFO received no blacksmith")
    Else
        serviceSucceeded = MMEFollowerArmorRescue.TryRescueNearbyCompanions(blacksmith)
    EndIf
    PublishVendorResult(blacksmith, serviceSucceeded)
EndFunction

Function Fragment_RescueFollowerArmorCompleted(ObjectReference akSpeakerRef)
    ; Keep the retired transient gate cleared on old saves. Visibility is now
    ; static; the service always revalidates live actors and armor on selection.
    ClearLegacyDialogueState()
    ; TopicInfo begin/end fragments do not reliably share instance fields.
    ; Removal belongs exclusively to OnBegin; the persistent MMEDebug bus owns
    ; any pending animation state and safely ignores an end with no request.
    MMEDebug service = MMEDiagnostics.GetDebugService()
    If service != None
        service.ObserveVendorServiceInfoEnd(akSpeakerRef as Actor)
    Else
        MMELog.Alarm("[MME Extensions Follower Armor Rescue] FAILURE: vendor completion service is unavailable")
    EndIf
    MMELog.MasterDiagnostic("[MME Extensions Follower Armor Rescue] dedicated INFO end fragment complete")
EndFunction

Function PublishVendorResult(Actor blacksmith, Bool serviceSucceeded)
    ClearLegacyDialogueState()
    MMEDebug service = MMEDiagnostics.GetDebugService()
    If service != None
        service.HandleVendorServiceResult(blacksmith, "Blacksmith/RescueFollowerArmor", serviceSucceeded)
    Else
        MMELog.Alarm("[MME Extensions Follower Armor Rescue] FAILURE: vendor animation service is unavailable")
    EndIf
EndFunction

Function ClearLegacyDialogueState()
    GlobalVariable dialogueState = Game.GetFormFromFile(0x0008AA, "MMEAlert.esp") as GlobalVariable
    If dialogueState != None
        dialogueState.SetValue(0.0)
    Else
        MMELog.Alarm("[MME Extensions Follower Armor Rescue] FAILURE: could not clear legacy dialogue-state Global")
    EndIf
EndFunction
