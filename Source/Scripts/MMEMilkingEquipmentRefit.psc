Scriptname MMEMilkingEquipmentRefit Hidden

String Function SettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

String Function InitializedKey() Global
    Return "MMEExtensions.MilkingRefit.Initialized"
EndFunction

String Function LastObservedLevelKey() Global
    Return "MMEExtensions.MilkingRefit.LastObservedLevel"
EndFunction

String Function FittedLevelKey() Global
    Return "MMEExtensions.MilkingRefit.FittedLevel"
EndFunction

String Function NeedsRefitKey() Global
    Return "MMEExtensions.MilkingRefit.NeedsRefit"
EndFunction

String Function LastNoticeTimeKey() Global
    Return "MMEExtensions.MilkingRefit.LastNoticeTime"
EndFunction

Bool Function IsFeatureEnabled() Global
    Return MMEArmorScript.IsConfigurableArmorStrippingEnabled() \
        && JsonUtil.GetIntValue(SettingsFile(), "enableMilkingEquipmentRefits", 1) == 1
EndFunction

Bool Function NeedsRefit() Global
    Return IsFeatureEnabled() && StorageUtil.GetIntValue(Game.GetPlayer(), NeedsRefitKey(), 0) == 1
EndFunction

Function Reconcile(String source = "unspecified") Global
    Actor playerActor = Game.GetPlayer()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If playerActor == None || milkController == None
        Alarm("reconcile failed | player or MME controller unavailable | source=" + source)
        Return
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(playerActor, milkController)
        ClearState(playerActor, "player is not a Milk Maid | source=" + source)
        Return
    EndIf

    Int currentLevel = MME_Storage.getMaidLevel(playerActor)
    If StorageUtil.GetIntValue(playerActor, InitializedKey(), 0) != 1
        Baseline(playerActor, currentLevel, "initial observation | source=" + source)
        Return
    EndIf
    Int previousLevel = StorageUtil.GetIntValue(playerActor, LastObservedLevelKey(), currentLevel)
    Int fittedLevel = StorageUtil.GetIntValue(playerActor, FittedLevelKey(), currentLevel)

    If !IsFeatureEnabled()
        Baseline(playerActor, currentLevel, "feature inactive | source=" + source)
        Return
    EndIf

    If currentLevel > previousLevel
        StorageUtil.SetIntValue(playerActor, NeedsRefitKey(), 1)
        Trace("refit armed | previous=" + previousLevel + " | current=" + currentLevel + " | fitted=" + fittedLevel + " | source=" + source)
        ShowReminder(playerActor, True)
    ElseIf currentLevel < previousLevel && currentLevel <= fittedLevel
        StorageUtil.UnsetIntValue(playerActor, NeedsRefitKey())
        Trace("refit cleared after level decrease | previous=" + previousLevel + " | current=" + currentLevel + " | fitted=" + fittedLevel + " | source=" + source)
    EndIf
    StorageUtil.SetIntValue(playerActor, LastObservedLevelKey(), currentLevel)
EndFunction

Function HandleSettingsChanged(String source = "MCM changed") Global
    Reconcile(source)
EndFunction

Function HandleArmorEquipped(Actor wearer, Armor equippedArmor) Global
    Actor playerActor = Game.GetPlayer()
    If wearer == None || wearer != playerActor || equippedArmor == None
        Return
    EndIf
    Reconcile("player armor equipped")
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If ShouldBypassMilkingEquipmentProtection(wearer, equippedArmor, milkController)
        ShowReminder(playerActor, False)
    EndIf
EndFunction

Bool Function ShouldBypassMilkingEquipmentProtection(Actor wearer, Armor wornArmor, MilkQUEST milkController) Global
    If wearer == None || wearer != Game.GetPlayer() || wornArmor == None || milkController == None || !NeedsRefit()
        Return False
    EndIf
    Bool eligible = IsEligibleOrdinaryMilkingEquipment(wornArmor, milkController)
    If eligible
        Trace("ordinary MilkingEquipment protection bypass permitted | armor=" + GetArmorName(wornArmor))
    EndIf
    Return eligible
EndFunction

Bool Function IsEligibleOrdinaryMilkingEquipment(Armor wornArmor, MilkQUEST milkController) Global
    If wornArmor == None || milkController == None
        Return False
    EndIf
    ; Original MME equipment and every special armor class remain protected.
    If wornArmor == milkController.MilkCuirass || wornArmor == milkController.MilkCuirassFuta \
    || wornArmor == milkController.TITS4 || wornArmor == milkController.TITS6 || wornArmor == milkController.TITS8
        Return False
    EndIf
    String armorName = wornArmor.GetName()
    If armorName == "" || armorName == "Empty" || armorName == "empty"
        Return False
    EndIf
    If MMEArmorScript.FindBasicLivingArmorNameDirect(milkController, armorName) >= 0 \
    || MMEArmorScript.FindParasiteLivingArmorNameDirect(milkController, armorName) >= 0 \
    || MMECustomArmorRegistry.ClassifyCustomArmor(wornArmor) > 0
        Return False
    EndIf
    Return MMEArmorScript.CountMilkingEquipmentMatchesDirect(milkController, armorName) == 1
EndFunction

Int Function GetLiveServiceState(Actor blacksmith) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController) || !NeedsRefit()
        Return 0
    EndIf
    Armor wornArmor = playerActor.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    If !IsEligibleOrdinaryMilkingEquipment(wornArmor, milkController)
        Return 0
    EndIf
    Return 1
EndFunction

Bool Function TryRefit(Actor blacksmith) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, milkController) || !NeedsRefit()
        Reject("participants, settings, or pending state changed")
        Return False
    EndIf
    Armor wornArmor = playerActor.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    If !IsEligibleOrdinaryMilkingEquipment(wornArmor, milkController)
        Reject("eligible registered Milking Equipment is no longer worn")
        Return False
    EndIf
    Int currentLevel = MME_Storage.getMaidLevel(playerActor)
    StorageUtil.SetIntValue(playerActor, FittedLevelKey(), currentLevel)
    StorageUtil.SetIntValue(playerActor, LastObservedLevelKey(), currentLevel)
    StorageUtil.UnsetIntValue(playerActor, NeedsRefitKey())
    If StorageUtil.GetIntValue(playerActor, NeedsRefitKey(), 0) != 0 \
    || StorageUtil.GetIntValue(playerActor, FittedLevelKey(), -1) != currentLevel
        Alarm("refit state did not persist | level=" + currentLevel + " | armor=" + GetArmorName(wornArmor))
        Debug.Notification("The refit failed; no changes were made")
        Return False
    EndIf
    Debug.Notification("Your milking equipment now fits again")
    Trace("refit complete | level=" + currentLevel + " | armor=" + GetArmorName(wornArmor) + " | blacksmith=" + MMEForcedMilkDrink.GetActorName(blacksmith))
    Return True
EndFunction

Bool Function ValidateParticipants(Actor blacksmith, Actor playerActor, MilkQUEST milkController) Global
    If !MMEAlertsController.IsExtensionsEnabled() || !IsFeatureEnabled() \
    || blacksmith == None || playerActor == None || milkController == None
        Return False
    EndIf
    Faction blacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If blacksmithFaction == None || merchantFaction == None \
    || !blacksmith.IsInFaction(blacksmithFaction) || !blacksmith.IsInFaction(merchantFaction)
        Return False
    EndIf
    Return milkController.MilkMaidFaction != None && milkController.MilkSlaveFaction != None \
        && playerActor.IsInFaction(milkController.MilkMaidFaction) \
        && !playerActor.IsInFaction(milkController.MilkSlaveFaction)
EndFunction

Function ShowReminder(Actor playerActor, Bool force = False) Global
    If playerActor == None
        Return
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float last = StorageUtil.GetFloatValue(playerActor, LastNoticeTimeKey(), -100.0)
    If !force && now - last < 5.0
        Trace("equip reminder rate-limited")
        Return
    EndIf
    Debug.Notification("Your chests have gotten too big! Visit the blacksmith!")
    StorageUtil.SetFloatValue(playerActor, LastNoticeTimeKey(), now)
    Trace("refit reminder shown")
EndFunction

Function Baseline(Actor playerActor, Int currentLevel, String reason) Global
    StorageUtil.SetIntValue(playerActor, InitializedKey(), 1)
    StorageUtil.SetIntValue(playerActor, LastObservedLevelKey(), currentLevel)
    StorageUtil.SetIntValue(playerActor, FittedLevelKey(), currentLevel)
    StorageUtil.UnsetIntValue(playerActor, NeedsRefitKey())
    Trace("baseline established | level=" + currentLevel + " | " + reason)
EndFunction

Function ClearState(Actor playerActor, String reason) Global
    If playerActor == None
        Return
    EndIf
    StorageUtil.UnsetIntValue(playerActor, InitializedKey())
    StorageUtil.UnsetIntValue(playerActor, LastObservedLevelKey())
    StorageUtil.UnsetIntValue(playerActor, FittedLevelKey())
    StorageUtil.UnsetIntValue(playerActor, NeedsRefitKey())
    StorageUtil.UnsetFloatValue(playerActor, LastNoticeTimeKey())
    Trace("state cleared | " + reason)
EndFunction

String Function GetArmorName(Armor wornArmor) Global
    If wornArmor == None || wornArmor.GetName() == ""
        Return "<unnamed>"
    EndIf
    Return wornArmor.GetName()
EndFunction

Function Reject(String reason) Global
    MMELog.MasterDiagnostic("[MME Extensions Milking Refit] rejected | " + reason)
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Milking Refit] " + detail)
EndFunction

Function Alarm(String detail) Global
    MMELog.Alarm("[MME Extensions Milking Refit] FAILURE: " + detail)
EndFunction
