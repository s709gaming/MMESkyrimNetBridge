Scriptname MMEBlacksmithDialogue extends MME_Dialogues Hidden

; Transient choice state populated by the existing [MME] Hey there! opening:
; 0 unavailable/invalid, 1 Add, 2 Remove, 3 protected, 4 registry full.
; The Global controls visibility only. Action fragments never trust it.
GlobalVariable Property MMEExt_BlacksmithArmorState Auto
GlobalVariable Property MMEExt_AlchemistLivingArmorState Auto
GlobalVariable Property MMEExt_MageParasiteArmorState Auto
GlobalVariable Property MMEExt_MageReverseLevelAvailable Auto
GlobalVariable Property MMEExt_TrapArmorRemovalState Auto
GlobalVariable Property MMEExt_DwemerBlacksmithArmorState Auto
GlobalVariable Property MMEExt_MilkingEquipmentRefitState Auto
GlobalVariable Property MMEExt_FollowerArmorRescueState Auto
Bool serviceSucceeded = False
Bool followerRescueAttempted = False

Function Fragment_RefreshBlacksmithArmorState(ObjectReference akSpeakerRef)
    SetDialogueState(0)
    MMEAlchemistDialogue.SetDialogueState(MMEExt_AlchemistLivingArmorState, 0)
    MMEMageDialogue.SetDialogueState(MMEExt_MageParasiteArmorState, 0)
    If MMEExt_MageReverseLevelAvailable != None
        MMEExt_MageReverseLevelAvailable.SetValue(0.0)
    EndIf
    SetTrapArmorDialogueState(0)
    MMEDwemerBlacksmithDialogue.SetDialogueState(MMEExt_DwemerBlacksmithArmorState, 0)
    SetMilkingEquipmentRefitState(0)
    SetFollowerArmorRescueState(0)
    ; Preserve MME's complete opening behavior exactly once before its existing
    ; linked choices and our two new choices evaluate their conditions.
    Parent.Fragment_00(akSpeakerRef)
    If MMEExt_MageReverseLevelAvailable != None && MMEMageDialogue.CanOfferReverseLeveling(akSpeakerRef as Actor)
        MMEExt_MageReverseLevelAvailable.SetValue(1.0)
    EndIf
    SetDialogueState(GetLiveServiceState(akSpeakerRef as Actor))
    MMEAlchemistDialogue.SetDialogueState(MMEExt_AlchemistLivingArmorState, MMEAlchemistDialogue.GetLiveServiceState(akSpeakerRef as Actor))
    MMEMageDialogue.SetDialogueState(MMEExt_MageParasiteArmorState, MMEMageDialogue.GetLiveServiceState(akSpeakerRef as Actor))
    SetTrapArmorDialogueState(MMETrapArmorDialogue.GetLiveServiceState(akSpeakerRef as Actor))
    MMEDwemerBlacksmithDialogue.SetDialogueState(MMEExt_DwemerBlacksmithArmorState, MMEDwemerBlacksmithDialogue.GetLiveServiceState(akSpeakerRef as Actor))
    SetMilkingEquipmentRefitState(MMEMilkingEquipmentRefit.GetLiveServiceState(akSpeakerRef as Actor))
    SetFollowerArmorRescueState(MMEFollowerArmorRescue.GetLiveServiceState(akSpeakerRef as Actor))
    ; The live trace records the published state here, before the controller's
    ; deferred snapshot checks whether Skyrim actually exposed the expected INFO.
    MMEDiagnostics.ObserveBlacksmithDialogueState(akSpeakerRef as Actor)
    MMEDiagnostics.ObserveAlchemistDialogueState(akSpeakerRef as Actor)
    MMEDiagnostics.ObserveMageDialogueState(akSpeakerRef as Actor)
EndFunction

Function Fragment_RescueFollowerArmor(ObjectReference akSpeakerRef)
    followerRescueAttempted = True
    MMELog.MasterDiagnostic("[MME Extensions Follower Armor Rescue] dialogue begin fragment entered")
    SetFollowerArmorRescueState(0)
    CompleteVendorService(akSpeakerRef, "Blacksmith/RescueFollowerArmor", MMEFollowerArmorRescue.TryRescueNearbyCompanions(akSpeakerRef as Actor))
EndFunction

; Skyrim can finish a response without dispatching its begin fragment on some
; dialogue paths. The dedicated end fragment provides an idempotent fallback,
; then preserves the shared vendor-animation completion bus.
Function Fragment_RescueFollowerArmorCompleted(ObjectReference akSpeakerRef)
    If !followerRescueAttempted
        MMELog.MasterDiagnostic("[MME Extensions Follower Armor Rescue] begin fragment was missed; end fallback dispatching service")
        Fragment_RescueFollowerArmor(akSpeakerRef)
    EndIf
    followerRescueAttempted = False
    Fragment_ServiceCompleted(akSpeakerRef)
EndFunction

Function SetFollowerArmorRescueState(Int value)
    ; Heal the persistent opening INFO script on saves created before this
    ; property existed, matching the milking-refit upgrade path above.
    If MMEExt_FollowerArmorRescueState == None
        MMEExt_FollowerArmorRescueState = Game.GetFormFromFile(0x0008AA, "MMEAlert.esp") as GlobalVariable
    EndIf
    If MMEExt_FollowerArmorRescueState != None
        MMEExt_FollowerArmorRescueState.SetValue(value as Float)
    Else
        MMELog.Alarm("[MME Extensions Follower Armor Rescue] FAILURE: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Fragment_RefitMilkingEquipment(ObjectReference akSpeakerRef)
    SetMilkingEquipmentRefitState(0)
    CompleteVendorService(akSpeakerRef, "Blacksmith/RefitMilkingEquipment", MMEMilkingEquipmentRefit.TryRefit(akSpeakerRef as Actor))
EndFunction

Function SetMilkingEquipmentRefitState(Int value)
    ; Older saves can retain the script instance created before this property
    ; was correctly bound in the plugin. Resolve the local Global form once so
    ; those saves heal without requiring a restart or clean save.
    If MMEExt_MilkingEquipmentRefitState == None
        MMEExt_MilkingEquipmentRefitState = Game.GetFormFromFile(0x0008A7, "MMEAlert.esp") as GlobalVariable
    EndIf
    If MMEExt_MilkingEquipmentRefitState != None
        MMEExt_MilkingEquipmentRefitState.SetValue(value as Float)
    Else
        MMELog.Alarm("[MME Extensions Milking Refit] FAILURE: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Fragment_InstallDwemerAttachment(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Blacksmith/InstallDwemerAttachment", MMEDwemerBlacksmithDialogue.TryInstall(akSpeakerRef as Actor))
EndFunction

Function Fragment_RemoveDwemerAttachment(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Blacksmith/RemoveDwemerAttachment", MMEDwemerBlacksmithDialogue.TryRemove(akSpeakerRef as Actor))
EndFunction

Function Fragment_RemoveTimedTrapArmor(ObjectReference akSpeakerRef)
    SetTrapArmorDialogueState(0)
    CompleteVendorService(akSpeakerRef, "TrapArmor/Release", MMETrapArmorDialogue.TryVendorRelease(akSpeakerRef as Actor))
EndFunction

Function SetTrapArmorDialogueState(Int value)
    ; Existing saves can retain the opening INFO script instance from before
    ; this property was bound. Resolve the local Global once, just like the
    ; refit and follower-rescue state properties above.
    If MMEExt_TrapArmorRemovalState == None
        MMEExt_TrapArmorRemovalState = Game.GetFormFromFile(0x00089F, "MMEAlert.esp") as GlobalVariable
    EndIf
    If MMEExt_TrapArmorRemovalState != None
        MMEExt_TrapArmorRemovalState.SetValue(value as Float)
    Else
        MMELog.Alarm("[MME Extensions Trap Armor Dialogue] FAILURE: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Fragment_AddLivingArmor(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Alchemist/AddLivingArmor", MMEAlchemistDialogue.TryAddLivingArmor(akSpeakerRef as Actor, MMEExt_AlchemistLivingArmorState))
EndFunction

Function Fragment_RemoveLivingArmor(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Alchemist/RemoveLivingArmor", MMEAlchemistDialogue.TryRemoveLivingArmor(akSpeakerRef as Actor, MMEExt_AlchemistLivingArmorState))
EndFunction

Function Fragment_AddParasiteArmor(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Mage/AddParasiteArmor", MMEMageDialogue.TryAddParasiteArmor(akSpeakerRef as Actor, MMEExt_MageParasiteArmorState))
EndFunction

Function Fragment_ApplyReverseLeveling(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Mage/ApplyReverseLeveling", MMEMageDialogue.TryApplyReverseLeveling(akSpeakerRef as Actor))
EndFunction

Function Fragment_RemoveParasiteArmor(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Mage/RemoveParasiteArmor", MMEMageDialogue.TryRemoveParasiteArmor(akSpeakerRef as Actor, MMEExt_MageParasiteArmorState))
EndFunction

Function Fragment_AddMilkArmor(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Blacksmith/AddMilkArmor", TryAddMilkArmor(akSpeakerRef as Actor))
EndFunction

Function Fragment_RemoveMilkArmor(ObjectReference akSpeakerRef)
    CompleteVendorService(akSpeakerRef, "Blacksmith/RemoveMilkArmor", TryRemoveMilkArmor(akSpeakerRef as Actor))
EndFunction

; Bound only to the service INFOs' OnEnd, after their final response finishes.
Function Fragment_ServiceCompleted(ObjectReference akSpeakerRef)
    If serviceSucceeded
        MMEDebug service = MMEDiagnostics.GetDebugService()
        If service != None
            service.ObserveVendorServiceInfoEnd(akSpeakerRef as Actor)
        EndIf
    EndIf
    serviceSucceeded = False
EndFunction

Function CompleteVendorService(ObjectReference akSpeakerRef, String route, Bool succeeded)
    serviceSucceeded = succeeded
    MMEDebug service = MMEDiagnostics.GetDebugService()
    If service != None
        service.HandleVendorServiceResult(akSpeakerRef as Actor, route, succeeded)
    ElseIf MMELog.IsDiagnosticEnabled()
        MMELog.Alarm("[MME Extensions Vendor Animation Bus] STOP: persistent MMEDebug service unavailable | route=" + route)
    EndIf
EndFunction

Int Function GetLiveServiceState(Actor blacksmith)

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController)
        Return 0
    EndIf
    Return MMEItemAttachments.ServiceState(playerActor, 1)
EndFunction

Bool Function TryAddMilkArmor(Actor blacksmith)

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController)
        Return False
    EndIf
    Return MMEItemAttachments.ApplyService(playerActor, 1, True)
EndFunction

Bool Function TryRemoveMilkArmor(Actor blacksmith)

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController)
        Return False
    EndIf
    Return MMEItemAttachments.ApplyService(playerActor, 1, False)
EndFunction

Bool Function ValidateParticipants(Actor blacksmith, Actor playerActor, MilkQUEST milkController)
    If !MMEAlertsController.IsExtensionsEnabled() || blacksmith == None \
        || playerActor == None || milkController == None
        Return False
    EndIf
    Faction blacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If blacksmithFaction == None || merchantFaction == None \
        || !blacksmith.IsInFaction(blacksmithFaction) \
        || !blacksmith.IsInFaction(merchantFaction)
        Return False
    EndIf
    ; Dialogue service is intentionally stricter than the compatibility helper:
    ; require MME's live Maid faction and explicitly exclude its Slave faction.
    If milkController.MilkMaidFaction == None || milkController.MilkSlaveFaction == None \
        || !playerActor.IsInFaction(milkController.MilkMaidFaction) \
        || playerActor.IsInFaction(milkController.MilkSlaveFaction)
        Return False
    EndIf
    Return True
EndFunction

Armor Function GetWornBodyArmor(Actor target)
    If target == None
        Return None
    EndIf
    Return target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
EndFunction

Bool Function IsManageableArmorIdentity(Armor wornArmor)
    If wornArmor == None
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    Return armorName != "" && armorName != "Empty" && armorName != "empty"
EndFunction

Function SetDialogueState(Int value)
    If MMEExt_BlacksmithArmorState != None
        MMEExt_BlacksmithArmorState.SetValue(value as Float)
    Else
        MMELog.Alarm("[MME Extensions Blacksmith] ERROR: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Reject(String reason, Bool notifyPlayer = True)
    If notifyPlayer
        Debug.Notification(MMELocalization.Text("Armor state changed; no changes made"))
    EndIf
    MMELog.Diagnostic("[MME Extensions Blacksmith] REJECTED: " + reason, 1)
EndFunction
