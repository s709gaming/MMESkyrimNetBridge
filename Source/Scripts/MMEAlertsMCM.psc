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
Int skyrimNetDrinkDiagnosticOption
Int skyrimNetMilkingDiagnosticOption
Int skyrimNetCreationDiagnosticOption
Int skyrimNetStatusDiagnosticOption
Int skyrimNetPromptDiagnosticOption
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
Int npcMilkEffectsOption
Int npcMilkConsumptionDiagnosticOption
Int lifecycleDiagnosticOption
Int milkmaidCreationDiagnosticOption
Int nativeScanDiagnosticOption
Int skyrimNetMilkStatusesOption
Int skyrimNetMilkDrinksOption
Int skyrimNetMilkingEventsOption
Int skyrimNetMilkmaidCreatedOption
Int skyrimNetStatusIntervalOption
Int milkFullNarrationOption
Int milkFullNarrationCooldownOption
Int milkFullNarrationDiagnosticOption

; SkyUI uses this version to run settings migrations on existing saves.
Int Function GetVersion()
    Return 53
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
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetFloatValue(SettingsFile, "flatMilkBonus", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1)
        JsonUtil.SetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilking", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilk", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkFullNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 10.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "lifecycleDiagnosticMigration35", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "lifecycleDiagnosticMigration35", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkmaidCreationDiagnosticMigration39", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "milkmaidCreationDiagnosticMigration39", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "nativeScanDiagnosticMigration40", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNativeScanDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "nativeScanDiagnosticMigration40", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "nativeScanProductionMigration41", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "nativeScanProductionMigration41", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Test-build defaults for the first combined nearby-status verification.
    If JsonUtil.GetIntValue(SettingsFile, "skyrimNetMilkStatusesMigration42", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", 1)
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "skyrimNetMilkStatusesMigration42", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "splitSkyrimNetDiagnosticsMigration43", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "splitSkyrimNetDiagnosticsMigration43", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "skyrimNetTrackingTogglesMigration44", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1)
        JsonUtil.SetIntValue(SettingsFile, "skyrimNetTrackingTogglesMigration44", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "skyrimNetPromptDiagnosticMigration45", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "skyrimNetPromptDiagnosticMigration45", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "skyrimNetStatusTimerMigration46", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "skyrimNetStatusTimerMigration46", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "voiceMilkingTestMigration47", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilkingDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "voiceMilkingTestMigration47", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Voice action selection depends heavily on LLM context, so ship it opt-in only.
    If JsonUtil.GetIntValue(SettingsFile, "voiceMilkingExperimentalMigration48", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilking", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "voiceMilkingExperimentalMigration48", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkFullNarrationMigration49", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarration", 0)
        JsonUtil.SetFloatValue(SettingsFile, "milkFullNarrationCooldown", 300.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "milkFullNarrationMigration49", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Enable the reusable give-milk conversational action for its first test build.
    If JsonUtil.GetIntValue(SettingsFile, "voiceGiveMilkMigration50", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilk", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilkDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "voiceGiveMilkMigration50", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Release candidate defaults: working features on, diagnostics and retired voice actions off.
    If JsonUtil.GetIntValue(SettingsFile, "releaseDefaultsMigration51", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableReactionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityReactions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkFullNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilking", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilk", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "releaseDefaultsMigration51", 1)
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
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 10.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "arousalIntegrationMigration27", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkBoostMigration16", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetFloatValue(SettingsFile, "flatMilkBonus", 1.0)
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
    ; Must run after every historical test migration so none can restore noisy defaults.
    If JsonUtil.GetIntValue(SettingsFile, "releaseDiagnosticsFinalMigration52", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "releaseDiagnosticsFinalMigration52", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "npcMilkConsumptionMigration53", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "npcMilkConsumptionMigration53", 1)
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
    skyrimNetDrinkDiagnosticOption = -1
    skyrimNetMilkingDiagnosticOption = -1
    skyrimNetCreationDiagnosticOption = -1
    skyrimNetStatusDiagnosticOption = -1
    skyrimNetPromptDiagnosticOption = -1
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
    npcMilkEffectsOption = -1
    npcMilkConsumptionDiagnosticOption = -1
    lifecycleDiagnosticOption = -1
    milkmaidCreationDiagnosticOption = -1
    nativeScanDiagnosticOption = -1
    skyrimNetMilkStatusesOption = -1
    skyrimNetMilkDrinksOption = -1
    skyrimNetMilkingEventsOption = -1
    skyrimNetMilkmaidCreatedOption = -1
    skyrimNetStatusIntervalOption = -1
    milkFullNarrationOption = -1
    milkFullNarrationCooldownOption = -1
    milkFullNarrationDiagnosticOption = -1
    SetCursorFillMode(TOP_TO_BOTTOM)
    If page == "Milk Drinking"
        AddHeaderOption("Milk Gain Per Drink")
        milkmaidLevelBonusOption = AddToggleOption("MME Level Bonus", JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1) == 1)
        flatMilkBonusOption = AddSliderOption("Flat Milk Bonus", JsonUtil.GetFloatValue(SettingsFile, "flatMilkBonus", 1.0), "+{1} milk")
        lactacidMultiplierOption = AddSliderOption("Lactacid Multiplier", JsonUtil.GetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0), "x{1}")
        AddHeaderOption("NPC Milk Drinking")
        npcMilkEffectsOption = AddToggleOption("NPC Milk Effects", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkEffects", 1) == 1)
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
        milkDrinkArousalAmountOption = AddSliderOption("Arousal Per Milk", JsonUtil.GetFloatValue(SettingsFile, "milkDrinkArousal", 10.0), "+{0}", arousalFlags)
        Return
    EndIf
    If page == "Skyrim.Net"
        AddHeaderOption("Integration Status")
        skyrimNetStatusOption = AddToggleOption("Skyrim.Net Detected", MMEAlertsSkyrimNet.IsAvailable(), OPTION_FLAG_DISABLED)
        AddHeaderOption("Event Tracking")
        skyrimNetMilkDrinksOption = AddToggleOption("Track Milk Drinks", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", 1) == 1)
        skyrimNetMilkingEventsOption = AddToggleOption("Track Milking Start/End", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", 1) == 1)
        skyrimNetMilkmaidCreatedOption = AddToggleOption("Track New Milkmaids", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", 1) == 1)
        skyrimNetMilkStatusesOption = AddToggleOption("Track Nearby Milk Statuses", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1) == 1)
        skyrimNetStatusIntervalOption = AddSliderOption("Milk Status Interval", JsonUtil.GetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0), "{0} seconds")
        AddHeaderOption("AI Reactions")
        milkFullNarrationOption = AddToggleOption("Narrate Milk Full", JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarration", 1) == 1)
        Int narrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarration", 1) != 1
            narrationFlags = OPTION_FLAG_DISABLED
        EndIf
        milkFullNarrationCooldownOption = AddSliderOption("Milk Full Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "milkFullNarrationCooldown", 60.0), "{0} seconds", narrationFlags)
        Return
    EndIf
    If page == "Debug"
        AddHeaderOption("Development Diagnostics")
        lifecycleDiagnosticOption = AddToggleOption("Location Wait Load", JsonUtil.GetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0) == 1)
        milkmaidCreationDiagnosticOption = AddToggleOption("Milkmaid Creation Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 1) == 1)
        nativeScanDiagnosticOption = AddToggleOption("Native Actor Scan Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0) == 1)
        debugMilkingEventsOption = AddToggleOption("Report Milking Start/End", JsonUtil.GetIntValue(SettingsFile, "enableMilkingEventDebug", 1) == 1)
        debugMilkReportOption = AddToggleOption("Milk Status Every 5 Seconds", JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1)
        addMilkDebugOption = AddToggleOption("Milk Drinking Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1)
        npcMilkConsumptionDiagnosticOption = AddToggleOption("NPC Milk Consumption", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0) == 1)
        SetCursorPosition(1)
        AddHeaderOption("Skyrim.Net Diagnostics")
        skyrimNetDrinkDiagnosticOption = AddToggleOption("Milk Drink Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0) == 1)
        skyrimNetMilkingDiagnosticOption = AddToggleOption("Milking Start/End Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0) == 1)
        skyrimNetCreationDiagnosticOption = AddToggleOption("New Milkmaid Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0) == 1)
        skyrimNetStatusDiagnosticOption = AddToggleOption("Nearby Milk Status Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0) == 1)
        skyrimNetPromptDiagnosticOption = AddToggleOption("Milkmaid Bio Prompt", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 1) == 1)
        milkFullNarrationDiagnosticOption = AddToggleOption("Milk Full Narration Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0) == 1)
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
    pollingIntervalOption = AddSliderOption("Capacity Polling Interval", JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 15.0), "{0} seconds")
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
    ElseIf option == npcMilkEffectsOption
        SetInfoText("Apply milk, arousal, and moan effects when an MME Milkmaid consumes recognized milk.")
    ElseIf option == npcMilkConsumptionDiagnosticOption
        SetInfoText("Report native NPC milk detection, Milkmaid validation, duplicates, and applied effects.")
    ElseIf option == debugMilkingEventsOption
        SetInfoText("Report each detected milking start and end.")
    ElseIf option == lifecycleDiagnosticOption
        SetInfoText("Report native wait, sleep, location, and load events with nearby Milkmaid status.")
    ElseIf option == milkmaidCreationDiagnosticOption
        SetInfoText("Report MME creation effects and confirmed new Milkmaids.")
    ElseIf option == nativeScanDiagnosticOption
        SetInfoText("Report native nearby actor counts and scanner failures.")
    ElseIf option == debugMilkReportOption
        SetInfoText("Report nearby Milkmaid capacity every five seconds.")
    ElseIf option == addMilkDebugOption
        SetInfoText("Report drink detection, sound, bonus math, and MME add results.")
    ElseIf option == skyrimNetDrinkDiagnosticOption
        SetInfoText("Report SkyrimNet milk-drink payloads and API results.")
    ElseIf option == skyrimNetMilkingDiagnosticOption
        SetInfoText("Report SkyrimNet milking start/end payloads and API results.")
    ElseIf option == skyrimNetCreationDiagnosticOption
        SetInfoText("Report SkyrimNet new-Milkmaid schema, payload, and API results.")
    ElseIf option == skyrimNetStatusDiagnosticOption
        SetInfoText("Report SkyrimNet nearby Milkmaid status updates and failures.")
    ElseIf option == skyrimNetPromptDiagnosticOption
        SetInfoText("Report when SkyrimNet renders the optional Milkmaid bio prompt for an actor.")
    ElseIf option == skyrimNetStatusOption
        SetInfoText("Read-only. Enabled when SkyrimNet.esp is active in the load order.")
    ElseIf option == skyrimNetMilkStatusesOption
        SetInfoText("Send nearby Milkmaid states plus half-full and full milestones to Skyrim.Net.")
    ElseIf option == skyrimNetStatusIntervalOption
        SetInfoText("Set both the Skyrim.Net status refresh interval and event lifetime.")
    ElseIf option == milkFullNarrationOption
        SetInfoText("Ask Skyrim.Net for one immediate Milk Maid reaction at full capacity. Uses LLM tokens.")
    ElseIf option == milkFullNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using milk-full narrations.")
    ElseIf option == milkFullNarrationDiagnosticOption
        SetInfoText("Report milk-full narration triggers, cooldowns, payload calls, and API results.")
    ElseIf option == skyrimNetMilkDrinksOption
        SetInfoText("Send recognized player milk drinks to SkyrimNet.")
    ElseIf option == skyrimNetMilkingEventsOption
        SetInfoText("Send nearby Milkmaid milking start and end events to SkyrimNet.")
    ElseIf option == skyrimNetMilkmaidCreatedOption
        SetInfoText("Record confirmed new Milkmaids in SkyrimNet event history.")
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
    ElseIf option == milkFullNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == milkFullNarrationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == lifecycleDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableLifecycleDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkmaidCreationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == nativeScanDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNativeScanDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkmaidLevelBonusOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == addMilkDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcMilkEffectsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkEffects", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcMilkConsumptionDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetDrinkDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetMilkingDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetCreationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetStatusDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetPromptDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetMilkStatusesOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", value)
        SetToggleOptionValue(option, value == 1)
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
    ElseIf option == skyrimNetMilkDrinksOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetMilkingEventsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == skyrimNetMilkmaidCreatedOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", value)
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
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 15.0))
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(3.0, 30.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == skyrimNetStatusIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0))
        SetSliderDialogDefaultValue(15.0)
        SetSliderDialogRange(15.0, 300.0)
        SetSliderDialogInterval(15.0)
    ElseIf option == flatMilkBonusOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "flatMilkBonus", 1.0))
        SetSliderDialogDefaultValue(1.0)
        SetSliderDialogRange(0.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == lactacidMultiplierOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0))
        SetSliderDialogDefaultValue(2.0)
        SetSliderDialogRange(0.0, 2.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == milkDrinkArousalAmountOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkDrinkArousal", 10.0))
        SetSliderDialogDefaultValue(10.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == milkFullNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkFullNarrationCooldown", 60.0))
        SetSliderDialogDefaultValue(60.0)
        SetSliderDialogRange(10.0, 3600.0)
        SetSliderDialogInterval(10.0)
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
    ElseIf option == skyrimNetStatusIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "skyrimNetStatusInterval", value)
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
    ElseIf option == milkFullNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "milkFullNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    EndIf
EndEvent
