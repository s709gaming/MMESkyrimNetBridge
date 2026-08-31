Scriptname MMEAlchemistDialogue Hidden

; State values: 0 unavailable/invalid, 1 Add, 2 Remove, 3 protected,
; 4 registry full. The Global controls visibility only; actions revalidate.
Int Function GetLiveServiceState(Actor alchemist) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(alchemist, playerActor, milkController) \
        || !MMEArmorScript.IsBasicLivingArmorRegistrySafeForManagement(milkController)
        Return 0
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Return 0
    EndIf
    If MMEArmorScript.GetMMEProtectedForBasicLivingArmorReason(milkController, wornArmor) != ""
        Return 3
    EndIf
    String armorName = wornArmor.GetName()
    Int matches = MMEArmorScript.CountBasicLivingArmorMatchesDirect(milkController, armorName)
    If matches == 1
        Return 2
    ElseIf matches != 0
        Return 0
    EndIf
    If MMEArmorScript.FindBasicLivingArmorEmptySlotDirect(milkController) >= 0
        Return 1
    EndIf
    Return 4
EndFunction

Bool Function TryAddLivingArmor(Actor alchemist, GlobalVariable stateGlobal) Global
    SetDialogueState(stateGlobal, 0)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(alchemist, playerActor, milkController) \
        || !MMEArmorScript.IsBasicLivingArmorRegistrySafeForManagement(milkController)
        Reject("participants or BasicLivingArmor registry changed")
        Return False
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Reject("no usable slot-32 armor is equipped")
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    If MMEArmorScript.GetMMEProtectedForBasicLivingArmorReason(milkController, wornArmor) != ""
        Debug.Notification("That armor is already bound to another MME system.")
        Reject("protected armor cannot be registered", False)
        Return False
    EndIf
    If MMEArmorScript.CountBasicLivingArmorMatchesDirect(milkController, armorName) != 0
        Reject("armor is already registered or registration data is ambiguous")
        Return False
    EndIf
    Int emptyIndex = MMEArmorScript.FindBasicLivingArmorEmptySlotDirect(milkController)
    If emptyIndex < 0
        Debug.Notification("Error: Basic Living Armor is full")
        Reject("BasicLivingArmor has no Empty slot", False)
        Return False
    EndIf
    If GetWornBodyArmor(playerActor) != wornArmor \
        || !ValidateParticipants(alchemist, playerActor, milkController) \
        || !MMEArmorScript.IsBasicLivingArmorRegistrySafeForManagement(milkController) \
        || MMEArmorScript.GetMMEProtectedForBasicLivingArmorReason(milkController, wornArmor) != "" \
        || MMEArmorScript.CountBasicLivingArmorMatchesDirect(milkController, armorName) != 0 \
        || emptyIndex >= milkController.BasicLivingArmor.Length \
        || milkController.BasicLivingArmor[emptyIndex] != "Empty"
        Reject("live participants, armor, or registry changed before Add")
        Return False
    EndIf
    milkController.BasicLivingArmor[emptyIndex] = armorName
    If milkController.BasicLivingArmor[emptyIndex] != armorName \
        || MMEArmorScript.CountBasicLivingArmorMatchesDirect(milkController, armorName) != 1
        Reject("MME did not retain the added registration")
        Return False
    EndIf
    Debug.Notification(armorName + " Added to Basic Living Armor")
    Debug.Trace("[MME Extensions Alchemist] ADD complete | armor=" + armorName + " | index=" + emptyIndex)
    Return True
EndFunction

Bool Function TryRemoveLivingArmor(Actor alchemist, GlobalVariable stateGlobal) Global
    SetDialogueState(stateGlobal, 0)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(alchemist, playerActor, milkController) \
        || !MMEArmorScript.IsBasicLivingArmorRegistrySafeForManagement(milkController)
        Reject("participants or BasicLivingArmor registry changed")
        Return False
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Reject("no usable slot-32 armor is equipped")
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    If MMEArmorScript.GetMMEProtectedForBasicLivingArmorReason(milkController, wornArmor) != ""
        Debug.Notification("That armor is bound to another MME system.")
        Reject("protected armor cannot be removed", False)
        Return False
    EndIf
    If MMEArmorScript.CountBasicLivingArmorMatchesDirect(milkController, armorName) != 1
        Reject("armor is not registered exactly once")
        Return False
    EndIf
    Int registeredIndex = MMEArmorScript.FindBasicLivingArmorNameDirect(milkController, armorName)
    If registeredIndex < 0
        Reject("exact registration index was unavailable")
        Return False
    EndIf
    If GetWornBodyArmor(playerActor) != wornArmor \
        || !ValidateParticipants(alchemist, playerActor, milkController) \
        || !MMEArmorScript.IsBasicLivingArmorRegistrySafeForManagement(milkController) \
        || MMEArmorScript.GetMMEProtectedForBasicLivingArmorReason(milkController, wornArmor) != "" \
        || MMEArmorScript.CountBasicLivingArmorMatchesDirect(milkController, armorName) != 1 \
        || registeredIndex >= milkController.BasicLivingArmor.Length \
        || milkController.BasicLivingArmor[registeredIndex] != armorName
        Reject("live participants, armor, or registry changed before Remove")
        Return False
    EndIf
    milkController.BasicLivingArmor[registeredIndex] = "Empty"
    If milkController.BasicLivingArmor[registeredIndex] != "Empty" \
        || MMEArmorScript.CountBasicLivingArmorMatchesDirect(milkController, armorName) != 0
        Reject("MME did not retain the removed registration")
        Return False
    EndIf
    Debug.Notification(armorName + " Removed from Basic Living Armor")
    Debug.Trace("[MME Extensions Alchemist] REMOVE complete | armor=" + armorName + " | index=" + registeredIndex)
    Return True
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
        Debug.Trace("[MME Extensions Alchemist] ERROR: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Reject(String reason, Bool notifyPlayer = True) Global
    If notifyPlayer
        Debug.Notification("Armor state changed; no changes made")
    EndIf
    Debug.Trace("[MME Extensions Alchemist] REJECTED: " + reason, 1)
EndFunction
