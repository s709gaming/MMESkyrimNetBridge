Scriptname MMETrapArmorDialogue Hidden

Int Function GetLiveServiceState(Actor speaker) Global
    Actor playerActor = Game.GetPlayer()
    String reason = GetEligibilityFailure(speaker, playerActor)
    If reason != ""
        Trace("option unavailable | " + reason)
        Return 0
    EndIf
    Armor lockedArmor = MMETimedArmorLock.GetLockedArmor(playerActor)
    Int armorClass = MMETimedArmorLock.GetRegisteredArmorClass(lockedArmor)
    Trace("option available | speaker=" + GetActorName(speaker) + " | armor=" + lockedArmor.GetName() + " | class=" + armorClass)
    Return 1
EndFunction

Bool Function TryVendorRelease(Actor speaker) Global
    Actor playerActor = Game.GetPlayer()
    String reason = GetEligibilityFailure(speaker, playerActor)
    If reason != ""
        Debug.Notification("The armor situation changed; no removal was attempted.")
        Trace("release rejected | " + reason)
        Return False
    EndIf
    Armor lockedArmor = MMETimedArmorLock.GetLockedArmor(playerActor)
    Int armorClass = MMETimedArmorLock.GetRegisteredArmorClass(lockedArmor)
    Trace("release starting | speaker=" + GetActorName(speaker) + " | armor=" + lockedArmor.GetName() + " | class=" + armorClass)
    If !MMETimedArmorLock.Release(playerActor, "Vendor Assistance")
        Alarm("vendor release failed | speaker=" + GetActorName(speaker) + " | armor=" + lockedArmor.GetName() + " | class=" + armorClass)
        Return False
    EndIf
    If MMETimedArmorLock.IsLocked(playerActor) || playerActor.IsEquipped(lockedArmor)
        Alarm("vendor release returned success but armor state remains active | armor=" + lockedArmor.GetName())
        Return False
    EndIf
    Trace("release complete | speaker=" + GetActorName(speaker) + " | armor=" + lockedArmor.GetName() + " | class=" + armorClass)
    Return True
EndFunction

String Function GetEligibilityFailure(Actor speaker, Actor playerActor) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Return "MME Extensions disabled"
    ElseIf speaker == None || playerActor == None
        Return "speaker or player missing"
    ElseIf !MMETimedArmorLock.IsLocked(playerActor)
        Return "player has no active timed armor bond"
    EndIf
    Armor lockedArmor = MMETimedArmorLock.GetLockedArmor(playerActor)
    If lockedArmor == None
        Alarm("active timed armor bond has no armor form")
        Return "locked armor missing"
    ElseIf !playerActor.IsEquipped(lockedArmor)
        Return "locked armor is no longer equipped"
    EndIf
    Int armorClass = MMETimedArmorLock.GetRegisteredArmorClass(lockedArmor)
    If armorClass < 2 || armorClass > 4
        Alarm("active trap armor has unsupported class | armor=" + lockedArmor.GetName() + " | class=" + armorClass)
        Return "unsupported trap armor class"
    EndIf
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    Faction blacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    Faction apothecaryFaction = Game.GetFormFromFile(0x05091C, "Skyrim.esm") as Faction
    Faction courtWizardFaction = Game.GetFormFromFile(0x05091E, "Skyrim.esm") as Faction
    If merchantFaction == None || blacksmithFaction == None || apothecaryFaction == None || courtWizardFaction == None
        Alarm("one or more Skyrim service factions could not resolve")
        Return "service faction missing"
    ElseIf !speaker.IsInFaction(merchantFaction)
        Return "speaker is not an eligible merchant"
    ElseIf armorClass == 4 && !speaker.IsInFaction(blacksmithFaction)
        Return "Dwemer armor requires a blacksmith"
    ElseIf (armorClass == 2 || armorClass == 3) \
        && !speaker.IsInFaction(apothecaryFaction) && !speaker.IsInFaction(courtWizardFaction)
        Return "Living or Parasite armor requires an alchemist or court wizard"
    EndIf
    Return ""
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Trap Armor Dialogue] " + detail)
EndFunction

Function Alarm(String detail) Global
    MMELog.Alarm("[MME Extensions Trap Armor Dialogue] FAILURE: " + detail)
EndFunction
