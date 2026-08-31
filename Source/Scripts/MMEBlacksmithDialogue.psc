Scriptname MMEBlacksmithDialogue extends MME_Dialogues Hidden

; Transient choice state populated by the existing [MME] Hey there! opening:
; 0 unavailable/invalid, 1 Add, 2 Remove, 3 protected, 4 registry full.
; The Global controls visibility only. Action fragments never trust it.
GlobalVariable Property MMEExt_BlacksmithArmorState Auto

Function Fragment_RefreshBlacksmithArmorState(ObjectReference akSpeakerRef)
    SetDialogueState(0)
    ; Preserve MME's complete opening behavior exactly once before its existing
    ; linked choices and our two new choices evaluate their conditions.
    Parent.Fragment_00(akSpeakerRef)
    SetDialogueState(GetLiveServiceState(akSpeakerRef as Actor))
EndFunction

Function Fragment_AddMilkArmor(ObjectReference akSpeakerRef)
    TryAddMilkArmor(akSpeakerRef as Actor)
EndFunction

Function Fragment_RemoveMilkArmor(ObjectReference akSpeakerRef)
    TryRemoveMilkArmor(akSpeakerRef as Actor)
EndFunction

Int Function GetLiveServiceState(Actor blacksmith)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController)
        Return 0
    EndIf
    If !MMEArmorScript.AreArmorRegistriesSafeForManagement(milkController)
        Return 0
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Return 0
    EndIf
    If MMEArmorScript.GetMMEProtectedArmorReason(milkController, wornArmor, "blacksmith-menu", playerActor) != ""
        Return 3
    EndIf
    String armorName = wornArmor.GetName()
    Int matches = MMEArmorScript.CountArmorNameMatchesSafe(armorName, milkController.MilkingEquipment)
    If matches == 1
        Return 2
    ElseIf matches != 0
        Return 0
    EndIf
    If MMEArmorScript.FindArmorEmptySlotSafe(milkController.MilkingEquipment) >= 0
        Return 1
    EndIf
    Return 4
EndFunction

Bool Function TryAddMilkArmor(Actor blacksmith)
    SetDialogueState(0)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController) \
        || !MMEArmorScript.AreArmorRegistriesSafeForManagement(milkController)
        Reject("participants or MME armor registries changed")
        Return False
    EndIf

    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Reject("no usable slot-32 armor is equipped")
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    If MMEArmorScript.GetMMEProtectedArmorReason(milkController, wornArmor, "blacksmith-add", playerActor) != ""
        Debug.Notification("Not this one. It's already got its own milking setup.")
        Reject("protected armor cannot be registered", False)
        Return False
    EndIf
    If MMEArmorScript.CountArmorNameMatchesSafe(armorName, milkController.MilkingEquipment) != 0
        Reject("armor is already registered or registration data is ambiguous")
        Return False
    EndIf
    Int emptyIndex = MMEArmorScript.FindArmorEmptySlotSafe(milkController.MilkingEquipment)
    If emptyIndex < 0
        Debug.Notification("Error: Milking Equipment is full")
        Reject("MilkingEquipment has no Empty slot", False)
        Return False
    EndIf

    ; Final intent check. Every call below is non-latent; no dialogue snapshot,
    ; Wait, spell Cast, or purge can intervene before the native-style write.
    If GetWornBodyArmor(playerActor) != wornArmor \
        || !MMEArmorScript.AreArmorRegistriesSafeForManagement(milkController) \
        || MMEArmorScript.GetMMEProtectedArmorReason(milkController, wornArmor, "blacksmith-add-final", playerActor) != "" \
        || MMEArmorScript.CountArmorNameMatchesSafe(armorName, milkController.MilkingEquipment) != 0 \
        || emptyIndex >= milkController.MilkingEquipment.Length \
        || milkController.MilkingEquipment[emptyIndex] != "Empty"
        Reject("live armor or registry changed before Add")
        Return False
    EndIf

    ; This is MME's original AM Milk Armor operation: exact display name into
    ; the first exact "Empty" cell of MilkQ.MilkingEquipment.
    milkController.MilkingEquipment[emptyIndex] = armorName
    If milkController.MilkingEquipment[emptyIndex] != armorName \
        || MMEArmorScript.CountArmorNameMatchesSafe(armorName, milkController.MilkingEquipment) != 1
        Reject("MME did not retain the added registration")
        Return False
    EndIf
    Debug.Notification(armorName + " Added to Milking Equipment")
    Debug.Trace("[MME Extensions Blacksmith] ADD complete | armor=" + armorName + " | index=" + emptyIndex)
    Return True
EndFunction

Bool Function TryRemoveMilkArmor(Actor blacksmith)
    SetDialogueState(0)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController) \
        || !MMEArmorScript.AreArmorRegistriesSafeForManagement(milkController)
        Reject("participants or MME armor registries changed")
        Return False
    EndIf

    Armor wornArmor = GetWornBodyArmor(playerActor)
    If !IsManageableArmorIdentity(wornArmor)
        Reject("no usable slot-32 armor is equipped")
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    If MMEArmorScript.GetMMEProtectedArmorReason(milkController, wornArmor, "blacksmith-remove", playerActor) != ""
        Debug.Notification("Not this one. It's already got its own milking setup.")
        Reject("protected armor cannot be removed", False)
        Return False
    EndIf
    If MMEArmorScript.CountArmorNameMatchesSafe(armorName, milkController.MilkingEquipment) != 1
        Reject("armor is not registered exactly once")
        Return False
    EndIf
    Int registeredIndex = MMEArmorScript.FindArmorNameSafe(armorName, milkController.MilkingEquipment)
    If registeredIndex < 0
        Reject("exact registration index was unavailable")
        Return False
    EndIf

    ; Final intent check immediately adjacent to the original AM removal write.
    If GetWornBodyArmor(playerActor) != wornArmor \
        || !MMEArmorScript.AreArmorRegistriesSafeForManagement(milkController) \
        || MMEArmorScript.GetMMEProtectedArmorReason(milkController, wornArmor, "blacksmith-remove-final", playerActor) != "" \
        || MMEArmorScript.CountArmorNameMatchesSafe(armorName, milkController.MilkingEquipment) != 1 \
        || registeredIndex >= milkController.MilkingEquipment.Length \
        || milkController.MilkingEquipment[registeredIndex] != armorName
        Reject("live armor or registry changed before Remove")
        Return False
    EndIf

    milkController.MilkingEquipment[registeredIndex] = "Empty"
    If milkController.MilkingEquipment[registeredIndex] != "Empty" \
        || MMEArmorScript.CountArmorNameMatchesSafe(armorName, milkController.MilkingEquipment) != 0
        Reject("MME did not retain the removed registration")
        Return False
    EndIf
    Debug.Notification(armorName + " Removed from Milking Equipment")
    Debug.Trace("[MME Extensions Blacksmith] REMOVE complete | armor=" + armorName + " | index=" + registeredIndex)
    Return True
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
    Return armorName != "" && armorName != "Empty" && armorName != "empty" \
        && !MMEArmorScript.IsAmbiguousOrdinaryArmorName(armorName)
EndFunction

Function SetDialogueState(Int value)
    If MMEExt_BlacksmithArmorState != None
        MMEExt_BlacksmithArmorState.SetValue(value as Float)
    Else
        Debug.Trace("[MME Extensions Blacksmith] ERROR: dialogue-state Global is unbound", 2)
    EndIf
EndFunction

Function Reject(String reason, Bool notifyPlayer = True)
    If notifyPlayer
        Debug.Notification("Armor state changed; no changes made")
    EndIf
    Debug.Trace("[MME Extensions Blacksmith] REJECTED: " + reason, 1)
EndFunction
