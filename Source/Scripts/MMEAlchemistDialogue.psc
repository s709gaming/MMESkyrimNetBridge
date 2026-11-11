Scriptname MMEAlchemistDialogue Hidden

; State values: 0 unavailable/invalid, 1 Add, 2 Remove, 3 protected,
; 4 registry full. The Global controls visibility only; actions revalidate.
Int Function GetLiveServiceState(Actor alchemist) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(alchemist, playerActor, milkController)
        Return 0
    EndIf
    Return MMEItemAttachments.ServiceState(playerActor, 2)
EndFunction

Bool Function TryAddLivingArmor(Actor alchemist, GlobalVariable stateGlobal) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    SetDialogueState(stateGlobal, 0)
    If !ValidateParticipants(alchemist, playerActor, milkController)
        Return False
    EndIf
    Return MMEItemAttachments.ApplyService(playerActor, 2, True)
EndFunction

Bool Function TryRemoveLivingArmor(Actor alchemist, GlobalVariable stateGlobal) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    SetDialogueState(stateGlobal, 0)
    If !ValidateParticipants(alchemist, playerActor, milkController)
        Return False
    EndIf
    Return MMEItemAttachments.ApplyService(playerActor, 2, False)
EndFunction

Bool Function ValidateParticipants(Actor alchemist, Actor playerActor, MilkQUEST milkController) Global
    If !MMEAlertsController.IsExtensionsEnabled() || alchemist == None \
        || playerActor == None || milkController == None
        Return False
    EndIf
    Faction apothecaryFaction = Game.GetFormFromFile(0x05091C, "Skyrim.esm") as Faction
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If apothecaryFaction == None || merchantFaction == None \
        || !alchemist.IsInFaction(apothecaryFaction) || !alchemist.IsInFaction(merchantFaction)
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
        MMELog.Alarm("[MME Extensions Alchemist] ERROR: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Reject(String reason, Bool notifyPlayer = True) Global
    If notifyPlayer
        Debug.Notification(MMELocalization.Text("Armor state changed; no changes made"))
    EndIf
    MMELog.Diagnostic("[MME Extensions Alchemist] REJECTED: " + reason, 1)
EndFunction
