Scriptname MMEMageDialogue Hidden

; State values: 0 unavailable/invalid, 1 Add, 2 Remove, 3 protected,
; 4 registry full. The Global controls visibility only; actions revalidate.
Int Function GetLiveServiceState(Actor mage) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(mage, playerActor, milkController) \
        || !MMEArmorScript.IsParasiteLivingArmorRegistrySafeForManagement(milkController)
        Return 0
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Return 0
    EndIf
    If MMEArmorScript.GetMMEProtectedForParasiteLivingArmorReason(milkController, wornArmor) != ""
        Return 3
    EndIf
    String armorName = wornArmor.GetName()
    Int matches = MMEArmorScript.CountParasiteLivingArmorMatchesDirect(milkController, armorName)
    If matches == 1
        Return 2
    ElseIf matches != 0
        Return 0
    EndIf
    If MMEArmorScript.FindParasiteLivingArmorEmptySlotDirect(milkController) >= 0
        Return 1
    EndIf
    Return 4
EndFunction

Bool Function TryAddParasiteArmor(Actor mage, GlobalVariable stateGlobal) Global
    SetDialogueState(stateGlobal, 0)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(mage, playerActor, milkController) \
        || !MMEArmorScript.IsParasiteLivingArmorRegistrySafeForManagement(milkController)
        Reject("participants or ParasiteLivingArmor registry changed")
        Return False
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Reject("no usable slot-32 armor is equipped")
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    If MMEArmorScript.GetMMEProtectedForParasiteLivingArmorReason(milkController, wornArmor) != ""
        Debug.Notification("That armor is already bound to another MME system.")
        Reject("protected armor cannot be registered", False)
        Return False
    EndIf
    If MMEArmorScript.CountParasiteLivingArmorMatchesDirect(milkController, armorName) != 0
        Reject("armor is already registered or registration data is ambiguous")
        Return False
    EndIf
    Int emptyIndex = MMEArmorScript.FindParasiteLivingArmorEmptySlotDirect(milkController)
    If emptyIndex < 0
        Debug.Notification("Error: Parasite Living Armor is full")
        Reject("ParasiteLivingArmor has no Empty slot", False)
        Return False
    EndIf
    If GetWornBodyArmor(playerActor) != wornArmor \
        || !ValidateParticipants(mage, playerActor, milkController) \
        || !MMEArmorScript.IsParasiteLivingArmorRegistrySafeForManagement(milkController) \
        || MMEArmorScript.GetMMEProtectedForParasiteLivingArmorReason(milkController, wornArmor) != "" \
        || MMEArmorScript.CountParasiteLivingArmorMatchesDirect(milkController, armorName) != 0 \
        || emptyIndex >= milkController.ParasiteLivingArmor.Length \
        || milkController.ParasiteLivingArmor[emptyIndex] != "Empty"
        Reject("live participants, armor, or registry changed before Add")
        Return False
    EndIf
    milkController.ParasiteLivingArmor[emptyIndex] = armorName
    If milkController.ParasiteLivingArmor[emptyIndex] != armorName \
        || MMEArmorScript.CountParasiteLivingArmorMatchesDirect(milkController, armorName) != 1
        Reject("MME did not retain the added registration")
        Return False
    EndIf
    Debug.Notification(armorName + " Added to Parasite Living Armor")
    Debug.Trace("[MME Extensions Mage] ADD complete | armor=" + armorName + " | index=" + emptyIndex)
    Return True
EndFunction

Bool Function TryRemoveParasiteArmor(Actor mage, GlobalVariable stateGlobal) Global
    SetDialogueState(stateGlobal, 0)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(mage, playerActor, milkController) \
        || !MMEArmorScript.IsParasiteLivingArmorRegistrySafeForManagement(milkController)
        Reject("participants or ParasiteLivingArmor registry changed")
        Return False
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Reject("no usable slot-32 armor is equipped")
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    If MMEArmorScript.GetMMEProtectedForParasiteLivingArmorReason(milkController, wornArmor) != ""
        Debug.Notification("That armor is bound to another MME system.")
        Reject("protected armor cannot be removed", False)
        Return False
    EndIf
    If MMEArmorScript.CountParasiteLivingArmorMatchesDirect(milkController, armorName) != 1
        Reject("armor is not registered exactly once")
        Return False
    EndIf
    Int registeredIndex = MMEArmorScript.FindParasiteLivingArmorNameDirect(milkController, armorName)
    If registeredIndex < 0
        Reject("exact registration index was unavailable")
        Return False
    EndIf
    If GetWornBodyArmor(playerActor) != wornArmor \
        || !ValidateParticipants(mage, playerActor, milkController) \
        || !MMEArmorScript.IsParasiteLivingArmorRegistrySafeForManagement(milkController) \
        || MMEArmorScript.GetMMEProtectedForParasiteLivingArmorReason(milkController, wornArmor) != "" \
        || MMEArmorScript.CountParasiteLivingArmorMatchesDirect(milkController, armorName) != 1 \
        || registeredIndex >= milkController.ParasiteLivingArmor.Length \
        || milkController.ParasiteLivingArmor[registeredIndex] != armorName
        Reject("live participants, armor, or registry changed before Remove")
        Return False
    EndIf
    milkController.ParasiteLivingArmor[registeredIndex] = "Empty"
    If milkController.ParasiteLivingArmor[registeredIndex] != "Empty" \
        || MMEArmorScript.CountParasiteLivingArmorMatchesDirect(milkController, armorName) != 0
        Reject("MME did not retain the removed registration")
        Return False
    EndIf
    Debug.Notification(armorName + " Removed from Parasite Living Armor")
    Debug.Trace("[MME Extensions Mage] REMOVE complete | armor=" + armorName + " | index=" + registeredIndex)
    Return True
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
        Debug.Trace("[MME Extensions Mage] ERROR: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Reject(String reason, Bool notifyPlayer = True) Global
    If notifyPlayer
        Debug.Notification("Armor state changed; no changes made")
    EndIf
    Debug.Trace("[MME Extensions Mage] REJECTED: " + reason, 1)
EndFunction
