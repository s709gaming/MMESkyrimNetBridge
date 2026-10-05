Scriptname MMECustomArmorRegistry Hidden

; Unlimited, data-driven armor compatibility layered after MME's native forms
; and ten-slot name arrays. Exact entries are Plugin|decimal local ID|label.

String Function GetConfigFile() Global
    Return "/MMEAlerts/CustomArmorRegistry"
EndFunction

String Function GetDwemerArtisanKey() Global
    Return "MMEExtensions.CustomArmorRegistry.DwemerArtisanForms"
EndFunction

String Function GetFormKey(Int armorClass) Global
    If armorClass == 1
        Return "milk_forms"
    ElseIf armorClass == 2
        Return "living_forms"
    ElseIf armorClass == 3
        Return "parasite_forms"
    ElseIf armorClass == 4
        Return "dwemer_forms"
    EndIf
    Return ""
EndFunction

String Function GetNameKey(Int armorClass) Global
    If armorClass == 1
        Return "milk_names"
    ElseIf armorClass == 2
        Return "living_names"
    ElseIf armorClass == 3
        Return "parasite_names"
    ElseIf armorClass == 4
        Return "dwemer_names"
    EndIf
    Return ""
EndFunction

String Function GetClassLabel(Int armorClass) Global
    If armorClass == 1
        Return "Milking Armor"
    ElseIf armorClass == 2
        Return "Living Armor"
    ElseIf armorClass == 3
        Return "Living Parasite"
    ElseIf armorClass == 4
        Return "Dwemer Armor"
    EndIf
    Return "Unsupported"
EndFunction

String Function GetArmorName(Armor targetArmor) Global
    If targetArmor == None
        Return "<missing armor>"
    EndIf
    String armorName = targetArmor.GetName()
    If armorName == ""
        Return "<unnamed armor>"
    EndIf
    Return armorName
EndFunction

Function Trace(String reportText) Global
    MMELog.MasterDiagnostic("[MME Extensions Custom Armor] " + reportText)
EndFunction

Function Alarm(String reportText) Global
    MMELog.Alarm("[MME Extensions Custom Armor] " + reportText)
EndFunction

; Exact identities always win over optional display-name fallbacks. Category
; Dwemer is independent and wins any stale duplicate left by an older registry.
; Remaining precedence mirrors MME: Living, Parasite, then Milking equipment.
Int Function ClassifyCustomArmor(Armor targetArmor, Bool traceMatch = False) Global
    If targetArmor == None
        Return 0
    EndIf
    Int armorClass = MatchExactClass(targetArmor, 4)
    If armorClass == 0
        armorClass = MatchExactClass(targetArmor, 2)
    EndIf
    If armorClass == 0
        armorClass = MatchExactClass(targetArmor, 3)
    EndIf
    If armorClass == 0
        armorClass = MatchExactClass(targetArmor, 1)
    EndIf
    String source = "exact form"
    If armorClass == 0
        armorClass = MatchNameClass(targetArmor, 4)
        source = "name fallback"
    EndIf
    If armorClass == 0 && IsArtisanDwemerArmor(targetArmor)
        armorClass = 4
        source = "blacksmith attachment"
    EndIf
    If armorClass == 0
        armorClass = MatchNameClass(targetArmor, 2)
    EndIf
    If armorClass == 0
        armorClass = MatchNameClass(targetArmor, 3)
    EndIf
    If armorClass == 0
        armorClass = MatchNameClass(targetArmor, 1)
    EndIf
    If traceMatch && armorClass > 0
        Trace("classified | armor=" + GetArmorName(targetArmor) + " | class=" + GetClassLabel(armorClass) + " | source=" + source)
    EndIf
    Return armorClass
EndFunction

Bool Function IsArtisanDwemerArmor(Armor targetArmor) Global
    If targetArmor == None
        Return False
    EndIf
    Return StorageUtil.FormListFind(None, GetDwemerArtisanKey(), targetArmor) >= 0
EndFunction

; Presentation is intentionally separate from class-4 mechanics. Only exact
; entries explicitly marked deviousSuit receive full-body restraint lore.
; Artisan and unprofiled future entries conservatively use attachment lore.
String Function GetDwemerPresentationProfile(Armor targetArmor) Global
    If targetArmor == None
        Return "artisanAttachment"
    EndIf
    If IsArtisanDwemerArmor(targetArmor)
        Return "artisanAttachment"
    EndIf
    String[] entries = JsonUtil.PathStringElements(GetConfigFile(), ".dwemer_forms")
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 2 && parts[0] != "" && parts[1] != ""
            Armor configuredArmor = Game.GetFormFromFile(parts[1] as Int, parts[0]) as Armor
            If configuredArmor != None && configuredArmor == targetArmor
                If parts.Length >= 4 && parts[3] == "deviousSuit"
                    Return "deviousSuit"
                EndIf
                Return "artisanAttachment"
            EndIf
        EndIf
        index += 1
    EndWhile
    Return "artisanAttachment"
EndFunction

Bool Function RegisterArtisanDwemerArmor(Armor targetArmor) Global
    If targetArmor == None
        Trace("artisan register rejected | missing armor")
        Return False
    EndIf
    String armorName = GetArmorName(targetArmor)
    If ClassifyCustomArmor(targetArmor) > 0
        Trace("artisan register skipped | armor already has a custom class | " + armorName)
        Return False
    EndIf
    If StorageUtil.FormListAdd(None, GetDwemerArtisanKey(), targetArmor, False) < 0
        Alarm("artisan exact-form register failed | " + armorName)
        Return False
    EndIf
    If !IsArtisanDwemerArmor(targetArmor) || ClassifyCustomArmor(targetArmor) != 4
        Alarm("artisan register saved but Dwemer classification verification failed | " + armorName)
        Return False
    EndIf
    Trace("artisan Dwemer attachment registered | armor=" + armorName)
    Return True
EndFunction

Bool Function UnregisterArtisanDwemerArmor(Armor targetArmor) Global
    If targetArmor == None
        Trace("artisan unregister rejected | missing armor")
        Return False
    EndIf
    String armorName = targetArmor.GetName()
    If !IsArtisanDwemerArmor(targetArmor)
        Trace("artisan unregister skipped | attachment not found | " + armorName)
        Return False
    EndIf
    If StorageUtil.FormListRemove(None, GetDwemerArtisanKey(), targetArmor, True) <= 0
        Alarm("artisan exact-form unregister failed | " + armorName)
        Return False
    EndIf
    If IsArtisanDwemerArmor(targetArmor)
        Alarm("artisan unregister saved but attachment remains registered | " + armorName)
        Return False
    EndIf
    Trace("artisan Dwemer attachment unregistered | armor=" + armorName)
    Return True
EndFunction

Int Function MatchExactClass(Armor targetArmor, Int armorClass) Global
    String keyName = GetFormKey(armorClass)
    If keyName == ""
        Return 0
    EndIf
    String[] entries = JsonUtil.PathStringElements(GetConfigFile(), "." + keyName)
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 2 && parts[0] != "" && parts[1] != ""
            Armor configuredArmor = Game.GetFormFromFile(parts[1] as Int, parts[0]) as Armor
            If configuredArmor != None && configuredArmor == targetArmor
                Return armorClass
            EndIf
        EndIf
        index += 1
    EndWhile
    Return 0
EndFunction

Int Function MatchNameClass(Armor targetArmor, Int armorClass) Global
    String armorName = targetArmor.GetName()
    If armorName == "" || armorName == "Empty" || armorName == "empty"
        Return 0
    EndIf
    String keyName = GetNameKey(armorClass)
    String[] entries = JsonUtil.PathStringElements(GetConfigFile(), "." + keyName)
    If entries.Find(armorName) >= 0
        Return armorClass
    EndIf
    Return 0
EndFunction

; Called once during controller initialization. It reports malformed or missing
; optional entries without making an absent compatibility mod an error.
Function AuditRegistry() Global
    If !JsonUtil.JsonExists(GetConfigFile()) || !JsonUtil.IsGood(GetConfigFile())
        Alarm("registry JSON is missing or malformed")
        Return
    EndIf
    ; Builds before 0.5.1 stored blacksmith attachments by display name. A
    ; generic name such as "clothes" consequently classified every matching
    ; outfit in a loaded town. Remove that unsafe legacy state once; new
    ; attachments live as exact save-persistent Form references instead.
    If JsonUtil.GetIntValue(GetConfigFile(), "artisan_exact_form_migration", 0) == 0
        JsonUtil.StringListClear(GetConfigFile(), "dwemer_artisan_names")
        JsonUtil.SetIntValue(GetConfigFile(), "artisan_exact_form_migration", 1)
        If !JsonUtil.Save(GetConfigFile(), False)
            Alarm("legacy artisan-name migration could not be saved")
        Else
            Trace("legacy artisan-name registry cleared; exact-form storage active")
        EndIf
    EndIf
    Int armorClass = 1
    While armorClass <= 4
        String keyName = GetFormKey(armorClass)
        String[] entries = JsonUtil.PathStringElements(GetConfigFile(), "." + keyName)
        Int index = 0
        While index < entries.Length
            String[] parts = StringUtil.Split(entries[index], "|")
            If parts.Length < 2 || parts[0] == "" || parts[1] == ""
                Alarm("malformed " + keyName + " entry at index " + index + " | " + entries[index])
            Else
                Form configuredForm = Game.GetFormFromFile(parts[1] as Int, parts[0])
                If configuredForm != None && (configuredForm as Armor) == None
                    Alarm("configured form is not Armor | " + entries[index])
                ElseIf configuredForm == None && Game.GetModByName(parts[0]) != 255
                    Alarm("configured armor could not resolve | " + entries[index])
                EndIf
            EndIf
            index += 1
        EndWhile
        armorClass += 1
    EndWhile
    Trace("registry audit complete")
EndFunction

; Reproduces MME_CheckForSpriggan only for JSON-only classifications. Original
; MME armor remains owned by MME and never enters this function.
Function HandleCustomArmorEquipped(Actor wearer, Armor equippedArmor) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If wearer == None || equippedArmor == None || milkController == None
        Return
    EndIf
    Int armorClass = ClassifyCustomArmor(equippedArmor, True)
    If armorClass == 0
        Return
    EndIf
    If MMEArmorScript.ClassifyOriginalArmor(milkController, equippedArmor) != 0
        Trace("equip ignored | original MME classification owns " + GetArmorName(equippedArmor))
        Return
    EndIf

    Trace("equip detected | actor=" + MMEArmorScript.GetActorName(wearer) + " | armor=" + GetArmorName(equippedArmor) + " | class=" + GetClassLabel(armorClass))
    ActorBase wearerBase = wearer.GetLeveledActorBase()
    If wearerBase == None || (wearerBase.GetSex() != 1 && !(wearerBase.GetSex() == 0 && milkController.MaleMaids))
        Trace("equip compatibility stopped | actor sex is not enabled by MME")
        Return
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(wearer, milkController)
        ; A registered armor is a base form, not a unique inventory instance.
        ; Never convert NPCs merely because they equip one: deliberate NPC
        ; conversion belongs to the public forced-conversion routes.
        If wearer != Game.GetPlayer()
            Trace("equip compatibility stopped | NPC equip cannot create Milk Maid | actor=" + MMEArmorScript.GetActorName(wearer) + " | armor=" + GetArmorName(equippedArmor))
            Return
        EndIf
        ; MilkQUEST reserves MilkMaid[0] for the player. AssignSlotMaid writes
        ; that unique slot directly and deliberately bypasses the NPC-only
        ; MME_FreeMaidSlots/Milklvl0fix capacity gate. Do not preflight the
        ; player through the NPC counter or a full NPC registry blocks a valid
        ; player conversion.
        Trace("Milk Maid assignment requested through dedicated player slot | actor=" + MMEArmorScript.GetActorName(wearer))
        milkController.AssignSlotMaid(wearer)
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(wearer, milkController)
        Trace("equip compatibility stopped | Milk Maid assignment unavailable")
        Return
    EndIf

    String armorName = GetArmorName(equippedArmor)
    If armorClass == 4
        ; Dwemer armor owns no Living/Parasite passive. Its dedicated system
        ; uses MME's normal Milk Maid registration and Lactacid authority only.
        If MME_Storage.getLactacidCurrent(wearer) < 1.0
            MME_Storage.setLactacidCurrent(wearer, 1.0)
            Trace("Dwemer Lactacid raised to 1 | actor=" + MMEArmorScript.GetActorName(wearer))
        EndIf
        If wearer == Game.GetPlayer()
            Debug.Notification(armorName + "'s kinky milking and teasing devices attach to your most intimate places")
        EndIf
        Trace("Dwemer equip compatibility complete | dedicated system owns reactions")
        Return
    ElseIf armorClass == 2 || armorClass == 3
        If wearer == Game.GetPlayer() && MME_Storage.getBreastRows(wearer) > 1 && wearer.GetWornForm(Armor.GetMaskForSlot(32)) == equippedArmor
            Debug.Notification(armorName + " attaches to your breasts, absorbing your additional breast rows")
            MME_Storage.setBreastRows(wearer, 1)
        EndIf
        If wearer == Game.GetPlayer()
            Debug.Notification(armorName + " attaches to your breasts")
        EndIf
        If milkController.MilkForSprigganPassive != None
            wearer.AddSpell(milkController.MilkForSprigganPassive, False)
            Trace("Living passive added | actor=" + MMEArmorScript.GetActorName(wearer))
        Else
            Alarm("MME MilkForSprigganPassive property is unavailable")
        EndIf
        If MME_Storage.getLactacidCurrent(wearer) < 1.0
            MME_Storage.setLactacidCurrent(wearer, 1.0)
            Trace("Lactacid raised to 1 | actor=" + MMEArmorScript.GetActorName(wearer))
        EndIf
    ElseIf wearer == Game.GetPlayer()
        Debug.Notification("The milking cups attach to your breasts, ready to milk you")
    EndIf
    Trace("equip compatibility effects complete")
EndFunction

Function HandleCustomArmorUnequipped(Actor wearer, Armor unequippedArmor) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If wearer == None || unequippedArmor == None || milkController == None
        Return
    EndIf
    Int armorClass = ClassifyCustomArmor(unequippedArmor, True)
    If armorClass == 0 || MMEArmorScript.ClassifyOriginalArmor(milkController, unequippedArmor) != 0
        Return
    EndIf
    Trace("unequip detected | actor=" + MMEArmorScript.GetActorName(wearer) + " | armor=" + GetArmorName(unequippedArmor) + " | class=" + GetClassLabel(armorClass))
    If armorClass == 4
        Trace("Dwemer removal complete | no Living/Parasite cleanup applied")
        Return
    ElseIf armorClass == 2 || armorClass == 3
        If wearer == Game.GetPlayer()
            Debug.Notification("You are free from " + GetArmorName(unequippedArmor))
        EndIf
        If !HasWornLivingArmor(wearer, milkController) && milkController.MilkForSprigganPassive != None
            wearer.RemoveSpell(milkController.MilkForSprigganPassive)
            Trace("Living passive removed | actor=" + MMEArmorScript.GetActorName(wearer))
        Else
            Trace("Living passive retained | another Living/Parasite armor remains worn")
        EndIf
    ElseIf wearer == Game.GetPlayer()
        Debug.Notification("The milking cups detach from your breasts")
    EndIf
    Trace("unequip compatibility cleanup complete")
EndFunction

Bool Function HasWornLivingArmor(Actor wearer, MilkQUEST milkController) Global
    Int slot = 30
    While slot <= 61
        Armor wornArmor = wearer.GetWornForm(Armor.GetMaskForSlot(slot)) as Armor
        If wornArmor != None
            Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "custom-unequip", wearer)
            If armorClass == 2 || armorClass == 3
                Return True
            EndIf
        EndIf
        slot += 1
    EndWhile
    Return False
EndFunction

Bool Function RegisterArmor(String pluginName, Int localFormID, Int armorClass) Global
    String keyName = GetFormKey(armorClass)
    If pluginName == "" || localFormID <= 0 || keyName == ""
        Trace("register rejected | invalid plugin, local FormID, or class")
        Return False
    EndIf
    Armor targetArmor = Game.GetFormFromFile(localFormID, pluginName) as Armor
    If targetArmor == None
        Trace("register rejected | armor did not resolve | " + pluginName + ":" + localFormID)
        Return False
    EndIf
    Int existingClass = FindExactClass(pluginName, localFormID)
    If existingClass > 0
        Trace("register skipped | exact entry already exists as " + GetClassLabel(existingClass) + " | " + pluginName + ":" + localFormID)
        Return False
    EndIf
    String entry = pluginName + "|" + localFormID + "|" + GetArmorName(targetArmor)
    If JsonUtil.StringListAdd(GetConfigFile(), keyName, entry, False) < 0 || !JsonUtil.Save(GetConfigFile(), False)
        Alarm("register failed while saving | " + entry)
        Return False
    EndIf
    Trace("register complete | class=" + GetClassLabel(armorClass) + " | " + entry)
    Return True
EndFunction

Int Function FindExactClass(String pluginName, Int localFormID) Global
    Int armorClass = 1
    While armorClass <= 4
        If FindExactEntry(pluginName, localFormID, armorClass) != ""
            Return armorClass
        EndIf
        armorClass += 1
    EndWhile
    Return 0
EndFunction

Bool Function UnregisterArmor(String pluginName, Int localFormID, Int armorClass) Global
    String keyName = GetFormKey(armorClass)
    If pluginName == "" || localFormID <= 0 || keyName == ""
        Trace("unregister rejected | invalid plugin, local FormID, or class")
        Return False
    EndIf
    String entry = FindExactEntry(pluginName, localFormID, armorClass)
    If entry == ""
        Trace("unregister skipped | entry not found | " + pluginName + ":" + localFormID)
        Return False
    EndIf
    If JsonUtil.StringListRemove(GetConfigFile(), keyName, entry, True) <= 0 || !JsonUtil.Save(GetConfigFile(), False)
        Alarm("unregister failed while saving | " + entry)
        Return False
    EndIf
    Trace("unregister complete | class=" + GetClassLabel(armorClass) + " | " + entry)
    Return True
EndFunction

String Function FindExactEntry(String pluginName, Int localFormID, Int armorClass) Global
    String keyName = GetFormKey(armorClass)
    String[] entries = JsonUtil.PathStringElements(GetConfigFile(), "." + keyName)
    Int index = 0
    While index < entries.Length
        String[] parts = StringUtil.Split(entries[index], "|")
        If parts.Length >= 2 && parts[0] == pluginName && (parts[1] as Int) == localFormID
            Return entries[index]
        EndIf
        index += 1
    EndWhile
    Return ""
EndFunction

Bool Function RegisterArmorName(String armorName, Int armorClass) Global
    String keyName = GetNameKey(armorClass)
    If armorName == "" || armorName == "Empty" || keyName == ""
        Trace("name register rejected | invalid name or class")
        Return False
    EndIf
    Int existingClass = FindNameClass(armorName)
    If existingClass > 0
        Trace("name register skipped | entry already exists as " + GetClassLabel(existingClass) + " | " + armorName)
        Return False
    EndIf
    If JsonUtil.StringListAdd(GetConfigFile(), keyName, armorName, False) < 0 || !JsonUtil.Save(GetConfigFile(), False)
        Alarm("name register failed while saving | " + armorName)
        Return False
    EndIf
    Trace("name register complete | class=" + GetClassLabel(armorClass) + " | " + armorName)
    Return True
EndFunction

Int Function FindNameClass(String armorName) Global
    Int armorClass = 1
    While armorClass <= 4
        If JsonUtil.StringListFind(GetConfigFile(), GetNameKey(armorClass), armorName) >= 0
            Return armorClass
        EndIf
        armorClass += 1
    EndWhile
    Return 0
EndFunction

Bool Function UnregisterArmorName(String armorName, Int armorClass) Global
    String keyName = GetNameKey(armorClass)
    If armorName == "" || keyName == ""
        Trace("name unregister rejected | invalid name or class")
        Return False
    EndIf
    If JsonUtil.StringListRemove(GetConfigFile(), keyName, armorName, True) <= 0
        Trace("name unregister skipped | entry not found | " + armorName)
        Return False
    EndIf
    If !JsonUtil.Save(GetConfigFile(), False)
        Alarm("name unregister failed while saving | " + armorName)
        Return False
    EndIf
    Trace("name unregister complete | class=" + GetClassLabel(armorClass) + " | " + armorName)
    Return True
EndFunction
