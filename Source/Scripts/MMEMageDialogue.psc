Scriptname MMEMageDialogue Hidden

Bool Function CanOfferReverseLeveling(Actor mage) Global
    Faction courtWizards = Game.GetFormFromFile(0x05091E, "Skyrim.esm") as Faction
    MMEReverseLevel service = MMEReverseLevel.GetService()
    If mage == None || courtWizards == None || service == None
        Return False
    EndIf
    Return MMEAlertsController.IsExtensionsEnabled() && mage.IsInFaction(courtWizards) \
        && MMEReverseLevel.IsPlayerMaid() && service.ReverseAbility != None \
        && MME_Storage.getMaidLevel(Game.GetPlayer()) >= MMEReverseLevel.GetRequiredLevel()
EndFunction

Bool Function TryApplyReverseLeveling(Actor mage) Global
    If !CanOfferReverseLeveling(mage)
        Debug.Notification(MMELocalization.Text("Reverse leveling is not available right now."))
        Return False
    EndIf
    Return MMEReverseLevel.GetService().ApplyReverseLeveling()
EndFunction

; State values: 0 unavailable/invalid, 1 Add, 2 Remove, 3 protected,
; 4 registry full. The Global controls visibility only; actions revalidate.
Int Function GetLiveServiceState(Actor mage) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(mage, playerActor, milkController)
        Return 0
    EndIf
    Return MMEItemAttachments.ServiceState(playerActor, 3)
EndFunction

Bool Function TryAddParasiteArmor(Actor mage, GlobalVariable stateGlobal) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    SetDialogueState(stateGlobal, 0)
    If !ValidateParticipants(mage, playerActor, milkController)
        Return False
    EndIf
    Return MMEItemAttachments.ApplyService(playerActor, 3, True)
EndFunction

Bool Function TryRemoveParasiteArmor(Actor mage, GlobalVariable stateGlobal) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    SetDialogueState(stateGlobal, 0)
    If !ValidateParticipants(mage, playerActor, milkController)
        Return False
    EndIf
    Return MMEItemAttachments.ApplyService(playerActor, 3, False)
EndFunction

Bool Function ValidateParticipants(Actor mage, Actor playerActor, MilkQUEST milkController) Global
    If !MMEAlertsController.IsExtensionsEnabled() || mage == None \
        || playerActor == None || milkController == None
        Return False
    EndIf
    Faction courtWizardFaction = Game.GetFormFromFile(0x05091E, "Skyrim.esm") as Faction
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If courtWizardFaction == None || merchantFaction == None \
        || !mage.IsInFaction(courtWizardFaction) || !mage.IsInFaction(merchantFaction)
        Return False
    EndIf
    If milkController.MilkMaidFaction == None || milkController.MilkSlaveFaction == None \
        || !playerActor.IsInFaction(milkController.MilkMaidFaction) \
        || playerActor.IsInFaction(milkController.MilkSlaveFaction)
        Return False
    EndIf
    Return True
EndFunction

Armor Function GetWornBodyArmor(Actor target) Global
    If target == None
        Return None
    EndIf
    Return target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
EndFunction

Bool Function IsManageableArmorIdentity(Armor wornArmor) Global
    If wornArmor == None
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    Return armorName != "" && armorName != "Empty" && armorName != "empty"
EndFunction

Function SetDialogueState(GlobalVariable stateGlobal, Int value) Global
    If stateGlobal != None
        stateGlobal.SetValue(value as Float)
    Else
        MMELog.Alarm("[MME Extensions Mage] ERROR: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Reject(String reason, Bool notifyPlayer = True) Global
    If notifyPlayer
        Debug.Notification(MMELocalization.Text("Armor state changed; no changes made"))
    EndIf
    MMELog.Diagnostic("[MME Extensions Mage] REJECTED: " + reason, 1)
EndFunction
