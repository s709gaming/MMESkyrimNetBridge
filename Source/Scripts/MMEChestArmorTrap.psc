Scriptname MMEChestArmorTrap Hidden

String Function GetC5Catalog() Global
    Return "/MMEAlerts/TimedArmor_C5Kev"
EndFunction

String Function GetDwemerCatalog() Global
    Return "/MMEAlerts/TimedArmor_Dwemer"
EndFunction

; Return 1 only after an armor is equipped and synchronously locked. A zero
; lets the controller continue to conversion and milk-drink outcomes.
Int Function HandleActivation(Actor opener, String chestIdentity, Bool inDwemerRuin) Global
    String settings = "/MMEAlerts/Settings"
    If !MMEAlertsController.IsExtensionsEnabled() || JsonUtil.GetIntValue(settings, "enableChestArmorTrap", 1) != 1
        Return 0
    EndIf
    If opener == None || chestIdentity == ""
        Alarm("malformed activation: opener or chest identity missing")
        Return 0
    EndIf
    Float nowGame = Utility.GetCurrentGameTime()
    Float nextAllowed = StorageUtil.GetFloatValue(None, "MMEExtensions.ChestArmor.NextAllowedGameDay", -1.0)
    If nextAllowed > nowGame
        Trace("cooldown active | chest=" + chestIdentity + " | remaining hours=" + ((nextAllowed - nowGame) * 24.0))
        Return 0
    EndIf
    Actor target = MMEChestTrapTargets.SelectTarget(opener, 1, 1500.0)
    If target == None
        Trace("no eligible nearby allied female | chest=" + chestIdentity)
        Return 0
    EndIf

    Armor selected = None
    If inDwemerRuin
        Int ruinChance = ClampChance(JsonUtil.GetIntValue(settings, "dwemerRuinArmorTrapChance", 25))
        Int ruinRoll = Utility.RandomInt(1, 100)
        Trace("Dwemer ruin roll | chance=" + ruinChance + " | roll=" + ruinRoll)
        If ruinChance > 0 && ruinRoll <= ruinChance
            selected = SelectCandidate(True, False)
        EndIf
    EndIf
    If selected == None
        Int generalChance = ClampChance(JsonUtil.GetIntValue(settings, "chestArmorTrapChance", 5))
        Int generalRoll = Utility.RandomInt(1, 100)
        Trace("general roll | chance=" + generalChance + " | roll=" + generalRoll)
        If generalChance <= 0 || generalRoll > generalChance
            Return 0
        EndIf
        Bool allowDwemer = inDwemerRuin || JsonUtil.GetIntValue(settings, "enableDwemerArmorOutsideRuins", 0) == 1
        selected = SelectCandidate(False, allowDwemer)
    EndIf
    If selected == None
        Trace("roll succeeded but no installed eligible armor candidate | chest=" + chestIdentity)
        Return 0
    EndIf

    Int armorClass = GetCatalogClass(selected)
    If armorClass < 2 || armorClass > 4
        Alarm("selected armor has invalid class | armor=" + selected.GetName() + " | class=" + armorClass)
        Return 0
    EndIf
    EnsureCustomClassification(selected, armorClass)
    If target.GetItemCount(selected) <= 0
        target.AddItem(selected, 1, True)
    EndIf
    Bool locked = MMETimedArmorLock.TryLock(target, selected, -1.0, "Treasure Chest Trap")
    If !locked || !target.IsEquipped(selected) || !MMETimedArmorLock.IsLocked(target)
        Alarm("equip/lock failed | actor=" + GetActorName(target) + " | armor=" + selected.GetName())
        Return 0
    EndIf
    Float cooldown = JsonUtil.GetFloatValue(settings, "chestArmorTrapCooldownHours", 4.0)
    If cooldown < 0.0
        cooldown = 0.0
    ElseIf cooldown > 24.0
        cooldown = 24.0
    EndIf
    StorageUtil.SetFloatValue(None, "MMEExtensions.ChestArmor.NextAllowedGameDay", nowGame + (cooldown / 24.0))
    Trace("complete | chest=" + chestIdentity + " | actor=" + GetActorName(target) + " | armor=" + selected.GetName() + " | class=" + armorClass + " | cooldown hours=" + cooldown)
    Return 1
EndFunction

Int Function ClampChance(Int value) Global
    If value < 0
        Return 0
    ElseIf value > 100
        Return 100
    EndIf
    Return value
EndFunction

Armor Function SelectCandidate(Bool dwemerOnly, Bool includeDwemer) Global
    Int c5Count = 0
    If !dwemerOnly
        c5Count = CountCandidates(GetC5Catalog(), False)
    EndIf
    Int dwemerCount = 0
    If dwemerOnly || includeDwemer
        dwemerCount = CountCandidates(GetDwemerCatalog(), True)
    EndIf
    Int total = c5Count + dwemerCount
    Trace("candidate pool | dwemerOnly=" + dwemerOnly + " | C5=" + c5Count + " | Dwemer=" + dwemerCount)
    If total <= 0
        Return None
    EndIf
    Int pick = Utility.RandomInt(0, total - 1)
    If pick < c5Count
        Return GetCandidate(GetC5Catalog(), pick, False)
    EndIf
    Return GetCandidate(GetDwemerCatalog(), pick - c5Count, True)
EndFunction

Int Function CountCandidates(String catalog, Bool requireDwemer) Global
    If !JsonUtil.JsonExists(catalog) || !JsonUtil.IsGood(catalog)
        Return 0
    EndIf
    String[] entries = JsonUtil.PathStringElements(catalog, ".trap_armor_forms")
    Int count = 0
    Int index = 0
    While index < entries.Length
        If ResolveEntry(entries[index], requireDwemer) != None
            count += 1
        EndIf
        index += 1
    EndWhile
    Return count
EndFunction

Armor Function GetCandidate(String catalog, Int wanted, Bool requireDwemer) Global
    String[] entries = JsonUtil.PathStringElements(catalog, ".trap_armor_forms")
    Int found = 0
    Int index = 0
    While index < entries.Length
        Armor candidate = ResolveEntry(entries[index], requireDwemer)
        If candidate != None
            If found == wanted
                Return candidate
            EndIf
            found += 1
        EndIf
        index += 1
    EndWhile
    Return None
EndFunction

Armor Function ResolveEntry(String entry, Bool requireDwemer) Global
    String[] parts = StringUtil.Split(entry, "|")
    If parts.Length < 3 || parts[0] == "" || parts[1] == ""
        Alarm("malformed installed armor catalog entry | " + entry)
        Return None
    EndIf
    Int armorClass = parts[2] as Int
    If (requireDwemer && armorClass != 4) || (!requireDwemer && (armorClass < 2 || armorClass > 3))
        Return None
    EndIf
    If !IsArmorClassEnabled(armorClass)
        Return None
    EndIf
    Armor targetArmor = Game.GetFormFromFile(parts[1] as Int, parts[0]) as Armor
    If targetArmor == None
        If Game.GetModByName(parts[0]) != 255
            Alarm("installed catalog armor could not resolve | " + entry)
        EndIf
        Return None
    EndIf
    If Math.LogicalAnd(targetArmor.GetSlotMask(), Armor.GetMaskForSlot(32)) == 0
        Alarm("installed trap armor is not slot 32 | " + entry)
        Return None
    EndIf
    Return targetArmor
EndFunction

Bool Function IsArmorClassEnabled(Int armorClass) Global
    String settings = "/MMEAlerts/Settings"
    If armorClass == 2
        Return JsonUtil.GetIntValue(settings, "enableLivingArmorChestTrap", 1) == 1
    ElseIf armorClass == 3
        Return JsonUtil.GetIntValue(settings, "enableParasiteArmorChestTrap", 1) == 1
    ElseIf armorClass == 4
        Return JsonUtil.GetIntValue(settings, "enableDwemerArmorChestTrap", 1) == 1
    EndIf
    Return False
EndFunction

Int Function GetCatalogClass(Armor targetArmor) Global
    Int result = FindClass(GetC5Catalog(), targetArmor)
    If result == 0
        result = FindClass(GetDwemerCatalog(), targetArmor)
    EndIf
    Return result
EndFunction

Int Function FindClass(String catalog, Armor targetArmor) Global
    String[] entries = JsonUtil.PathStringElements(catalog, ".trap_armor_forms")
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 3 && Game.GetFormFromFile(parts[1] as Int, parts[0]) == targetArmor
            Return parts[2] as Int
        EndIf
        index += 1
    EndWhile
    Return 0
EndFunction

Function EnsureCustomClassification(Armor targetArmor, Int armorClass) Global
    If MMECustomArmorRegistry.ClassifyCustomArmor(targetArmor) == armorClass
        Return
    EndIf
    ; Provider entries are registered by matching their exact resolved form.
    RegisterMatchingEntry(GetC5Catalog(), targetArmor, armorClass)
    RegisterMatchingEntry(GetDwemerCatalog(), targetArmor, armorClass)
EndFunction

Function RegisterMatchingEntry(String catalog, Armor targetArmor, Int armorClass) Global
    String[] entries = JsonUtil.PathStringElements(catalog, ".trap_armor_forms")
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 3 && Game.GetFormFromFile(parts[1] as Int, parts[0]) == targetArmor
            MMECustomArmorRegistry.RegisterArmor(parts[0], parts[1] as Int, armorClass)
            Return
        EndIf
        index += 1
    EndWhile
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Chest Armor] " + detail)
EndFunction

Function Alarm(String detail) Global
    MMELog.Alarm("[MME Extensions Chest Armor] FAILURE: " + detail)
EndFunction
