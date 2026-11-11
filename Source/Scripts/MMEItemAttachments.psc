Scriptname MMEItemAttachments Hidden

; Exact inventory item facade. Built-in Dwemer suits remain base-form compatibility.
; Operations: -1 read/resolve, 0 capture, 1 install, 2 remove, 3 refit, 4 label.
String Function Request(Actor wearer, Armor item, Int operation, String expected = "", Int fittedLevel = 0, Int armorClass = 4) Global
    If wearer == None || item == None || !MMEAlertsController.IsExtensionsEnabled()
        Return "skip|feature disabled or target missing"
    EndIf
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePapyrusTrace", 0) == 1
    Int requestID = MMEExtensionsNative.QueueItemAttachment(wearer, item, operation, expected, diagnostic, fittedLevel, armorClass)
    MMELog.MasterDiagnostic("[MME Item Attachments] entry | request=" + requestID + " | actor=" + wearer + " | armor=" + item + " | operation=" + operation)
    If requestID <= 0
        Return "error|native request unavailable"
    EndIf
    String result = ""
    Int remaining = 100
    While result == "" && remaining > 0
        result = MMEExtensionsNative.GetDwemerAttachmentResult(requestID)
        If result == ""
            Utility.WaitMenuMode(0.05)
        EndIf
        remaining -= 1
    EndWhile
    If result == ""
        ; Cancellation atomically returns a completed commit, or removes the queued request.
        result = MMEExtensionsNative.GetDwemerAttachmentResult(requestID, True)
    EndIf
    MMELog.MasterDiagnostic("[MME Item Attachments] result/cleanup | request=" + requestID + " | actor=" + wearer + " | " + result)
    If StringUtil.Find(result, "error|") == 0
        Int generation = MMEExtensionsNative.GetMovementSlapSession()
        If StorageUtil.GetIntValue(wearer, "MME.DwemerInstance.Alarm", -1) != generation
            StorageUtil.SetIntValue(wearer, "MME.DwemerInstance.Alarm", generation)
            MMELog.Alarm("[MME Item Attachments] operation=" + operation + " | actor=" + wearer + " | armor=" + item + " | failure=" + result)
        EndIf
    EndIf
    Return result
EndFunction

String Function Identity(Actor wearer, Armor item) Global
    If wearer == None || item == None || wearer.GetWornForm(Armor.GetMaskForSlot(32)) != item
        Return ""
    EndIf
    String identity = MMEExtensionsNative.GetDwemerItemIdentity(wearer, item)
    If identity == "?"
        String resolved = Request(wearer, item, -1)
        If StringUtil.Find(resolved, "ok|") != 0
            Return ""
        EndIf
        identity = StringUtil.Substring(resolved, 3)
    EndIf
    Return identity
EndFunction

Int Function GetClass(Actor wearer, Armor item) Global
    If !MMEAlertsController.IsExtensionsEnabled() || Identity(wearer, item) == ""
        Return 0
    EndIf
    Int armorClass = MMEExtensionsNative.GetWornItemAttachmentClass(wearer, item)
    If armorClass > 0 && MMEExtensionsNative.DwemerLabelNeedsUpdate(wearer, item)
        Request(wearer, item, 4, Identity(wearer, item), 0, armorClass)
    EndIf
    Return MMEExtensionsNative.GetWornItemAttachmentClass(wearer, item)
EndFunction

; Cached non-latent lookup for original MME production/milking loops.
Int Function GetClassFast(Actor wearer, Armor item) Global
    If wearer == None || item == None || !MMEAlertsController.IsExtensionsEnabled()
        Return 0
    EndIf
    Return MMEExtensionsNative.GetWornItemAttachmentClass(wearer, item)
EndFunction

Bool Function Has(Actor wearer, Armor item) Global
    Return GetClass(wearer, item) > 0
EndFunction

String Function Capture(Actor wearer, Armor item) Global
    String result = Request(wearer, item, 0)
    If StringUtil.Find(result, "ok|") == 0
        Return StringUtil.Substring(result, 3)
    EndIf
    Return ""
EndFunction

Bool Function Install(Actor wearer, Armor item, String identity, Int armorClass = 4) Global
    If identity == "" || identity == "ordinary"
        Return False
    EndIf
    Return StringUtil.Find(Request(wearer, item, 1, identity, MME_Storage.getMaidLevel(wearer), armorClass), "ok|") == 0
EndFunction

Bool Function Remove(Actor wearer, Armor item, String identity, Int armorClass = 4) Global
    If identity == "" || identity == "ordinary"
        Return False
    EndIf
    Return StringUtil.Find(Request(wearer, item, 2, identity, 0, armorClass), "ok|") == 0
EndFunction

String Function Tag(Actor wearer, Armor item) Global
    If !Has(wearer, item)
        Return ""
    EndIf
    Return MMEExtensionsNative.GetDwemerAttachmentTag(wearer, item)
EndFunction

Bool Function NeedsRefit(Actor wearer, Armor item) Global
    If !Has(wearer, item)
        Return False
    EndIf
    Int fitted = MMEExtensionsNative.GetDwemerRefitLevel(wearer, item)
    Return fitted >= 0 && MME_Storage.getMaidLevel(wearer) > fitted
EndFunction

Bool Function Refit(Actor wearer, Armor item) Global
    String identity = Capture(wearer, item)
    If identity == ""
        Return False
    EndIf
    Return StringUtil.Find(Request(wearer, item, 3, identity, MME_Storage.getMaidLevel(wearer), GetClass(wearer, item)), "ok|") == 0
EndFunction


Int Function ServiceState(Actor wearer, Int armorClass) Global
    If wearer == None || armorClass < 1 || armorClass > 4 || !MMEAlertsController.IsExtensionsEnabled()
        Return 0
    EndIf
    Armor item = wearer.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If item == None || milkController == None
        Return 0
    EndIf
    String busyReason = MMEAnimationSafety.GetStartBlockReason(wearer, milkController, False)
    If busyReason != ""
        MMELog.MasterDiagnostic("[MME Item Attachments] service skip | actor=" + wearer + " | reason=" + busyReason)
        Return 0
    EndIf
    If MMETimedArmorLock.IsLocked(wearer)
        Return 3
    EndIf
    Int current = GetClass(wearer, item)
    If current == armorClass
        Return 2
    ElseIf current > 0
        Return 3
    EndIf
    If MMEArmorScript.GetMMEArmorProtectionReason(milkController, item, "instance-service", wearer) != ""
        Return 3
    EndIf
    Return 1
EndFunction

Bool Function ApplyService(Actor wearer, Int armorClass, Bool adding) Global
    Int expected = 2
    If adding
        expected = 1
    EndIf
    If wearer == None || ServiceState(wearer, armorClass) != expected
        MMELog.MasterDiagnostic("[MME Item Attachments] service skip | target unavailable/protected or class changed")
        Return False
    EndIf
    Armor item = wearer.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    String identity = Capture(wearer, item)
    If ServiceState(wearer, armorClass) != expected
        MMELog.MasterDiagnostic("[MME Item Attachments] commit skipped | actor state changed during capture")
        Return False
    EndIf
    Bool result = False
    If adding
        result = Install(wearer, item, identity, armorClass)
    Else
        result = Remove(wearer, item, identity, armorClass)
    EndIf
    If !result
        Return False
    EndIf
    If adding && Identity(wearer, item) == identity
        MMECustomArmorRegistry.HandleCustomArmorEquipped(wearer, item)
        If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableRepeatOrdinaryArmorStories", 1) == 1
            MMEExtensionsAPI.TryRepeatArmorEquipStory(wearer, item)
        Else
            MMEArmorIntroduction.TryIntroduction(wearer, item, "Individual armor fitting service")
        EndIf
    ElseIf !adding
        Cleanup(wearer)
    EndIf
    MMELog.MasterDiagnostic("[MME Item Attachments] service complete | actor=" + wearer + " | class=" + armorClass + " | add=" + adding)
    Return True
EndFunction

Bool Function ToggleWorn(Actor wearer, Int armorClass) Global
    If wearer == None || armorClass < 1 || armorClass > 3
        Return False
    EndIf
    Return ApplyService(wearer, armorClass, ServiceState(wearer, armorClass) != 2)
EndFunction

Function Cleanup(Actor wearer) Global
    If wearer == None
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkForSprigganPassive == None
        Return
    EndIf
    If StorageUtil.GetIntValue(wearer, "MME.ItemAttachment.OwnsPassive", 0) == 1 && !MMECustomArmorRegistry.HasWornLivingArmor(wearer, milkController)
        wearer.RemoveSpell(milkController.MilkForSprigganPassive)
        If wearer.HasSpell(milkController.MilkForSprigganPassive)
            Int session = MMEExtensionsNative.GetMovementSlapSession()
            If StorageUtil.GetIntValue(wearer, "MME.ItemAttachment.CleanupAlarm", -1) != session
                StorageUtil.SetIntValue(wearer, "MME.ItemAttachment.CleanupAlarm", session)
                MMELog.Alarm("[MME Item Attachments] cleanup failed | actor=" + wearer + " | Living passive remains")
            EndIf
        Else
            StorageUtil.UnsetIntValue(wearer, "MME.ItemAttachment.OwnsPassive")
            MMELog.MasterDiagnostic("[MME Item Attachments] cleanup complete | actor=" + wearer)
        EndIf
    EndIf
EndFunction

Function ReportMigration() Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return
    EndIf
    Bool hasLegacy = False
    Int i = 0
    While (milkController.MilkingEquipment as Bool) && i < milkController.MilkingEquipment.Length
        If milkController.MilkingEquipment[i] != "Empty" && milkController.MilkingEquipment[i] != ""
            hasLegacy = True
        EndIf
        i += 1
    EndWhile
    i = 0
    While (milkController.BasicLivingArmor as Bool) && i < milkController.BasicLivingArmor.Length
        If milkController.BasicLivingArmor[i] != "Empty" && milkController.BasicLivingArmor[i] != ""
            hasLegacy = True
        EndIf
        i += 1
    EndWhile
    i = 0
    While (milkController.ParasiteLivingArmor as Bool) && i < milkController.ParasiteLivingArmor.Length
        If milkController.ParasiteLivingArmor[i] != "Empty" && milkController.ParasiteLivingArmor[i] != ""
            hasLegacy = True
        EndIf
        i += 1
    EndWhile
    MMELog.MasterDiagnostic("[MME Item Attachments] migration inspection | legacy entries=" + hasLegacy)
    If hasLegacy && StorageUtil.GetIntValue(None, "MME.ItemAttachment.MigrationNotice", 0) == 0
        StorageUtil.SetIntValue(None, "MME.ItemAttachment.MigrationNotice", 1)
        Debug.Notification(MMELocalization.Text("MME: clear old armor lists and refit desired individual items."))
        MMELog.MasterDiagnostic("[MME Item Attachments] migration | legacy name lists dormant; individual reinstallation required; Maid data preserved")
    EndIf
EndFunction

Function Reconcile(Actor wearer) Global
    If wearer == None || wearer.IsDead()
        Return
    EndIf
    Armor item = wearer.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    Int armorClass = GetClass(wearer, item)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkForSprigganPassive == None || !MMEArmorScript.IsMMEMilkMaid(wearer, milkController)
        Return
    EndIf
    If armorClass == 2 || armorClass == 3
        If !wearer.HasSpell(milkController.MilkForSprigganPassive)
            wearer.AddSpell(milkController.MilkForSprigganPassive, False)
            MMELog.MasterDiagnostic("[MME Item Attachments] restored worn passive | actor=" + wearer + " | class=" + armorClass)
        EndIf
        StorageUtil.SetIntValue(wearer, "MME.ItemAttachment.OwnsPassive", 1)
    ElseIf wearer.HasSpell(milkController.MilkForSprigganPassive) && !MMECustomArmorRegistry.HasWornLivingArmor(wearer, milkController)
        ; MME's named armor passive is no longer backed by a recognized worn item.
        StorageUtil.SetIntValue(wearer, "MME.ItemAttachment.OwnsPassive", 1)
        Cleanup(wearer)
    EndIf
EndFunction

Function Observe(Actor[] actors) Global
    Reconcile(Game.GetPlayer())
    Int i = 0
    While (actors as Bool) && i < actors.Length
        Reconcile(actors[i])
        i += 1
    EndWhile
EndFunction
