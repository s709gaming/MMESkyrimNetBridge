Scriptname MMEAlertsMCM extends SKI_ConfigBase

String SettingsFile = "/MMEAlerts/Settings"
Int soundsOption
Int volumeOption
Int capacityOption
Int pollingOption
Int notificationOption
Int pollingIntervalOption
Int debugMilkReportOption
Int debugMilkingEventsOption
Int milkmaidLevelBonusOption
Int flatMilkBonusOption
Int addMilkDebugOption
Int lactacidMultiplierOption
Int skyrimNetDiagnosticOption
Int drinkMoansOption
Int fullnessMoansOption
Int milkingMoansOption
Int skyrimNetStatusOption
Int arousalStatusOption
Int milkDrinkArousalOption
Int milkDrinkArousalAmountOption
Int arousalDiagnosticOption
Int dialogueDiagnosticOption
Int npcDrinkAnimationOption

; SkyUI uses this version to run settings migrations on existing saves.
Int Function GetVersion()
    Return 34
EndFunction

Function SetPageNames()
    Pages = new String[5]
    Pages[0] = "General"
    Pages[1] = "Milk Drinking"
    ; Build this at runtime to prevent Papyrus's case-insensitive string table
    ; from reusing the lowercase arousal token found in integration symbols.
    Pages[2] = "A" + "rousal "
    Pages[3] = "Skyrim.Net"
    Pages[4] = "Debug"
EndFunction

; Creates the MCM pages and initializes controllers on first registration.
Event OnConfigInit()
    ModName = "MME Extensions"
    SetPageNames()
    EnsureDefaults()
    ApplyDevelopmentSetup()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).InitializeController()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).UpdateDebugLoop()
EndEvent

; Reapplies page metadata and safe migrations after an MCM version increase.
Event OnVersionUpdate(Int newVersion)
    ModName = "MME Extensions"
    SetPageNames()
    RefreshRegisteredName()
    EnsureDefaults()
    ApplyDevelopmentSetup()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).InitializeController()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).UpdateDebugLoop()
EndEvent

; Refreshes exact capitalization whenever SkyUI opens this menu.
Event OnConfigOpen()
    ModName = "MME Extensions"
    SetPageNames()
EndEvent

; SkyUI caches the MCM name at first registration, so changing ModName alone
; does not rename an existing menu. Re-register this menu in place on upgrade.
Function RefreshRegisteredName()
    SKI_ConfigManager manager = Quest.GetQuest("SKI_ConfigManagerInstance") as SKI_ConfigManager
    If manager != None
        manager.UnregisterMod(Self)
        manager.RegisterMod(Self, ModName)
    EndIf
EndFunction

Function ApplyDevelopmentSetup()
    MMEAlertsQuickTest quickTest = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsQuickTest
    If quickTest != None
        quickTest.ApplyTestSetup()
    EndIf
EndFunction

; Seeds new settings and runs one-time migrations without overriding later choices.
Function EnsureDefaults()
    If !JsonUtil.IsPendingSave(SettingsFile) && JsonUtil.GetIntValue(SettingsFile, "initialized", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "initialized", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableReactionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingMoans", 1)
        JsonUtil.SetFloatValue(SettingsFile, "reactionSoundVolume", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityReactions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", 1)
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", 5.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetFloatValue(SettingsFile, "flatMilkBonus", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 5.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Applies quieter release defaults once without overriding later player choices.
    If JsonUtil.GetIntValue(SettingsFile, "quietDiagnosticsMigration32", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "quietDiagnosticsMigration32", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "npcDrinkAnimationMigration31", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "npcDrinkAnimationMigration31", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "dialogueDiagnosticMigration30", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "dialogueDiagnosticMigration30", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "arousalIntegrationMigration27", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 5.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "arousalIntegrationMigration27", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkBoostMigration16", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetFloatValue(SettingsFile, "flatMilkBonus", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "milkBoostMigration16", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "addMilkDebugMigration17", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "addMilkDebugMigration17", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Repairs saves where the intended default-on level bonus was left disabled.
    If JsonUtil.GetIntValue(SettingsFile, "mmeLevelBonusRepair20", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetIntValue(SettingsFile, "mmeLevelBonusRepair20", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "lactacidMultiplierMigration22", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0)
        JsonUtil.SetIntValue(SettingsFile, "lactacidMultiplierMigration22", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "skyrimNetDiagnosticMigration23", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "skyrimNetDiagnosticMigration23", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkDiagnosticsDefaultOff24", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkDiagnosticsDefaultOff24", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "modularMoansMigration25", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "modularMoansMigration25", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Disable the retired repeating diagnostic on existing saves as well.
    If JsonUtil.GetIntValue(SettingsFile, "disableDrinkDiagnosticsMigration15", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "disableDrinkDiagnosticsMigration15", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkingEventDebugMigration14", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "milkingEventDebugMigration14", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "drinkTrackerMigration9", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "drinkTrackerMigration9", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "drinkTrackerRepair11", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "drinkTrackerRepair11", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "drinkDiagnosticsMigration12", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "drinkDiagnosticsMigration12", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; One-time migration for existing saves. Later player choices persist.
    If JsonUtil.GetIntValue(SettingsFile, "capacityPollingMigration7", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugSoundLoop", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugSoundTest", 0)
        JsonUtil.SetIntValue(SettingsFile, "capacityPollingMigration7", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "debugPageMigration8", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 1)
        If JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 0.0) < 3.0
            JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", 5.0)
        EndIf
        JsonUtil.SetIntValue(SettingsFile, "debugPageMigration8", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
EndFunction

; Renders the selected SkyUI page from persisted JContainers settings.
Event OnPageReset(String page)
    EnsureDefaults()
    soundsOption = -1
    volumeOption = -1
    capacityOption = -1
    pollingOption = -1
    pollingIntervalOption = -1
    notificationOption = -1
    debugMilkReportOption = -1
    debugMilkingEventsOption = -1
    milkmaidLevelBonusOption = -1
    flatMilkBonusOption = -1
    addMilkDebugOption = -1
    lactacidMultiplierOption = -1
    skyrimNetDiagnosticOption = -1
    drinkMoansOption = -1
    fullnessMoansOption = -1
    milkingMoansOption = -1
    skyrimNetStatusOption = -1
    arousalStatusOption = -1
    milkDrinkArousalOption = -1
    milkDrinkArousalAmountOption = -1
    arousalDiagnosticOption = -1
    dialogueDiagnosticOption = -1
    npcDrinkAnimationOption = -1
    SetCursorFillMode(TOP_TO_BOTTOM)
    If page == "Milk Drinking"
        AddHeaderOption("Milk Gain Per Drink")
        milkmaidLevelBonusOption = AddToggleOption("MME Level Bonus", JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1) == 1)
        flatMilkBonusOption = AddSliderOption("Flat Milk Bonus", JsonUtil.GetFloatValue(SettingsFile, "flatMilkBonus", 4.0), "+{1} milk")
        lactacidMultiplierOption = AddSliderOption("Lactacid Multiplier", JsonUtil.GetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0), "x{1}")
        AddHeaderOption("NPC Dialogue")
        npcDrinkAnimationOption = AddToggleOption("NPC Milk-Drink Animation", JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0) == 1)
        Return
    EndIf
    If page == "A" + "rousal "
        Bool arousalAvailable = MMEArousalBridge.IsAvailable()
        Int arousalFlags = OPTION_FLAG_DISABLED
        If arousalAvailable
            arousalFlags = OPTION_FLAG_NONE
        EndIf
        AddHeaderOption("Integration Status")
        arousalStatusOption = AddToggleOption("SexLab Arousal Detected", arousalAvailable, OPTION_FLAG_DISABLED)
        AddHeaderOption("Milk Drinking")
        milkDrinkArousalOption = AddToggleOption("Milk Raises Arousal", JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkArousal", 1) == 1, arousalFlags)
        If JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkArousal", 1) != 1
            arousalFlags = OPTION_FLAG_DISABLED
        EndIf
        milkDrinkArousalAmountOption = AddSliderOption("Arousal Per Milk", JsonUtil.GetFloatValue(SettingsFile, "milkDrinkArousal", 5.0), "+{0}", arousalFlags)
        Return
    EndIf
    If page == "Skyrim.Net"
        AddHeaderOption("Integration Status")
        skyrimNetStatusOption = AddToggleOption("Skyrim.Net Detected", MMEAlertsSkyrimNet.IsAvailable(), OPTION_FLAG_DISABLED)
        AddHeaderOption("Event Tracking")
        Return
    EndIf
    If page == "Debug"
        AddHeaderOption("Development Diagnostics")
        debugMilkingEventsOption = AddToggleOption("Report Milking Start/End", JsonUtil.GetIntValue(SettingsFile, "enableMilkingEventDebug", 1) == 1)
        debugMilkReportOption = AddToggleOption("Milk Status Every 5 Seconds", JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1)
        addMilkDebugOption = AddToggleOption("Milk Drinking Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1)
        AddHeaderOption("Skyrim.Net Diagnostics")
        skyrimNetDiagnosticOption = AddToggleOption("Skyrim.Net Diagnostic", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 1) == 1)
        AddHeaderOption("Arousal Diagnostics")
        arousalDiagnosticOption = AddToggleOption("Milk Arousal Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableArousalDiagnostic", 0) == 1)
        AddHeaderOption("Dialogue Diagnostics")
        dialogueDiagnosticOption = AddToggleOption("NPC Dialogue Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0) == 1)
        Return
    EndIf
    AddHeaderOption("Sounds")
    soundsOption = AddToggleOption("Enable Moaning Sounds", JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) == 1)
    drinkMoansOption = AddToggleOption("Drink Milk Moans", JsonUtil.GetIntValue(SettingsFile, "enableDrinkMoans", 1) == 1)
    fullnessMoansOption = AddToggleOption("Milk Fullness Moans", JsonUtil.GetIntValue(SettingsFile, "enableFullnessMoans", 1) == 1)
    milkingMoansOption = AddToggleOption("Milking Start/End Moans", JsonUtil.GetIntValue(SettingsFile, "enableMilkingMoans", 1) == 1)
    volumeOption = AddSliderOption("Moaning Sound Volume", JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0), "{0}%")
    AddHeaderOption("Capacity Tracker")
    capacityOption = AddToggleOption("Enable 50% Capacity Reactions", JsonUtil.GetIntValue(SettingsFile, "enableCapacityReactions", 1) == 1)
    pollingOption = AddToggleOption("Enable Capacity Polling", JsonUtil.GetIntValue(SettingsFile, "enableCapacityPolling", 1) == 1)
    pollingIntervalOption = AddSliderOption("Capacity Polling Interval", JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 5.0), "{0} seconds")
    notificationOption = AddToggleOption("Enable Capacity Notifications", JsonUtil.GetIntValue(SettingsFile, "enableCapacityNotifications", 1) == 1)
EndEvent

; Gives every visible setting a short explanation for players and screen readers.
Event OnOptionHighlight(Int option)
    If option == soundsOption
        SetInfoText("Play reaction sounds for milking and milk drinking.")
    ElseIf option == volumeOption
        SetInfoText("Set the reaction sound volume.")
    ElseIf option == drinkMoansOption
        SetInfoText("Play a moan when the player drinks recognized milk.")
    ElseIf option == fullnessMoansOption
        SetInfoText("Play moans when a Milkmaid crosses half or full capacity.")
    ElseIf option == milkingMoansOption
        SetInfoText("Play moans when milking starts and ends.")
    ElseIf option == capacityOption
        SetInfoText("React when a Milkmaid reaches half capacity.")
    ElseIf option == pollingOption
        SetInfoText("Check nearby Milkmaid capacity on a timer.")
    ElseIf option == pollingIntervalOption
        SetInfoText("Set seconds between capacity checks.")
    ElseIf option == notificationOption
        SetInfoText("Show capacity reaction notifications.")
    ElseIf option == milkmaidLevelBonusOption
        SetInfoText("Add MME Milkmaid Level divided by 2 to every recognized milk drink.")
    ElseIf option == flatMilkBonusOption
        SetInfoText("Add this much milk per MME or regular milk drink.")
    ElseIf option == lactacidMultiplierOption
        SetInfoText("Multiply Lactacid's Flat Bonus from 0 to 2. MME Level Bonus is separate.")
    ElseIf option == npcDrinkAnimationOption
        SetInfoText("Play a five-second reaction animation after a Milkmaid drinks through dialogue.")
    ElseIf option == debugMilkingEventsOption
        SetInfoText("Report each detected milking start and end.")
    ElseIf option == debugMilkReportOption
        SetInfoText("Report nearby Milkmaid capacity every five seconds.")
    ElseIf option == addMilkDebugOption
        SetInfoText("Report drink detection, sound, bonus math, and MME add results.")
    ElseIf option == skyrimNetDiagnosticOption
        SetInfoText("Report SkyrimNet version, player UUID, event text, and API result.")
    ElseIf option == skyrimNetStatusOption
        SetInfoText("Read-only. Enabled when SkyrimNet.esp is active in the load order.")
    ElseIf option == arousalStatusOption
        SetInfoText("Read-only. Enabled when SexLabAroused.esm is active.")
    ElseIf option == milkDrinkArousalOption
        SetInfoText("Raise player arousal after drinking recognized milk.")
    ElseIf option == milkDrinkArousalAmountOption
        SetInfoText("Set arousal added per recognized milk drink.")
    ElseIf option == arousalDiagnosticOption
        SetInfoText("Report actor, milk, amount, detection, and event failures.")
    ElseIf option == dialogueDiagnosticOption
        SetInfoText("Report dialogue target detection and MME Milkmaid validation.")
    EndIf
EndEvent

; Persists toggle changes and refreshes only controllers affected by that option.
Event OnOptionSelect(Int option)
    If option == soundsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableReactionSounds", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == drinkMoansOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDrinkMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkMoans", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == fullnessMoansOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableFullnessMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessMoans", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkingMoansOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkingMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingMoans", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == capacityOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableCapacityReactions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityReactions", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == pollingOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableCapacityPolling", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", value)
        SetToggleOptionValue(option, value == 1)
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
    ElseIf option == notificationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableCapacityNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityNotifications", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == debugMilkReportOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", value)
        SetToggleOptionValue(option, value == 1)
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).UpdateDebugLoop()
    ElseIf option == debugMilkingEventsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkingEventDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkmaidLevelBonusOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == addMilkDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkDrinkArousalOption && MMEArousalBridge.IsAvailable()
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == arousalDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == dialogueDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcDrinkAnimationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", value)
        SetToggleOptionValue(option, value == 1)
    EndIf
    JsonUtil.Save(SettingsFile, False)
EndEvent

; Configures the shared sound-volume and capacity-interval slider dialogs.
Event OnOptionSliderOpen(Int option)
    If option == volumeOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == pollingIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 5.0))
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(3.0, 30.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == flatMilkBonusOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "flatMilkBonus", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == lactacidMultiplierOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0))
        SetSliderDialogDefaultValue(2.0)
        SetSliderDialogRange(0.0, 2.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == milkDrinkArousalAmountOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkDrinkArousal", 5.0))
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    EndIf
EndEvent

; Saves accepted slider values and reschedules polling when its interval changes.
Event OnOptionSliderAccept(Int option, Float value)
    If option == volumeOption
        JsonUtil.SetFloatValue(SettingsFile, "reactionSoundVolume", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == pollingIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
    ElseIf option == flatMilkBonusOption
        JsonUtil.SetFloatValue(SettingsFile, "flatMilkBonus", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+{1} milk")
    ElseIf option == lactacidMultiplierOption
        JsonUtil.SetFloatValue(SettingsFile, "lactacidFlatMultiplier", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "x{1}")
    ElseIf option == milkDrinkArousalAmountOption
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+{0}")
    EndIf
EndEvent
