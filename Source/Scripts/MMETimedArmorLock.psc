Scriptname MMETimedArmorLock Hidden

; Standalone, DD-free timed protection for explicitly registered slot-32 armor.
; JSON owns reusable definitions; StorageUtil owns per-save actor state.

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

String Function GetRuntimeRegistryFile() Global
    Return "/MMEAlerts/TimedArmorRegistry"
EndFunction

String Function GetActorListKey() Global
    Return "MMEExtensions.TimedArmor.Actors"
EndFunction

String Function GetLockedKey() Global
    Return "MMEExtensions.TimedArmor.Locked"
EndFunction

String Function GetArmorKey() Global
    Return "MMEExtensions.TimedArmor.Armor"
EndFunction

String Function GetDeadlineKey() Global
    Return "MMEExtensions.TimedArmor.Deadline"
EndFunction

String Function GetGuardKey() Global
    Return "MMEExtensions.TimedArmor.Guard"
EndFunction

String Function GetEntryKey() Global
    Return "timed_armor_forms"
EndFunction

String Function GetNotificationFile() Global
    Return "/MMEAlerts/TimedArmorNotifications"
EndFunction

Spell Function GetPlayerIndicator() Global
    Return Game.GetFormFromFile(0x00089E, "MMEAlert.esp") as Spell
EndFunction

Function Trace(String reportText) Global
    MMELog.MasterDiagnostic("[MME Extensions Timed Armor] " + reportText)
EndFunction

Function Alarm(String reportText) Global
    MMELog.Alarm("[MME Extensions Timed Armor] " + reportText)
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<missing actor>"
    EndIf
    String actorName = target.GetDisplayName()
    If actorName == ""
        actorName = target.GetLeveledActorBase().GetName()
    EndIf
    Return actorName
EndFunction

Bool Function CatalogContains(String configFile, Armor targetArmor) Global
    If targetArmor == None || !JsonUtil.JsonExists(configFile) || !JsonUtil.IsGood(configFile)
        Return False
    EndIf
    String[] entries = JsonUtil.PathStringElements(configFile, "." + GetEntryKey())
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 2 && parts[0] != "" && parts[1] != ""
            Armor configuredArmor = Game.GetFormFromFile(parts[1] as Int, parts[0]) as Armor
            If configuredArmor != None && configuredArmor == targetArmor
                Return True
            EndIf
        EndIf
        index += 1
    EndWhile
    Return False
EndFunction

Bool Function IsRegisteredArmor(Armor targetArmor) Global
    Return CatalogContains("/MMEAlerts/TimedArmor_C5Kev", targetArmor) \
        || CatalogContains("/MMEAlerts/TimedArmor_Dwemer", targetArmor) \
        || CatalogContains(GetRuntimeRegistryFile(), targetArmor)
EndFunction

Int Function GetRegisteredArmorClass(Armor targetArmor) Global
    Int armorClass = GetCatalogArmorClass("/MMEAlerts/TimedArmor_C5Kev", targetArmor)
    If armorClass == 0
        armorClass = GetCatalogArmorClass("/MMEAlerts/TimedArmor_Dwemer", targetArmor)
    EndIf
    If armorClass == 0
        armorClass = GetCatalogArmorClass(GetRuntimeRegistryFile(), targetArmor)
    EndIf
    Return armorClass
EndFunction

Int Function GetCatalogArmorClass(String configFile, Armor targetArmor) Global
    If targetArmor == None || !JsonUtil.JsonExists(configFile) || !JsonUtil.IsGood(configFile)
        Return 0
    EndIf
    String[] entries = JsonUtil.PathStringElements(configFile, "." + GetEntryKey())
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 3 && parts[0] != "" && parts[1] != "" \
            && Game.GetFormFromFile(parts[1] as Int, parts[0]) == targetArmor
            Int armorClass = parts[2] as Int
            If armorClass >= 1 && armorClass <= 4
                Return armorClass
            EndIf
            Alarm("registered armor has invalid class | file=" + configFile + " | entry=" + entries[index])
            Return 0
        EndIf
        index += 1
    EndWhile
    Return 0
EndFunction

Bool Function IsSlot32Armor(Armor targetArmor) Global
    Return targetArmor != None && Math.LogicalAnd(targetArmor.GetSlotMask(), Armor.GetMaskForSlot(32)) != 0
EndFunction

Bool Function RegisterArmor(String pluginName, Int localFormID, Int armorClass) Global
    If pluginName == "" || localFormID <= 0 || armorClass < 1 || armorClass > 4
        Trace("register rejected | invalid plugin, form, or class")
        Return False
    EndIf
    Armor targetArmor = Game.GetFormFromFile(localFormID, pluginName) as Armor
    If targetArmor == None || !IsSlot32Armor(targetArmor)
        Trace("register rejected | form missing or not slot 32 | " + pluginName + ":" + localFormID)
        Return False
    EndIf
    String entry = pluginName + "|" + localFormID + "|" + armorClass + "|" + targetArmor.GetName()
    If JsonUtil.StringListFind(GetRuntimeRegistryFile(), GetEntryKey(), entry) >= 0
        Trace("register skipped | already present | " + entry)
        Return False
    EndIf
    If JsonUtil.StringListAdd(GetRuntimeRegistryFile(), GetEntryKey(), entry, False) < 0 || !JsonUtil.Save(GetRuntimeRegistryFile(), False)
        Alarm("registry save failed | " + entry)
        Return False
    EndIf
    Trace("register complete | " + entry)
    Return True
EndFunction

Bool Function UnregisterArmor(String pluginName, Int localFormID) Global
    String[] entries = JsonUtil.PathStringElements(GetRuntimeRegistryFile(), "." + GetEntryKey())
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 2 && parts[0] == pluginName && (parts[1] as Int) == localFormID
            If JsonUtil.StringListRemove(GetRuntimeRegistryFile(), GetEntryKey(), entries[index], True) > 0 && JsonUtil.Save(GetRuntimeRegistryFile(), False)
                Trace("unregister complete | " + entries[index])
                Return True
            EndIf
            Alarm("unregister save failed | " + entries[index])
            Return False
        EndIf
        index += 1
    EndWhile
    Trace("unregister skipped | entry not found | " + pluginName + ":" + localFormID)
    Return False
EndFunction

Bool Function IsLocked(Actor target) Global
    Return target != None && StorageUtil.GetIntValue(target, GetLockedKey(), 0) == 1
EndFunction

Armor Function GetLockedArmor(Actor target) Global
    Return StorageUtil.GetFormValue(target, GetArmorKey(), None) as Armor
EndFunction

Float Function GetDaysRemaining(Actor target) Global
    If !IsLocked(target)
        Return 0.0
    EndIf
    Float remaining = StorageUtil.GetFloatValue(target, GetDeadlineKey(), 0.0) - Utility.GetCurrentGameTime()
    If remaining < 0.0
        Return 0.0
    EndIf
    Return remaining
EndFunction

Function RefreshPlayerIndicator(Actor target) Global
    If target != Game.GetPlayer()
        Return
    EndIf
    Spell indicator = GetPlayerIndicator()
    If indicator == None
        Alarm("player indicator spell is missing from MMEAlert.esp")
        Return
    EndIf
    If IsLocked(target)
        If !target.HasSpell(indicator)
            target.AddSpell(indicator, False)
            Trace("player Active Effects indicator restored")
        EndIf
    ElseIf target.HasSpell(indicator)
        target.RemoveSpell(indicator)
        Trace("player Active Effects indicator removed")
    EndIf
EndFunction

Bool Function TryLock(Actor target, Armor targetArmor, Float durationDays = -1.0, String source = "API") Global
    If target == None || targetArmor == None || !IsRegisteredArmor(targetArmor) || !IsSlot32Armor(targetArmor)
        Trace("lock rejected | source=" + source + " | actor/armor invalid or unregistered")
        Return False
    EndIf
    If IsLocked(target)
        If GetLockedArmor(target) == targetArmor
            Trace("duplicate lock ignored | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName())
        Else
            Trace("lock rejected | actor already owns another timed chest lock | actor=" + GetActorName(target))
        EndIf
        Return False
    EndIf
    If durationDays < 0.0
        durationDays = JsonUtil.GetFloatValue(GetSettingsFile(), "timedArmorLockDays", 3.0)
    EndIf
    If durationDays < 0.0
        durationDays = 0.0
    ElseIf durationDays > 30.0
        durationDays = 30.0
    EndIf
    Float deadline = Utility.GetCurrentGameTime() + durationDays
    StorageUtil.SetIntValue(target, GetLockedKey(), 1)
    StorageUtil.SetFormValue(target, GetArmorKey(), targetArmor)
    StorageUtil.SetFloatValue(target, GetDeadlineKey(), deadline)
    StorageUtil.FormListAdd(None, GetActorListKey(), target, False)
    ; Do not use abPreventRemoval here. Skyrim owns its generic rejection text
    ; and emits no unequip event when it blocks the attempt. The native equip
    ; sink instead observes a real removal and this service restores the piece.
    If !target.IsEquipped(targetArmor)
        StorageUtil.SetIntValue(target, GetGuardKey(), 1)
        target.EquipItem(targetArmor, False, True)
        StorageUtil.UnsetIntValue(target, GetGuardKey())
    EndIf
    If !target.IsEquipped(targetArmor)
        Alarm("protected equip failed | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName())
        ClearState(target)
        Return False
    EndIf
    RefreshPlayerIndicator(target)
    Int shownDays = durationDays as Int
    If durationDays > shownDays
        shownDays += 1
    EndIf
    Debug.Notification("The armor magically wraps around you. Enjoy it for the next " + shownDays + " days!")
    Trace("lock complete | source=" + source + " | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName() + " | days=" + durationDays + " | deadline=" + deadline)
    Publish("MMEExtensions_TimedArmorLocked", target, targetArmor, durationDays, source)
    RefreshScheduling()
    Return True
EndFunction

Bool Function TryLockRegisteredEquip(Actor target, Armor targetArmor) Global
    If !IsRegisteredArmor(targetArmor)
        Return False
    EndIf
    If target != Game.GetPlayer() && MMEChestArmorTrap.IsTrapEquipPending(target, targetArmor)
        Trace("automatic lock bypassed for NPC chest-trap equip | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName())
        Return False
    EndIf
    Return TryLock(target, targetArmor, -1.0, "Automatic Equip")
EndFunction

; True means ordinary unequip cleanup must be suppressed because the lock
; restored the armor. Release paths clear state before unequipping and return false.
Bool Function HandleUnequip(Actor target, Armor targetArmor) Global
    If target == None || targetArmor == None || !IsLocked(target) || GetLockedArmor(target) != targetArmor
        Return False
    EndIf
    If StorageUtil.GetIntValue(target, GetGuardKey(), 0) == 1
        Trace("unequip callback ignored inside guarded transaction | actor=" + GetActorName(target))
        Return True
    EndIf
    If GetDaysRemaining(target) <= 0.0
        Release(target, "Timer Expired")
        Return False
    EndIf
    StorageUtil.SetIntValue(target, GetGuardKey(), 1)
    If target.GetItemCount(targetArmor) <= 0
        target.AddItem(targetArmor, 1, True)
        Trace("removed locked armor restored to inventory | actor=" + GetActorName(target))
    EndIf
    target.EquipItem(targetArmor, False, True)
    StorageUtil.UnsetIntValue(target, GetGuardKey())
    If !target.IsEquipped(targetArmor)
        Alarm("premature-removal recovery failed | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName())
        Publish("MMEExtensions_TimedArmorFailed", target, targetArmor, GetDaysRemaining(target), "Reequip Failed")
    Else
        ShowUnequipResistedNotification(target)
        Trace("premature removal resisted | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName() + " | days remaining=" + GetDaysRemaining(target))
        Publish("MMEExtensions_TimedArmorReequipped", target, targetArmor, GetDaysRemaining(target), "Removal Resisted")
    EndIf
    Return True
EndFunction

Function ShowUnequipResistedNotification(Actor target) Global
    String configFile = GetNotificationFile()
    String poolName = "unequip_resisted"
    String selected = "The armor gives you a teasing squeeze and refuses to let go."
    If JsonUtil.JsonExists(configFile) && JsonUtil.IsGood(configFile)
        Int count = JsonUtil.StringListCount(configFile, poolName)
        If count > 0
            selected = JsonUtil.StringListGet(configFile, poolName, Utility.RandomInt(0, count - 1))
        EndIf
    Else
        Alarm("unequip notification JSON is missing or malformed; using fallback")
    EndIf
    If selected == ""
        selected = "The armor gives you a teasing squeeze and refuses to let go."
    EndIf
    Debug.Notification(selected)
    Trace("playful removal rejection shown | actor=" + GetActorName(target))
EndFunction

Bool Function Release(Actor target, String source = "API") Global
    If target == None || !IsLocked(target)
        Trace("release skipped | no active lock | source=" + source)
        Return False
    EndIf
    Armor targetArmor = GetLockedArmor(target)
    ClearState(target)
    RefreshPlayerIndicator(target)
    If targetArmor != None && target.IsEquipped(targetArmor)
        target.UnequipItem(targetArmor, False, True)
    EndIf
    If targetArmor != None && target.IsEquipped(targetArmor)
        Alarm("release failed: armor remains equipped | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName())
        Publish("MMEExtensions_TimedArmorFailed", target, targetArmor, 0.0, "Release Failed")
        Return False
    EndIf
    Debug.Notification(GetActorName(target) + " is released from the armor.")
    Trace("release complete | source=" + source + " | actor=" + GetActorName(target))
    Publish("MMEExtensions_TimedArmorReleased", target, targetArmor, 0.0, source)
    RefreshScheduling()
    Return True
EndFunction

Function ClearState(Actor target) Global
    If target == None
        Return
    EndIf
    StorageUtil.UnsetIntValue(target, GetLockedKey())
    StorageUtil.UnsetFormValue(target, GetArmorKey())
    StorageUtil.UnsetFloatValue(target, GetDeadlineKey())
    StorageUtil.UnsetIntValue(target, GetGuardKey())
    StorageUtil.FormListRemove(None, GetActorListKey(), target, True)
EndFunction

Float Function GetNextDeadline() Global
    Float nextDeadline = 0.0
    Int index = StorageUtil.FormListCount(None, GetActorListKey()) - 1
    While index >= 0
        Actor target = StorageUtil.FormListGet(None, GetActorListKey(), index) as Actor
        If target != None && IsLocked(target)
            Float deadline = StorageUtil.GetFloatValue(target, GetDeadlineKey(), 0.0)
            If deadline > 0.0 && (nextDeadline <= 0.0 || deadline < nextDeadline)
                nextDeadline = deadline
            EndIf
        EndIf
        index -= 1
    EndWhile
    Return nextDeadline
EndFunction

Function ResolveDue(Float now) Global
    Int index = StorageUtil.FormListCount(None, GetActorListKey()) - 1
    While index >= 0
        Actor target = StorageUtil.FormListGet(None, GetActorListKey(), index) as Actor
        If target == None
            StorageUtil.FormListRemoveAt(None, GetActorListKey(), index)
        ElseIf !IsLocked(target)
            StorageUtil.FormListRemoveAt(None, GetActorListKey(), index)
        ElseIf StorageUtil.GetFloatValue(target, GetDeadlineKey(), 0.0) <= now
            Expire(target)
        EndIf
        index -= 1
    EndWhile
EndFunction

Function Expire(Actor target) Global
    If target == None || !IsLocked(target)
        Trace("expiration skipped | no active lock")
        Return
    EndIf
    Armor targetArmor = GetLockedArmor(target)
    Int armorClass = GetRegisteredArmorClass(targetArmor)
    ; Parasite armor becomes removable at its deadline but remains on its
    ; wearer. Explicit API, vendor and MCM releases still use Release() and
    ; therefore retain their existing immediate-unequip behavior.
    If armorClass == 3
        ClearState(target)
        RefreshPlayerIndicator(target)
        Debug.Notification(GetActorName(target) + "'s armor is satisfied and willing to release its well milked morsel!")
        Trace("parasite timer expired | lock cleared; armor intentionally retained | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName() + " | equipped=" + target.IsEquipped(targetArmor))
        Publish("MMEExtensions_TimedArmorReleased", target, targetArmor, 0.0, "Timer Expired")
        RefreshScheduling()
    Else
        Release(target, "Timer Expired")
    EndIf
EndFunction

Function RecoverAfterLoad() Global
    Float now = Utility.GetCurrentGameTime()
    ResolveDue(now)
    Int index = StorageUtil.FormListCount(None, GetActorListKey()) - 1
    While index >= 0
        Actor target = StorageUtil.FormListGet(None, GetActorListKey(), index) as Actor
        If target != None && IsLocked(target)
            Armor targetArmor = GetLockedArmor(target)
            If targetArmor == None
                Alarm("load recovery cleared unresolved armor | actor=" + GetActorName(target))
                ClearState(target)
            Else
                ; Reapplying with abPreventRemoval=False also converts locks
                ; created by the previous hard-lock release to the soft path.
                target.EquipItem(targetArmor, False, True)
                Trace("load recovery refreshed soft lock | actor=" + GetActorName(target) + " | armor=" + targetArmor.GetName())
                RefreshPlayerIndicator(target)
            EndIf
        EndIf
        index -= 1
    EndWhile
    Trace("load recovery complete | active actors=" + StorageUtil.FormListCount(None, GetActorListKey()))
    RefreshScheduling()
EndFunction

Function AuditCatalog(String configFile) Global
    If !JsonUtil.JsonExists(configFile)
        Return
    EndIf
    If !JsonUtil.IsGood(configFile)
        Alarm("catalog is malformed | " + configFile)
        Return
    EndIf
    String[] entries = JsonUtil.PathStringElements(configFile, "." + GetEntryKey())
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length < 2 || parts[0] == "" || parts[1] == ""
            Alarm("malformed catalog entry | file=" + configFile + " | index=" + index)
        ElseIf Game.GetModByName(parts[0]) != 255
            Armor configuredArmor = Game.GetFormFromFile(parts[1] as Int, parts[0]) as Armor
            If configuredArmor == None || !IsSlot32Armor(configuredArmor)
                Alarm("installed catalog armor is missing or not slot 32 | " + entries[index])
            EndIf
        EndIf
        index += 1
    EndWhile
EndFunction

Function AuditCatalogs() Global
    AuditCatalog("/MMEAlerts/TimedArmor_C5Kev")
    AuditCatalog("/MMEAlerts/TimedArmor_Dwemer")
    AuditCatalog(GetRuntimeRegistryFile())
    Trace("catalog audit complete")
EndFunction

Function RefreshScheduling() Global
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshTimedArmorScheduling()
    EndIf
EndFunction

Bool Function Publish(String eventName, Actor target, Armor targetArmor, Float days, String source) Global
    Int handle = ModEvent.Create(eventName)
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, target)
    ModEvent.PushForm(handle, targetArmor)
    ModEvent.PushFloat(handle, days)
    ModEvent.PushString(handle, source)
    Return ModEvent.Send(handle)
EndFunction
