Scriptname MMEArmorFamiliarity Hidden

; One body outfit + removal time per actor. -1 means worn; time is game days.
; Presentation policy only: never changes MME, equipment, locks or effects.
Bool Function IsBodyArmor(Armor item) Global
    Return item != None && Math.LogicalAnd(item.GetSlotMask(), Armor.GetMaskForSlot(32)) != 0
EndFunction

Function Trace(Actor target, String reason) Global
    MMELog.MasterDiagnostic("[MME Armor Familiarity] actor=" + target + " | " + reason)
EndFunction

; Startup/observation only. Never call this from an incoming equip handler.
Function Seed(Actor target) Global
    If target == None
        Return
    EndIf
    If StorageUtil.GetFormValue(target, "MME.ArmorFamiliarity.Last") != None
        Return
    EndIf
    If target.IsDead() || target.IsDisabled() || !target.Is3DLoaded()
        Return
    EndIf
    Armor worn = target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    If worn != None
        StorageUtil.SetFormValue(target, "MME.ArmorFamiliarity.Last", worn)
        StorageUtil.SetFloatValue(target, "MME.ArmorFamiliarity.Removed", -1.0)
        StorageUtil.SetStringValue(target, "MME.ArmorFamiliarity.DwemerItem", MMEDwemerAttachment.Tag(target, worn))
        Trace(target, "seeded currently worn outfit")
    EndIf
EndFunction

Function Observe(Actor[] actors) Global
    Seed(Game.GetPlayer())
    Int index = 0
    While index < actors.Length
        Seed(actors[index])
        index += 1
    EndWhile
EndFunction

; Compute once per native equip event, before any latent story dispatch.
; Returning True suppresses ordinary presentation, never gameplay bookkeeping.
Bool Function OnEquip(Actor target, Armor item) Global
    If target == None || !IsBodyArmor(item)
        Return False
    EndIf
    If target.GetWornForm(Armor.GetMaskForSlot(32)) != item
        Trace(target, "stale equip ignored for presentation")
        Return True
    EndIf
    Armor last = StorageUtil.GetFormValue(target, "MME.ArmorFamiliarity.Last") as Armor
    Float removed = StorageUtil.GetFloatValue(target, "MME.ArmorFamiliarity.Removed", -1.0)
    Float now = Utility.GetCurrentGameTime()
    String lastInstance = StorageUtil.GetStringValue(target, "MME.ArmorFamiliarity.DwemerItem", "")
    String instance = MMEDwemerAttachment.Tag(target, item)
    Bool familiar = last == item && lastInstance == instance && (removed < 0.0 || now < removed || now - removed < (8.0 / 24.0))
    StorageUtil.SetFormValue(target, "MME.ArmorFamiliarity.Last", item)
    StorageUtil.SetStringValue(target, "MME.ArmorFamiliarity.DwemerItem", instance)
    StorageUtil.SetFloatValue(target, "MME.ArmorFamiliarity.Removed", -1.0)
    If familiar
        Trace(target, "familiar re-equip| ordinary presentation suppressed")
    ElseIf last == item
        Trace(target, "eight-hour absence expired| ordinary presentation eligible")
    Else
        Trace(target, "different outfit remembered| ordinary presentation eligible")
    EndIf
    Return familiar
EndFunction

Function OnUnequip(Actor target, Armor item) Global
    If target == None || !IsBodyArmor(item)
        Return
    EndIf
    ; A delayed removal for an item already restored must not start expiry.
    If target.GetWornForm(Armor.GetMaskForSlot(32)) == item
        Return
    EndIf
    Armor last = StorageUtil.GetFormValue(target, "MME.ArmorFamiliarity.Last") as Armor
    If last != None && last != item
        Return
    EndIf
    If last == None
        ; First observed removal proves it was worn before this event.
        StorageUtil.SetFormValue(target, "MME.ArmorFamiliarity.Last", item)
    ElseIf StorageUtil.GetFloatValue(target, "MME.ArmorFamiliarity.Removed", -1.0) >= 0.0
        Return
    EndIf
    StorageUtil.SetFloatValue(target, "MME.ArmorFamiliarity.Removed", Utility.GetCurrentGameTime())
    Trace(target, "outfit removed| eight-hour absence begins")
EndFunction
