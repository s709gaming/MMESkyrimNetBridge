Scriptname MMEDwemerBlacksmithDialogue Hidden

; Blacksmith-only management for reversible Dwemer attachments. The dedicated
; artisan registry prevents this service from removing built-in compatibility.

Int Function GetLiveServiceState(Actor blacksmith) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    String failure = GetEligibilityFailure(blacksmith, playerActor, milkController)
    If failure != ""
        Trace("option unavailable | " + failure)
        Return 0
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If wornArmor == None
        Return 0
    EndIf
    If MMECustomArmorRegistry.IsArtisanDwemerArmor(wornArmor)
        Return 2
    EndIf
    If MMETimedArmorLock.IsLocked(playerActor) && MMETimedArmorLock.GetLockedArmor(playerActor) == wornArmor
        Return 3
    EndIf
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "dwemer-blacksmith-menu", playerActor)
    If armorClass > 0 || MMEArmorScript.GetMMEArmorProtectionReason(milkController, wornArmor, "dwemer-blacksmith-menu", playerActor) != ""
        Return 3
    EndIf
    Return 1
EndFunction

Bool Function TryInstall(Actor blacksmith) Global
    Actor playerActor = Game.GetPlayer()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String failure = GetEligibilityFailure(blacksmith, playerActor, milkController)
    If failure != ""
        Reject("install rejected | " + failure)
        Return False
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If wornArmor == None
        Reject("install rejected | no slot-32 armor equipped")
        Return False
    EndIf
    If MMETimedArmorLock.IsLocked(playerActor) && MMETimedArmorLock.GetLockedArmor(playerActor) == wornArmor
        Reject("install rejected | equipped armor has an active timed bond")
        Return False
    EndIf
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "dwemer-blacksmith-install", playerActor)
    If armorClass > 0 || MMEArmorScript.GetMMEArmorProtectionReason(milkController, wornArmor, "dwemer-blacksmith-install", playerActor) != ""
        Reject("install rejected | equipped armor already has managed behavior")
        Return False
    EndIf
    Trace("install starting | blacksmith=" + GetActorName(blacksmith) + " | armor=" + wornArmor.GetName())
    If !MMECustomArmorRegistry.RegisterArtisanDwemerArmor(wornArmor)
        Alarm("attachment registration failed | armor=" + wornArmor.GetName())
        Return False
    EndIf
    If GetWornBodyArmor(playerActor) != wornArmor || MMEArmorScript.ClassifyArmor(milkController, wornArmor, "dwemer-blacksmith-install-verify", playerActor) != 4
        MMECustomArmorRegistry.UnregisterArtisanDwemerArmor(wornArmor)
        Alarm("installation verification failed; registration rolled back | armor=" + wornArmor.GetName())
        Return False
    EndIf
    MMECustomArmorRegistry.HandleCustomArmorEquipped(playerActor, wornArmor)
    Debug.Notification("Dwemer milking attachment installed in " + wornArmor.GetName())
    Bool introduced = MMEArmorIntroduction.TryIntroduction(playerActor, wornArmor, "Blacksmith Dwemer attachment service")
    Trace("immediate Dwemer introduction result=" + introduced + " | armor=" + wornArmor.GetName())
    Trace("install complete | armor=" + wornArmor.GetName())
    Return True
EndFunction

Bool Function TryRemove(Actor blacksmith) Global
    Actor playerActor = Game.GetPlayer()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String failure = GetEligibilityFailure(blacksmith, playerActor, milkController)
    If failure != ""
        Reject("removal rejected | " + failure)
        Return False
    EndIf
    Armor wornArmor = GetWornBodyArmor(playerActor)
    If wornArmor == None || !MMECustomArmorRegistry.IsArtisanDwemerArmor(wornArmor)
        Reject("removal rejected | equipped armor has no artisan attachment")
        Return False
    EndIf
    If MMETimedArmorLock.IsLocked(playerActor) && MMETimedArmorLock.GetLockedArmor(playerActor) == wornArmor
        Reject("removal rejected | equipped armor has an active timed bond")
        Return False
    EndIf
    Trace("removal starting | blacksmith=" + GetActorName(blacksmith) + " | armor=" + wornArmor.GetName())
    If !MMECustomArmorRegistry.UnregisterArtisanDwemerArmor(wornArmor)
        Alarm("attachment removal failed | armor=" + wornArmor.GetName())
        Return False
    EndIf
    If MMECustomArmorRegistry.IsArtisanDwemerArmor(wornArmor)
        Alarm("removal verification failed | armor=" + wornArmor.GetName())
        Return False
    EndIf
    Debug.Notification("Dwemer milking attachment removed from " + wornArmor.GetName())
    Trace("removal complete | armor=" + wornArmor.GetName())
    Return True
EndFunction

String Function GetEligibilityFailure(Actor blacksmith, Actor playerActor, MilkQUEST milkController) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Return "MME Extensions disabled"
    ElseIf blacksmith == None || playerActor == None || milkController == None
        Return "speaker, player, or MME controller unavailable"
    EndIf
    Faction blacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If blacksmithFaction == None || merchantFaction == None
        Alarm("required Skyrim blacksmith/merchant faction could not resolve")
        Return "required service faction unavailable"
    ElseIf !blacksmith.IsInFaction(blacksmithFaction) || !blacksmith.IsInFaction(merchantFaction)
        Return "speaker is not an eligible blacksmith merchant"
    ElseIf milkController.MilkMaidFaction == None || milkController.MilkSlaveFaction == None
        Alarm("MME Maid or Slave faction property unavailable")
        Return "MME faction data unavailable"
    ElseIf !playerActor.IsInFaction(milkController.MilkMaidFaction) || playerActor.IsInFaction(milkController.MilkSlaveFaction)
        Return "player is not an eligible free Milk Maid"
    EndIf
    Return ""
EndFunction

Armor Function GetWornBodyArmor(Actor target) Global
    If target == None
        Return None
    EndIf
    Return target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
EndFunction

Function SetDialogueState(GlobalVariable stateGlobal, Int value) Global
    If stateGlobal == None
        Alarm("dialogue-state Global is unbound")
        Return
    EndIf
    stateGlobal.SetValue(value as Float)
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

Function Reject(String detail) Global
    Debug.Notification("Armor state changed; no changes made")
    Trace(detail)
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Dwemer Blacksmith] " + detail)
EndFunction

Function Alarm(String detail) Global
    MMELog.Alarm("[MME Extensions Dwemer Blacksmith] FAILURE: " + detail)
EndFunction
