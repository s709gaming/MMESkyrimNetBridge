Scriptname MMEServiceArmorReminder Hidden

; Read-only, event-driven armor reminder used when the player opens dialogue
; with one of the three MME armor-service professions. The established
; controller owns menu-session suppression; this utility owns only eligibility,
; live armor classification, wording, and presentation.

String Function GetConfigFile() Global
    Return "/MMEAlerts/ArmorCheckReminders"
EndFunction

Bool Function TryShow(Actor speaker) Global
    If speaker == None || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorCheckReminder", 1) != 1
        Return False
    EndIf

    String serviceRole = ResolveServiceRole(speaker)
    If serviceRole == ""
        ; Ordinary dialogue with a non-service NPC is expected and stays quiet.
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If milkController == None || playerActor == None
        ReportStop("controller/player unavailable", speaker, serviceRole)
        Return False
    EndIf
    If milkController.MilkMaidFaction == None || milkController.MilkSlaveFaction == None
        ReportStop("MME Maid/Slave factions unavailable", speaker, serviceRole)
        Return False
    EndIf
    If !playerActor.IsInFaction(milkController.MilkMaidFaction) || playerActor.IsInFaction(milkController.MilkSlaveFaction)
        ; These are normal service exclusions, not implementation failures.
        Return False
    EndIf

    String configFile = GetConfigFile()
    If !JsonUtil.JsonExists(configFile) || !JsonUtil.IsGood(configFile)
        ReportStop("ArmorCheckReminders.json missing or invalid", speaker, serviceRole)
        Return False
    EndIf

    Armor wornArmor = playerActor.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    Int armorClass = 0
    String poolName = "noArmor"
    If wornArmor != None
        armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "service-reminder", playerActor)
        ; Tentacle/Spriggan and the three configured arrays receive a concrete
        ; class above. Other canonical/special MME protections (for example an
        ; unmapped native breast form) must not fall through as ordinary armor.
        If armorClass == 0 && MMEArmorScript.GetMMEArmorProtectionReason(milkController, wornArmor, "service-reminder", playerActor) != ""
            ReportStop("protected MME armor has no reminder category: " + wornArmor.GetName(), speaker, serviceRole)
            Return False
        EndIf
        If armorClass == 1
            poolName = "milkingArmor"
        ElseIf armorClass == 2
            poolName = "livingArmor"
        ElseIf armorClass == 3
            poolName = "parasiteArmor"
        Else
            poolName = "regularArmor"
        EndIf
    EndIf

    String[] observations = JsonUtil.PathStringElements(configFile, "." + poolName)
    String[] reactions = JsonUtil.PathStringElements(configFile, ".reaction")
    If observations == None || observations.Length == 0 || reactions == None || reactions.Length == 0
        ReportStop("wording pool missing or empty: " + poolName, speaker, serviceRole)
        Return False
    EndIf

    String observation = observations[Utility.RandomInt(0, observations.Length - 1)]
    String reaction = reactions[Utility.RandomInt(0, reactions.Length - 1)]
    If observation == "" || reaction == ""
        ReportStop("blank wording entry: " + poolName, speaker, serviceRole)
        Return False
    EndIf

    String actorName = ResolveActorName(speaker)
    String reminderText = actorName + " " + observation + " " + reaction
    ; The HUD measures pixels rather than characters, but 80 characters is a
    ; conservative guard for common Skyrim/SkyUI notification layouts.
    If StringUtil.GetLength(reminderText) > 80
        reminderText = actorName + " " + GetCompactObservation(poolName) + " and nods."
    EndIf
    If StringUtil.GetLength(reminderText) > 80
        reminderText = "The vendor " + GetCompactObservation(poolName) + " and nods."
    EndIf

    Debug.Notification(reminderText)
    String armorName = "<none>"
    If wornArmor != None
        armorName = wornArmor.GetName()
    EndIf
    Debug.Trace("[MME Extensions Armor Reminder] PASS | role=" + serviceRole + " | speaker=" + actorName + " | armor=" + armorName + " | class=" + armorClass + " | pool=" + poolName + " | notification=" + reminderText)
    Return True
EndFunction

; Uses the exact job + merchant gates already required by the three working
; armor services. A deterministic priority prevents double reminders from an
; unusual NPC carrying more than one job faction.
String Function ResolveServiceRole(Actor speaker) Global
    If speaker == None
        Return ""
    EndIf
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If merchantFaction == None
        Debug.Trace("[MME Extensions Armor Reminder] STOP | Skyrim merchant faction unavailable", 2)
        Return ""
    EndIf
    If !speaker.IsInFaction(merchantFaction)
        Return ""
    EndIf

    Faction blacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    Faction apothecaryFaction = Game.GetFormFromFile(0x05091C, "Skyrim.esm") as Faction
    Faction courtWizardFaction = Game.GetFormFromFile(0x05091E, "Skyrim.esm") as Faction
    If blacksmithFaction == None || apothecaryFaction == None || courtWizardFaction == None
        Debug.Trace("[MME Extensions Armor Reminder] STOP | Skyrim service faction unavailable", 2)
        Return ""
    EndIf
    If speaker.IsInFaction(blacksmithFaction)
        Return "Blacksmith"
    ElseIf speaker.IsInFaction(apothecaryFaction)
        Return "Alchemist"
    ElseIf speaker.IsInFaction(courtWizardFaction)
        Return "Mage"
    EndIf
    Return ""
EndFunction

String Function ResolveActorName(Actor speaker) Global
    If speaker == None
        Return "The vendor"
    EndIf
    String actorName = speaker.GetDisplayName()
    If actorName == ""
        ActorBase baseActor = speaker.GetLeveledActorBase()
        If baseActor != None
            actorName = baseActor.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "The vendor"
    EndIf
    Return actorName
EndFunction

String Function GetCompactObservation(String poolName) Global
    If poolName == "noArmor"
        Return "notices you're bare"
    ElseIf poolName == "regularArmor"
        Return "eyes your armor"
    ElseIf poolName == "milkingArmor"
        Return "notices your milking gear"
    ElseIf poolName == "livingArmor"
        Return "watches your living armor stir"
    ElseIf poolName == "parasiteArmor"
        Return "notices the parasite"
    EndIf
    Return "studies your equipment"
EndFunction

Function ReportStop(String reason, Actor speaker, String serviceRole) Global
    Debug.Trace("[MME Extensions Armor Reminder] STOP | role=" + serviceRole + " | speaker=" + ResolveActorName(speaker) + " | reason=" + reason, 2)
EndFunction
