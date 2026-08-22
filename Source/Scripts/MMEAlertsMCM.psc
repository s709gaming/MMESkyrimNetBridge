Scriptname MMEAlertsMCM extends SKI_ConfigBase

; ---------------------------------------------------------------------------
; MCM settings schema and migrations
; ---------------------------------------------------------------------------
; JsonUtil is the persistent authority read by runtime scripts. This menu writes
; settings and asks only affected controllers to refresh; it must not implement
; gameplay. EnsureDefaults is append-only migration history for existing saves.

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
Int skyrimNetOStimTraceOption
Int skyrimNetSexLabTraceOption
Int drinkMoansOption
Int fullnessMoansOption
Int milkingMoansOption
Int skyrimNetStatusOption
Int arousalStatusOption
Int milkDrinkArousalOption
Int milkDrinkArousalAmountOption
Int dialogueDiagnosticOption
Int sexLabBreastfeedingDebugOption
Int npcDrinkAnimationOption
Int npcDrinkAnimationDurationOption
Int playerDrinkAnimationOption
Int playerDrinkAnimationDurationOption
Int milkDrinkAnimationDiagnosticOption
Int playerHalfFullSelfMilkAnimationOption
Int playerFullSelfMilkAnimationOption
Int playerFullnessSelfMilkAnimationDurationOption
Int npcHalfFullSelfMilkAnimationOption
Int npcFullSelfMilkAnimationOption
Int npcFullnessSelfMilkAnimationDurationOption
Int fullnessSelfMilkAnimationDiagnosticOption
Int npcMilkEffectsOption
Int npcMilkConsumptionDiagnosticOption
Int npcDrinkNotificationsOption
Int npcDrinkNotificationsDiagnosticOption
Int playerDrinkNotificationsOption
Int armorStrippingCheckDiagnosticOption
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
Int milkHalfFullNarrationOption
Int milkHalfFullNarrationCooldownOption
Int milkHalfFullNarrationDiagnosticOption
Int npcDrinkNarrationOption
Int npcDrinkNarrationCooldownOption
Int npcDrinkNarrationDiagnosticOption
Int playerDrinkNarrationOption
Int playerDrinkNarrationCooldownOption
Int playerDrinkNarrationDiagnosticOption
Int playerDrinkNarrationChanceOption
Int milkmaidCreatedNarrationOption
Int milkmaidCreatedNarrationCooldownOption
Int milkmaidCreatedNarrationDiagnosticOption
Int selfMilkingActionOption
Int pairedMilkingActionOption
Int selfMilkingActionDiagnosticOption
Int pairedMilkingActionDiagnosticOption
Int masterEnableOption
Int ostimBreastfeedingOption
Int ostimBreastfeedingDurationOption
Int ostimStatusOption
Int ostimDebugOption
Int playerMilkingArmorEquipMoanOption
Int playerMilkingArmorEquipAnimationOption
Int npcMilkingArmorEquipMoanOption
Int npcMilkingArmorEquipAnimationOption
Int playerLivingArmorEquipMoanOption
Int playerLivingArmorEquipAnimationOption
Int npcLivingArmorEquipMoanOption
Int npcLivingArmorEquipAnimationOption
Int playerLivingParasiteEquipMoanOption
Int playerLivingParasiteEquipAnimationOption
Int npcLivingParasiteEquipMoanOption
Int npcLivingParasiteEquipAnimationOption
Int nearbyMilkArmorStatusOption
Int playerMilkArmorEquipNarrationOption
Int npcMilkArmorEquipNarrationOption
Int playerMilkingArmorNarrationCooldownOption
Int npcMilkingArmorNarrationCooldownOption
Int armorDebugOption
Int blacksmithDebugOption
Int extensionsArmorStrippingOption
Int armorStripHeavyThresholdOption
Int armorStripLightThresholdOption
Int armorStripClothingThresholdOption
Int armorStripNotificationOption
Int armorStripMoanOption
Int armorStripNarrationOption
Int armorStripNarrationChanceOption
Int armorStripNarrationCooldownOption
Int armorStripNotificationDiagnosticOption
Int armorStripMoanDiagnosticOption
Int armorStripNarrationDiagnosticOption

; SkyUI uses this version to run settings migrations on existing saves.
Int Function GetVersion()
    Return 83
EndFunction

Function SetPageNames()
    Pages = new String[7]
    Pages[0] = "General"
    Pages[1] = "Milk Drinking"
    ; Build these page names at runtime so Papyrus's case-insensitive string
    ; table cannot reuse the lowercase "arousal"/"animations" tokens interned
    ; by integration scripts. The trailing spaces keep the built names distinct
    ; while rendering invisibly in the sidebar.
    Pages[2] = "A" + "nimations "
    Pages[3] = "A" + "rousal "
    Pages[4] = "Armor"
    Pages[5] = "Skyrim.Net"
    Pages[6] = "Debug"
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
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshOStimDialogueAvailability()
    EndIf
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
        quickTest.ScheduleTestSetup()
    EndIf
EndFunction

; Seeds new settings and runs one-time migrations without overriding later choices.
Function EnsureDefaults()
    ; New installations enter the first-version defaults block. Later blocks are
    ; individually guarded migrations so upgrades never overwrite user choices.
    If !JsonUtil.IsPendingSave(SettingsFile) && JsonUtil.GetIntValue(SettingsFile, "initialized", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "initialized", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMMEExtensions", 1)
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
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetOStimTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNearbyMilkArmorStatus", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "skyrimNetArmorMigration75", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBlacksmithDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "blacksmithServiceMigration77", 1)
        JsonUtil.SetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimBreastfeeding", MMEOStimBreastfeeding.IsOStimDetected() as Int)
        JsonUtil.SetFloatValue(SettingsFile, "ostimBreastfeedingDuration", 20.0)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "ostimBreastfeedingMigration70", 1)
        SetArmorReactionDefaults()
        JsonUtil.SetIntValue(SettingsFile, "milkingArmorMigration71", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilk", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkFullNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkHalfFullNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkHalfFullNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkHalfFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "npcDrinkNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 10.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.SetFloatValue(SettingsFile, "npcDrinkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkAnimation", 0)
        JsonUtil.SetFloatValue(SettingsFile, "playerDrinkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableHalfFullSelfMilkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullSelfMilkAnimation", 1)
        JsonUtil.SetFloatValue(SettingsFile, "fullnessSelfMilkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessSelfMilkAnimationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerHalfFullSelfMilkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerFullSelfMilkAnimation", 0)
        JsonUtil.SetFloatValue(SettingsFile, "playerFullnessSelfMilkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCHalfFullSelfMilkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCFullSelfMilkAnimation", 1)
        JsonUtil.SetFloatValue(SettingsFile, "npcFullnessSelfMilkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNotificationsDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNotificationsDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorOverflowDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyPercent", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightPercent", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripClothingPercent", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoan", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorStripNarrationChance", 100)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripNarrationCooldown", 300.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotificationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNarration", 0)
        JsonUtil.SetFloatValue(SettingsFile, "playerDrinkNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "playerDrinkNarrationChance", 25)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkmaidCreatedNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreatedNarrationDiagnostic", 0)
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
    If JsonUtil.GetIntValue(SettingsFile, "npcDrinkNarrationMigration54", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "npcDrinkNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "npcDrinkNarrationMigration54", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "masterEnableMigration55", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMMEExtensions", 1)
        JsonUtil.SetIntValue(SettingsFile, "masterEnableMigration55", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkHalfFullNarrationMigration58", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkHalfFullNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkHalfFullNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkHalfFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkHalfFullNarrationMigration58", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "npcDrinkNotificationsMigration59", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "npcDrinkNotificationsMigration59", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "npcDrinkNotificationsDiagnosticMigration60", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNotificationsDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "npcDrinkNotificationsDiagnosticMigration60", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "playerDrinkFeaturesMigration61", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNotificationsDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNarration", 0)
        JsonUtil.SetFloatValue(SettingsFile, "playerDrinkNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "playerDrinkFeaturesMigration61", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkingActionsMigration63", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkingActionsMigration63", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkmaidNarrationMigration64", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "playerDrinkNarrationChance", 25)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkmaidCreatedNarrationCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreatedNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkmaidNarrationMigration64", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "fullnessSelfMilkAnimationMigration65", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableHalfFullSelfMilkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullSelfMilkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessSelfMilkAnimationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "fullnessSelfMilkAnimationMigration65", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "animationDurationMigration66", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "npcDrinkAnimationDuration", 3.0)
        JsonUtil.SetFloatValue(SettingsFile, "fullnessSelfMilkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "animationDurationMigration66", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the separate player drink animation settings without touching the
    ; existing NPC animation choice or duration.
    If JsonUtil.GetIntValue(SettingsFile, "playerDrinkAnimationMigration67", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkAnimation", 0)
        JsonUtil.SetFloatValue(SettingsFile, "playerDrinkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "playerDrinkAnimationMigration67", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Splits fullness animations into Player and NPC policies. The previous
    ; shared values become the NPC policy, and the new Player policy starts off.
    If JsonUtil.GetIntValue(SettingsFile, "fullnessAnimationSplit68", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCHalfFullSelfMilkAnimation", JsonUtil.GetIntValue(SettingsFile, "enableHalfFullSelfMilkAnimation", 1))
        JsonUtil.SetIntValue(SettingsFile, "enableNPCFullSelfMilkAnimation", JsonUtil.GetIntValue(SettingsFile, "enableFullSelfMilkAnimation", 1))
        JsonUtil.SetFloatValue(SettingsFile, "npcFullnessSelfMilkAnimationDuration", JsonUtil.GetFloatValue(SettingsFile, "fullnessSelfMilkAnimationDuration", 3.0))
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerHalfFullSelfMilkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerFullSelfMilkAnimation", 0)
        JsonUtil.SetFloatValue(SettingsFile, "playerFullnessSelfMilkAnimationDuration", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "fullnessAnimationSplit68", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the optional post-drink armor stripping diagnostic without touching other settings.
    If JsonUtil.GetIntValue(SettingsFile, "armorOverflowDiagnosticMigration69", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorOverflowDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "armorOverflowDiagnosticMigration69", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; OStim remains optional and starts enabled only when its plugin is active.
    If JsonUtil.GetIntValue(SettingsFile, "ostimBreastfeedingMigration70", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableOStimBreastfeeding", MMEOStimBreastfeeding.IsOStimDetected() as Int)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "ostimBreastfeedingMigration70", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkingArmorMigration71", 0) == 0
        SetArmorReactionDefaults()
        JsonUtil.SetIntValue(SettingsFile, "milkingArmorMigration71", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "armorReactionMigration74", 0) == 0
        MigrateArmorReactionSettings()
        JsonUtil.SetIntValue(SettingsFile, "armorReactionMigration74", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "skyrimNetArmorMigration75", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNearbyMilkArmorStatus", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "skyrimNetArmorMigration75", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds diagnostics for the Blacksmith vendor-service transaction. Gameplay
    ; remains enabled with the MME Extensions master toggle; this controls only
    ; the short HUD checkpoints requested for testing.
    If JsonUtil.GetIntValue(SettingsFile, "blacksmithServiceMigration77", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBlacksmithDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "blacksmithServiceMigration77", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Dedicated OStim breastfeeding scenes suppress navigation, so their safe
    ; OStim-owned end condition has its own gameplay-independent duration.
    If JsonUtil.GetIntValue(SettingsFile, "ostimBreastfeedingDurationMigration78", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "ostimBreastfeedingDuration", 20.0)
        JsonUtil.SetIntValue(SettingsFile, "ostimBreastfeedingDurationMigration78", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Milk Drinking Diagnostics now owns the whole player drink transaction
    ; (milk math, arousal, and notification reporting). The two narrower toggles
    ; were removed; force their orphaned keys quiet so stale ON values cannot
    ; produce leftover output through any older code path.
    If JsonUtil.GetIntValue(SettingsFile, "milkDrinkDiagnosticsConsolidationMigration79", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNotificationsDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkDrinkDiagnosticsConsolidationMigration79", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Configurable armor stripping adds MCM fullness-percentage sliders and
    ; capacity-poll stripping for the player. Percent defaults start at 100.
    If JsonUtil.GetIntValue(SettingsFile, "armorStrippingFeatureMigration80", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyPercent", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightPercent", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripClothingPercent", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "armorStrippingFeatureMigration80", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Consolidate armor stripping diagnostics into one toggle and neutralize the
    ; temporary second diagnostic key for saves that already upgraded.
    If JsonUtil.GetIntValue(SettingsFile, "armorStrippingDiagnosticConsolidation81", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStrippingDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "armorStrippingDiagnosticConsolidation81", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; The stripping thresholds are now fullness percentages. Establish 100/100/100
    ; once for saves that already carried the earlier absolute keys; the old
    ; absolute keys are left inert and are no longer read anywhere.
    If JsonUtil.GetIntValue(SettingsFile, "armorStrippingPercentMigration82", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyPercent", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightPercent", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripClothingPercent", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "armorStrippingPercentMigration82", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Post-strip reactions: notification, HOT moan, and forced Skyrim.Net
    ; narration with chance/cooldown. One-time defaults; later user choices win.
    If JsonUtil.GetIntValue(SettingsFile, "armorStripReactionMigration83", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoan", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorStripNarrationChance", 100)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripNarrationCooldown", 300.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotificationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "armorStripReactionMigration83", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
EndFunction

Function SetArmorReactionDefaults()
    ; One helper defines the complete role/family matrix. Player animations start
    ; off; NPC animations start on; equip moans start on for every family.
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipAnimation", 0)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkingArmorEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkingArmorEquipAnimation", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingArmorEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingArmorEquipAnimation", 0)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingArmorEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingArmorEquipAnimation", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipAnimation", 0)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingParasiteEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingParasiteEquipAnimation", 1)
    JsonUtil.SetFloatValue(SettingsFile, "playerMilkingArmorNarrationCooldown", 120.0)
    JsonUtil.SetFloatValue(SettingsFile, "npcMilkingArmorNarrationCooldown", 300.0)
    JsonUtil.SetIntValue(SettingsFile, "enableArmorDebug", 0)
EndFunction

; Old first-equip settings do not map cleanly to per-equip reactions. Preserve
; the old moan choices, use the requested Player animation default, and keep
; the prior NPC animation behavior.
Function MigrateArmorReactionSettings()
    ; Preserve legacy Milking Armor choices while creating explicit Living and
    ; Parasite settings. Old "Sound" keys map once to the clearer "Moan" keys.
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipMoan", JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipSound", 1))
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipAnimation", 0)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkingArmorEquipMoan", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkingArmorEquipSound", 1))
    JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkingArmorEquipAnimation", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkingArmorFirstEquipAnimation", 1))
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingArmorEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingArmorEquipAnimation", 0)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingArmorEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingArmorEquipAnimation", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipAnimation", 0)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingParasiteEquipMoan", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableNPCLivingParasiteEquipAnimation", 1)
EndFunction

; Renders the selected SkyUI page from persisted JContainers settings.
Event OnPageReset(String page)
    ; Rebuild option IDs on every page render; SkyUI IDs are ephemeral and must
    ; never be persisted. Runtime values are always reread from JsonUtil.
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
    skyrimNetOStimTraceOption = -1
    skyrimNetSexLabTraceOption = -1
    drinkMoansOption = -1
    fullnessMoansOption = -1
    milkingMoansOption = -1
    skyrimNetStatusOption = -1
    arousalStatusOption = -1
    milkDrinkArousalOption = -1
    milkDrinkArousalAmountOption = -1
    dialogueDiagnosticOption = -1
    sexLabBreastfeedingDebugOption = -1
    npcDrinkAnimationOption = -1
    npcDrinkAnimationDurationOption = -1
    playerDrinkAnimationOption = -1
    playerDrinkAnimationDurationOption = -1
    milkDrinkAnimationDiagnosticOption = -1
    playerHalfFullSelfMilkAnimationOption = -1
    playerFullSelfMilkAnimationOption = -1
    playerFullnessSelfMilkAnimationDurationOption = -1
    npcHalfFullSelfMilkAnimationOption = -1
    npcFullSelfMilkAnimationOption = -1
    npcFullnessSelfMilkAnimationDurationOption = -1
    fullnessSelfMilkAnimationDiagnosticOption = -1
    npcMilkEffectsOption = -1
    npcMilkConsumptionDiagnosticOption = -1
    npcDrinkNotificationsOption = -1
    npcDrinkNotificationsDiagnosticOption = -1
    playerDrinkNotificationsOption = -1
    armorStrippingCheckDiagnosticOption = -1
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
    milkHalfFullNarrationOption = -1
    milkHalfFullNarrationCooldownOption = -1
    milkHalfFullNarrationDiagnosticOption = -1
    npcDrinkNarrationOption = -1
    npcDrinkNarrationCooldownOption = -1
    npcDrinkNarrationDiagnosticOption = -1
    playerDrinkNarrationOption = -1
    playerDrinkNarrationCooldownOption = -1
    playerDrinkNarrationDiagnosticOption = -1
    playerDrinkNarrationChanceOption = -1
    milkmaidCreatedNarrationOption = -1
    milkmaidCreatedNarrationCooldownOption = -1
    milkmaidCreatedNarrationDiagnosticOption = -1
    selfMilkingActionOption = -1
    pairedMilkingActionOption = -1
    selfMilkingActionDiagnosticOption = -1
    pairedMilkingActionDiagnosticOption = -1
    masterEnableOption = -1
    ostimBreastfeedingOption = -1
    ostimBreastfeedingDurationOption = -1
    ostimStatusOption = -1
    ostimDebugOption = -1
    playerMilkingArmorEquipMoanOption = -1
    playerMilkingArmorEquipAnimationOption = -1
    npcMilkingArmorEquipMoanOption = -1
    npcMilkingArmorEquipAnimationOption = -1
    playerLivingArmorEquipMoanOption = -1
    playerLivingArmorEquipAnimationOption = -1
    npcLivingArmorEquipMoanOption = -1
    npcLivingArmorEquipAnimationOption = -1
    playerLivingParasiteEquipMoanOption = -1
    playerLivingParasiteEquipAnimationOption = -1
    npcLivingParasiteEquipMoanOption = -1
    npcLivingParasiteEquipAnimationOption = -1
    nearbyMilkArmorStatusOption = -1
    playerMilkArmorEquipNarrationOption = -1
    npcMilkArmorEquipNarrationOption = -1
    playerMilkingArmorNarrationCooldownOption = -1
    npcMilkingArmorNarrationCooldownOption = -1
    armorDebugOption = -1
    blacksmithDebugOption = -1
    extensionsArmorStrippingOption = -1
    armorStripHeavyThresholdOption = -1
    armorStripLightThresholdOption = -1
    armorStripClothingThresholdOption = -1
    armorStripNotificationOption = -1
    armorStripMoanOption = -1
    armorStripNarrationOption = -1
    armorStripNarrationChanceOption = -1
    armorStripNarrationCooldownOption = -1
    armorStripNotificationDiagnosticOption = -1
    armorStripMoanDiagnosticOption = -1
    armorStripNarrationDiagnosticOption = -1
    SetCursorFillMode(TOP_TO_BOTTOM)
    If page == "Milk Drinking"
        AddHeaderOption("Milk Gain Per Drink")
        milkmaidLevelBonusOption = AddToggleOption("MME Level Bonus", JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1) == 1)
        flatMilkBonusOption = AddSliderOption("Flat Milk Bonus", JsonUtil.GetFloatValue(SettingsFile, "flatMilkBonus", 1.0), "+{1} milk")
        lactacidMultiplierOption = AddSliderOption("Lactacid Multiplier", JsonUtil.GetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0), "x{1}")
        AddHeaderOption("NPC Milk Drinking")
        npcMilkEffectsOption = AddToggleOption("NPC Milk Effects", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkEffects", 1) == 1)
        npcDrinkNotificationsOption = AddToggleOption("NPC Drink Notifications", JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNotifications", 1) == 1)
        AddHeaderOption("Player Milk Drinking")
        playerDrinkNotificationsOption = AddToggleOption("Player Drink Notifications", JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNotifications", 1) == 1)
        Return
    EndIf
    If page == "A" + "nimations "
        AddHeaderOption("Player Milk Drinking")
        playerDrinkAnimationOption = AddToggleOption("Player Milk-Drink Animation", JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkAnimation", 0) == 1)
        playerDrinkAnimationDurationOption = AddSliderOption("Player Milk-Drink Animation Duration", JsonUtil.GetFloatValue(SettingsFile, "playerDrinkAnimationDuration", 3.0), "{0} seconds")
        AddHeaderOption("NPC Milk Drinking")
        npcDrinkAnimationOption = AddToggleOption("NPC Milk-Drink Animation", JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0) == 1)
        npcDrinkAnimationDurationOption = AddSliderOption("NPC Milk-Drink Animation Duration", JsonUtil.GetFloatValue(SettingsFile, "npcDrinkAnimationDuration", 3.0), "{0} seconds")
        AddHeaderOption("Player Fullness")
        playerHalfFullSelfMilkAnimationOption = AddToggleOption("Player Half-Full Animation", JsonUtil.GetIntValue(SettingsFile, "enablePlayerHalfFullSelfMilkAnimation", 0) == 1)
        playerFullSelfMilkAnimationOption = AddToggleOption("Player Full Animation", JsonUtil.GetIntValue(SettingsFile, "enablePlayerFullSelfMilkAnimation", 0) == 1)
        playerFullnessSelfMilkAnimationDurationOption = AddSliderOption("Player Fullness Animation Duration", JsonUtil.GetFloatValue(SettingsFile, "playerFullnessSelfMilkAnimationDuration", 3.0), "{0} seconds")
        AddHeaderOption("NPC Fullness")
        npcHalfFullSelfMilkAnimationOption = AddToggleOption("NPC Half-Full Animation", JsonUtil.GetIntValue(SettingsFile, "enableNPCHalfFullSelfMilkAnimation", 1) == 1)
        npcFullSelfMilkAnimationOption = AddToggleOption("NPC Full Animation", JsonUtil.GetIntValue(SettingsFile, "enableNPCFullSelfMilkAnimation", 1) == 1)
        npcFullnessSelfMilkAnimationDurationOption = AddSliderOption("NPC Fullness Animation Duration", JsonUtil.GetFloatValue(SettingsFile, "npcFullnessSelfMilkAnimationDuration", 3.0), "{0} seconds")
        Bool ostimAvailable = MMEOStimBreastfeeding.IsOStimDetected()
        Int ostimFlags = OPTION_FLAG_DISABLED
        If ostimAvailable
            ostimFlags = OPTION_FLAG_NONE
        EndIf
        AddHeaderOption("OStim")
        ostimStatusOption = AddToggleOption("OStim Detected", ostimAvailable, OPTION_FLAG_DISABLED)
        ostimBreastfeedingOption = AddToggleOption("Use OStim Breastfeeding", JsonUtil.GetIntValue(SettingsFile, "enableOStimBreastfeeding", 0) == 1, ostimFlags)
        ostimBreastfeedingDurationOption = AddSliderOption("OStim Breastfeeding Scene Duration", JsonUtil.GetFloatValue(SettingsFile, "ostimBreastfeedingDuration", 20.0), "{0} seconds", ostimFlags)
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
    If page == "Armor"
        AddHeaderOption("Armor Stripping")
        extensionsArmorStrippingOption = AddToggleOption("Override MME Armor Stripping", JsonUtil.GetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1) == 1)
        Int stripFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1) != 1
            stripFlags = OPTION_FLAG_DISABLED
        EndIf
        Int narrationFlags = stripFlags
        If narrationFlags == OPTION_FLAG_NONE && JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarration", 1) != 1
            narrationFlags = OPTION_FLAG_DISABLED
        EndIf
        armorStripHeavyThresholdOption = AddSliderOption("Heavy Armor Fullness Threshold", JsonUtil.GetFloatValue(SettingsFile, "armorStripHeavyPercent", 100.0), "{0}%", stripFlags)
        armorStripLightThresholdOption = AddSliderOption("Light Armor Fullness Threshold", JsonUtil.GetFloatValue(SettingsFile, "armorStripLightPercent", 100.0), "{0}%", stripFlags)
        armorStripClothingThresholdOption = AddSliderOption("Clothing Fullness Threshold", JsonUtil.GetFloatValue(SettingsFile, "armorStripClothingPercent", 100.0), "{0}%", stripFlags)
        AddHeaderOption("Armor Strip Reactions")
        armorStripNotificationOption = AddToggleOption("Strip Notification", JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNotification", 1) == 1, stripFlags)
        armorStripMoanOption = AddToggleOption("Strip Moan", JsonUtil.GetIntValue(SettingsFile, "enableArmorStripMoan", 1) == 1, stripFlags)
        armorStripNarrationOption = AddToggleOption("Skyrim.Net Strip Narration", JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarration", 1) == 1, stripFlags)
        armorStripNarrationChanceOption = AddSliderOption("Narration Chance", JsonUtil.GetIntValue(SettingsFile, "armorStripNarrationChance", 100), "{0}%", narrationFlags)
        armorStripNarrationCooldownOption = AddSliderOption("Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "armorStripNarrationCooldown", 300.0) / 60.0, "{0} minutes", narrationFlags)
        AddHeaderOption("Milking Armor")
        playerMilkingArmorEquipMoanOption = AddToggleOption("Player Equip Moan", JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipMoan", 1) == 1)
        playerMilkingArmorEquipAnimationOption = AddToggleOption("Player Equip Animation", JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipAnimation", 0) == 1)
        npcMilkingArmorEquipMoanOption = AddToggleOption("NPC Equip Moan", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkingArmorEquipMoan", 1) == 1)
        npcMilkingArmorEquipAnimationOption = AddToggleOption("NPC Equip Animation", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkingArmorEquipAnimation", 1) == 1)
        AddHeaderOption("AM Living Armor")
        playerLivingArmorEquipMoanOption = AddToggleOption("Player Equip Moan", JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingArmorEquipMoan", 1) == 1)
        playerLivingArmorEquipAnimationOption = AddToggleOption("Player Equip Animation", JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingArmorEquipAnimation", 0) == 1)
        npcLivingArmorEquipMoanOption = AddToggleOption("NPC Equip Moan", JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingArmorEquipMoan", 1) == 1)
        npcLivingArmorEquipAnimationOption = AddToggleOption("NPC Equip Animation", JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingArmorEquipAnimation", 1) == 1)
        AddHeaderOption("AM Living Parasite")
        playerLivingParasiteEquipMoanOption = AddToggleOption("Player Equip Moan", JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipMoan", 1) == 1)
        playerLivingParasiteEquipAnimationOption = AddToggleOption("Player Equip Animation", JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipAnimation", 0) == 1)
        npcLivingParasiteEquipMoanOption = AddToggleOption("NPC Equip Moan", JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingParasiteEquipMoan", 1) == 1)
        npcLivingParasiteEquipAnimationOption = AddToggleOption("NPC Equip Animation", JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingParasiteEquipAnimation", 1) == 1)
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
        AddHeaderOption("Milk Armor")
        nearbyMilkArmorStatusOption = AddToggleOption("Track Nearby Milk Armor Status", JsonUtil.GetIntValue(SettingsFile, "enableNearbyMilkArmorStatus", 1) == 1)
        playerMilkArmorEquipNarrationOption = AddToggleOption("Player Milk Armor Equip Narration", JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", 1) == 1)
        npcMilkArmorEquipNarrationOption = AddToggleOption("NPC Milk Armor Equip Narration", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", 1) == 1)
        Int playerArmorNarrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", 1) != 1
            playerArmorNarrationFlags = OPTION_FLAG_DISABLED
        EndIf
        Int npcArmorNarrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", 1) != 1
            npcArmorNarrationFlags = OPTION_FLAG_DISABLED
        EndIf
        playerMilkingArmorNarrationCooldownOption = AddSliderOption("Player Armor Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "playerMilkingArmorNarrationCooldown", 120.0), "{0} seconds", playerArmorNarrationFlags)
        npcMilkingArmorNarrationCooldownOption = AddSliderOption("NPC Armor Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "npcMilkingArmorNarrationCooldown", 300.0), "{0} seconds", npcArmorNarrationFlags)
        AddHeaderOption("Actions")
        selfMilkingActionOption = AddToggleOption("Allow Self-Milking Action", JsonUtil.GetIntValue(SettingsFile, "enableSelfMilkingAction", 1) == 1)
        pairedMilkingActionOption = AddToggleOption("Allow Paired Milking Action", JsonUtil.GetIntValue(SettingsFile, "enablePairedMilkingAction", 1) == 1)
        AddHeaderOption("AI Reactions")
        milkFullNarrationOption = AddToggleOption("Narrate Milk Full", JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarration", 1) == 1)
        Int narrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarration", 1) != 1
            narrationFlags = OPTION_FLAG_DISABLED
        EndIf
        milkFullNarrationCooldownOption = AddSliderOption("Milk Full Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "milkFullNarrationCooldown", 60.0), "{0} seconds", narrationFlags)
        milkHalfFullNarrationOption = AddToggleOption("Half-Full Milk Narration", JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarration", 1) == 1)
        narrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarration", 1) != 1
            narrationFlags = OPTION_FLAG_DISABLED
        EndIf
        milkHalfFullNarrationCooldownOption = AddSliderOption("Half-Full Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "milkHalfFullNarrationCooldown", 60.0), "{0} seconds", narrationFlags)
        playerDrinkNarrationOption = AddToggleOption("Player Drink Narration", JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarration", 0) == 1)
        narrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarration", 0) != 1
            narrationFlags = OPTION_FLAG_DISABLED
        EndIf
        playerDrinkNarrationCooldownOption = AddSliderOption("Player Drink Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "playerDrinkNarrationCooldown", 60.0), "{0} seconds", narrationFlags)
        playerDrinkNarrationChanceOption = AddSliderOption("Player Drink Narration Chance", JsonUtil.GetIntValue(SettingsFile, "playerDrinkNarrationChance", 25), "{0}%", narrationFlags)
        milkmaidCreatedNarrationOption = AddToggleOption("New Milk Maid Narration", JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", 1) == 1)
        narrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", 1) != 1
            narrationFlags = OPTION_FLAG_DISABLED
        EndIf
        milkmaidCreatedNarrationCooldownOption = AddSliderOption("New Milk Maid Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "milkmaidCreatedNarrationCooldown", 60.0), "{0} seconds", narrationFlags)
        npcDrinkNarrationOption = AddToggleOption("NPC Drink Narration", JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarration", 1) == 1)
        narrationFlags = OPTION_FLAG_NONE
        If JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarration", 1) != 1
            narrationFlags = OPTION_FLAG_DISABLED
        EndIf
        npcDrinkNarrationCooldownOption = AddSliderOption("NPC Drink Narration Cooldown", JsonUtil.GetFloatValue(SettingsFile, "npcDrinkNarrationCooldown", 60.0), "{0} seconds", narrationFlags)
        Return
    EndIf
    If page == "Debug"
        AddHeaderOption("MME Extensions")
        masterEnableOption = AddToggleOption("Enable MME Extensions", JsonUtil.GetIntValue(SettingsFile, "enableMMEExtensions", 1) == 1)
        AddHeaderOption("Core / Development")
        lifecycleDiagnosticOption = AddToggleOption("Location Wait Load", JsonUtil.GetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0) == 1)
        milkmaidCreationDiagnosticOption = AddToggleOption("Milkmaid Creation Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 1) == 1)
        nativeScanDiagnosticOption = AddToggleOption("Native Actor Scan Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0) == 1)
        debugMilkingEventsOption = AddToggleOption("Report Milking Start/End", JsonUtil.GetIntValue(SettingsFile, "enableMilkingEventDebug", 1) == 1)
        debugMilkReportOption = AddToggleOption("Milk Status Every 5 Seconds", JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1)
        AddHeaderOption("Milk Drinking")
        addMilkDebugOption = AddToggleOption("Milk Drinking Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1)
        npcMilkConsumptionDiagnosticOption = AddToggleOption("NPC Milk Consumption", JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0) == 1)
        npcDrinkNotificationsDiagnosticOption = AddToggleOption("NPC Drink Notifications", JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNotificationsDiagnostic", 0) == 1)
        AddHeaderOption("Armor Debug")
        armorStrippingCheckDiagnosticOption = AddToggleOption("Armor Stripping Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableArmorOverflowDiagnostic", 0) == 1)
        armorStripNotificationDiagnosticOption = AddToggleOption("Strip Notification Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNotificationDiagnostic", 0) == 1)
        armorStripMoanDiagnosticOption = AddToggleOption("Strip Moan Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableArmorStripMoanDiagnostic", 0) == 1)
        armorStripNarrationDiagnosticOption = AddToggleOption("Strip Narration Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarrationDiagnostic", 0) == 1)
        armorDebugOption = AddToggleOption("Equip Reaction Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableArmorDebug", 0) == 1)
        blacksmithDebugOption = AddToggleOption("Blacksmith Debug", JsonUtil.GetIntValue(SettingsFile, "enableBlacksmithDebug", 0) == 1)
        AddHeaderOption("A" + "nimations ")
        milkDrinkAnimationDiagnosticOption = AddToggleOption("Milk Drink Animation", JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0) == 1)
        fullnessSelfMilkAnimationDiagnosticOption = AddToggleOption("Fullness Animation", JsonUtil.GetIntValue(SettingsFile, "enableFullnessSelfMilkAnimationDiagnostic", 0) == 1)
        selfMilkingActionDiagnosticOption = AddToggleOption("Self-Milking Action Diagnostic", JsonUtil.GetIntValue(SettingsFile, "enableSelfMilkingActionDiagnostic", 0) == 1)
        pairedMilkingActionDiagnosticOption = AddToggleOption("Paired Milking Action Diagnostic", JsonUtil.GetIntValue(SettingsFile, "enablePairedMilkingActionDiagnostic", 0) == 1)
        SetCursorPosition(1)
        AddHeaderOption("Skyrim.Net")
        skyrimNetDrinkDiagnosticOption = AddToggleOption("Milk Drink Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0) == 1)
        skyrimNetMilkingDiagnosticOption = AddToggleOption("Milking Start/End Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0) == 1)
        skyrimNetCreationDiagnosticOption = AddToggleOption("New Milkmaid Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0) == 1)
        skyrimNetStatusDiagnosticOption = AddToggleOption("Nearby Milk Status Events", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0) == 1)
        skyrimNetPromptDiagnosticOption = AddToggleOption("Milkmaid Bio Prompt", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 1) == 1)
        skyrimNetOStimTraceOption = AddToggleOption("Skyrim.Net OStim Trace", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetOStimTrace", 0) == 1)
        skyrimNetSexLabTraceOption = AddToggleOption("Skyrim.Net SexLab Trace", JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", 0) == 1)
        milkFullNarrationDiagnosticOption = AddToggleOption("Milk Full Narration Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0) == 1)
        milkHalfFullNarrationDiagnosticOption = AddToggleOption("Half-Full Narration Diagnostic", JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarrationDiagnostic", 0) == 1)
        playerDrinkNarrationDiagnosticOption = AddToggleOption("Player Drink Narration Diagnostic", JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarrationDiagnostic", 0) == 1)
        npcDrinkNarrationDiagnosticOption = AddToggleOption("NPC Drink Narration Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarrationDiagnostic", 0) == 1)
        milkmaidCreatedNarrationDiagnosticOption = AddToggleOption("New Milk Maid Narration Diagnostic", JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarrationDiagnostic", 0) == 1)
        AddHeaderOption("Dialogue")
        dialogueDiagnosticOption = AddToggleOption("NPC Dialogue Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0) == 1)
        sexLabBreastfeedingDebugOption = AddToggleOption("SexLab Breastfeeding Debug", JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0) == 1)
        ostimDebugOption = AddToggleOption("OStim Breastfeeding Debug", JsonUtil.GetIntValue(SettingsFile, "enableOStimDebug", 0) == 1)
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
    If option == masterEnableOption
        SetInfoText("Turn MME Extensions on or off.")
    ElseIf option == soundsOption
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
        SetInfoText("Periodically checks nearby Milkmaid fullness and player armor stripping. Disabling this also disables passive armor stripping checks, but drink and equip checks still work.")
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
        SetInfoText("Play MME's original Lactacid/New Milkmaid reaction animation after a Milkmaid drinks through dialogue.")
    ElseIf option == npcDrinkAnimationDurationOption
        SetInfoText("Set how long the NPC Milk-Drink Animation plays before the actor returns to idle.")
    ElseIf option == playerDrinkAnimationOption
        SetInfoText("Play MME's original Lactacid/New Milkmaid reaction animation after you drink recognized milk.")
    ElseIf option == playerDrinkAnimationDurationOption
        SetInfoText("Set how long your Milk-Drink Animation plays before you return to idle.")
    ElseIf option == playerHalfFullSelfMilkAnimationOption
        SetInfoText("Play MME's Self-Milk animation when you cross 50% fullness.")
    ElseIf option == playerFullSelfMilkAnimationOption
        SetInfoText("Play MME's standing milking animation when you cross 100% fullness, without triggering milking.")
    ElseIf option == playerFullnessSelfMilkAnimationDurationOption
        SetInfoText("Set how long your fullness self-milk animations play before you return to idle.")
    ElseIf option == npcHalfFullSelfMilkAnimationOption
        SetInfoText("Play MME's Self-Milk animation when an NPC Milkmaid crosses 50% fullness.")
    ElseIf option == npcFullSelfMilkAnimationOption
        SetInfoText("Play MME's standing milking animation when an NPC Milkmaid crosses 100% fullness, without triggering milking.")
    ElseIf option == npcFullnessSelfMilkAnimationDurationOption
        SetInfoText("Set how long NPC fullness self-milk animations play before the actor returns to idle.")
    ElseIf option == ostimBreastfeedingOption
        SetInfoText("Add optional OStim nipple-sucking choices beside MME's original SexLab breastfeeding dialogue.")
    ElseIf option == ostimBreastfeedingDurationOption
        SetInfoText("Set how long the dedicated fixed OStim breastfeeding scene runs. This is independent of MME milking completion.")
    ElseIf option == ostimStatusOption
        SetInfoText("Read-only. Enabled when OStim.esp is active in the load order.")
    ElseIf option == ostimDebugOption
        SetInfoText("Show in-game reasons when OStim breastfeeding is unavailable, blocked, or fails to start.")
    ElseIf option == npcMilkEffectsOption
        SetInfoText("Apply milk, arousal, and moan effects when an MME Milkmaid consumes recognized milk.")
    ElseIf option == npcDrinkNotificationsOption
        SetInfoText("Show a notification after an NPC Milkmaid drinks recognized milk.")
    ElseIf option == playerDrinkNotificationsOption
        SetInfoText("Show a notification after you drink recognized milk.")
    ElseIf option == selfMilkingActionOption
        SetInfoText("Allow Skyrim.Net to start self-milking for a selected Milk Maid.")
    ElseIf option == pairedMilkingActionOption
        SetInfoText("Allow Skyrim.Net to start a milk-sharing scene with the selected source and the player.")
    ElseIf option == npcMilkConsumptionDiagnosticOption
        SetInfoText("Report native NPC milk detection, Milkmaid validation, duplicates, and applied effects.")
    ElseIf option == npcDrinkNotificationsDiagnosticOption
        SetInfoText("Report NPC drink notification skips and the effective milk and arousal results shown.")
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
        SetInfoText("Report the full player milk-drink transaction: detection, sound, milk bonus math, arousal, notification, and MME add results.")
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
    ElseIf option == skyrimNetOStimTraceOption
        SetInfoText("Show Skyrim.Net breastfeeding action selection, semantic roles, OStim routing, and startup. If no SN BF intent appears, another action was selected before this mod ran.")
    ElseIf option == skyrimNetSexLabTraceOption
        SetInfoText("Trace a Skyrim.Net breastfeeding request through actor validation, acquisition, SexLab startup, and MME Mode 4 confirmation.")
    ElseIf option == skyrimNetStatusOption
        SetInfoText("Read-only. Enabled when SkyrimNet.esp is active in the load order.")
    ElseIf option == skyrimNetMilkStatusesOption
        SetInfoText("Send nearby Milkmaid states plus half-full and full milestones to Skyrim.Net.")
    ElseIf option == skyrimNetStatusIntervalOption
        SetInfoText("Set the shared nearby Skyrim.Net refresh interval. Nearby armor context keeps a 45-second lifetime.")
    ElseIf option == milkFullNarrationOption
        SetInfoText("Ask Skyrim.Net for one immediate Milk Maid reaction at full capacity. Uses LLM tokens.")
    ElseIf option == milkFullNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using milk-full narrations.")
    ElseIf option == milkFullNarrationDiagnosticOption
        SetInfoText("Report milk-full narration triggers, cooldowns, payload calls, and API results.")
    ElseIf option == milkHalfFullNarrationOption
        SetInfoText("Ask Skyrim.Net for one immediate Milk Maid reaction at half capacity. Uses LLM tokens.")
    ElseIf option == milkHalfFullNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using half-full narrations.")
    ElseIf option == milkHalfFullNarrationDiagnosticOption
        SetInfoText("Report half-full narration triggers, cooldowns, payload calls, and API results.")
    ElseIf option == playerDrinkNarrationOption
        SetInfoText("Ask Skyrim.Net for one immediate reaction after you drink recognized milk. Uses LLM tokens.")
    ElseIf option == playerDrinkNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using player drink narrations.")
    ElseIf option == playerDrinkNarrationChanceOption
        SetInfoText("Set the chance that an eligible player drink requests narration after normal drink tracking.")
    ElseIf option == playerDrinkNarrationDiagnosticOption
        SetInfoText("Report player drink narration detection, cooldowns, and API results.")
    ElseIf option == milkmaidCreatedNarrationOption
        SetInfoText("Ask Skyrim.Net for one immediate reaction when an actor becomes a new Milk Maid. Uses LLM tokens.")
    ElseIf option == milkmaidCreatedNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using new-Milk-Maid narrations.")
    ElseIf option == milkmaidCreatedNarrationDiagnosticOption
        SetInfoText("Report new-Milk-Maid narration detection, cooldowns, and API results.")
    ElseIf option == armorStrippingCheckDiagnosticOption
        SetInfoText("Report the full armor stripping transaction: drink attempt, delayed timer, milk values, slot 32, armor type, threshold, override state, protection, and strip result.")
    ElseIf option == armorStripNotificationDiagnosticOption
        SetInfoText("Report armor-strip notification triggers, feature state, and shown/skipped results.")
    ElseIf option == armorStripMoanDiagnosticOption
        SetInfoText("Report armor-strip moan triggers, feature state, sound lookup, and playback results.")
    ElseIf option == armorStripNarrationDiagnosticOption
        SetInfoText("Report armor-strip narration triggers, gates, chance, cooldown, and Skyrim.Net results.")
    ElseIf option == extensionsArmorStrippingOption
        SetInfoText("Take over armor stripping from Milk Mod Economy. While enabled, MME's original stripping is disabled and these fullness thresholds are used instead.")
    ElseIf option == armorStripHeavyThresholdOption
        SetInfoText("Unequip heavy body armor when the player's fullness reaches this percentage. 0 forbids this armor type; 100 strips at full.")
    ElseIf option == armorStripLightThresholdOption
        SetInfoText("Unequip light body armor when the player's fullness reaches this percentage. 0 forbids this armor type; 100 strips at full.")
    ElseIf option == armorStripClothingThresholdOption
        SetInfoText("Unequip clothing when the player's fullness reaches this percentage. 0 forbids this armor type; 100 strips at full.")
    ElseIf option == armorStripNotificationOption
        SetInfoText("Show a notification when milk fullness forces your worn armor or clothing off.")
    ElseIf option == armorStripMoanOption
        SetInfoText("Play a strong reaction moan when milk fullness forces your worn armor or clothing off.")
    ElseIf option == armorStripNarrationOption
        SetInfoText("Ask Skyrim.Net for an immediate exaggerated reaction when milk fullness forces armor or clothing off. Uses LLM tokens.")
    ElseIf option == armorStripNarrationChanceOption
        SetInfoText("Set the chance that an eligible armor-strip event requests Skyrim.Net narration.")
    ElseIf option == armorStripNarrationCooldownOption
        SetInfoText("Set the minimum real-time delay between successful armor-strip narrations.")
    ElseIf option == armorDebugOption
        SetInfoText("Report armor classification, matched MME list, equip reactions, nearby tracking, narration gates, and Skyrim.Net results.")
    ElseIf option == blacksmithDebugOption
        SetInfoText("Report Blacksmith eligibility, worn armor state, supported-milk payment, MilkingEquipment capacity, same-armor checks, and verified add/remove results.")
    ElseIf option == playerMilkingArmorEquipMoanOption || option == npcMilkingArmorEquipMoanOption
        SetInfoText("Play the mild equip moan whenever the matching Milk Maid equips supported Milking Armor.")
    ElseIf option == playerMilkingArmorEquipAnimationOption || option == npcMilkingArmorEquipAnimationOption
        SetInfoText("Play the shared three-second Standing reaction whenever supported Milking Armor is equipped.")
    ElseIf option == playerLivingArmorEquipMoanOption || option == npcLivingArmorEquipMoanOption
        SetInfoText("Play the strongest equip moan pool whenever the matching Milk Maid equips configured AM Living Armor.")
    ElseIf option == playerLivingArmorEquipAnimationOption || option == npcLivingArmorEquipAnimationOption
        SetInfoText("Play the shared three-second Kneeling reaction whenever configured AM Living Armor is equipped.")
    ElseIf option == playerLivingParasiteEquipMoanOption || option == npcLivingParasiteEquipMoanOption
        SetInfoText("Play the strongest equip moan pool whenever the matching Milk Maid equips configured AM Living Parasite armor.")
    ElseIf option == playerLivingParasiteEquipAnimationOption || option == npcLivingParasiteEquipAnimationOption
        SetInfoText("Play the shared three-second Kneeling reaction whenever configured AM Living Parasite armor is equipped.")
    ElseIf option == nearbyMilkArmorStatusOption
        SetInfoText("Refresh one combined Player-attached Skyrim.Net context for nearby Milk Maids wearing supported MME armor.")
    ElseIf option == playerMilkArmorEquipNarrationOption
        SetInfoText("Directly narrate supported Player Milk Armor equips through Skyrim.Net.")
    ElseIf option == npcMilkArmorEquipNarrationOption
        SetInfoText("Directly narrate supported NPC Milk Maid armor equips through Skyrim.Net.")
    ElseIf option == playerMilkingArmorNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using Player Milking Armor narrations.")
    ElseIf option == npcMilkingArmorNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using NPC Milking Armor narrations.")
    ElseIf option == selfMilkingActionDiagnosticOption
        SetInfoText("Report self-milking action registration, Milk Maid checks, and spell requests.")
    ElseIf option == pairedMilkingActionDiagnosticOption
        SetInfoText("Report paired milking action registration, actor selection, dependency checks, and scene results.")
    ElseIf option == fullnessSelfMilkAnimationDiagnosticOption
        SetInfoText("Report PLAYER/NPC fullness animation triggers, selected animation, start, skip, and reset reasons.")
    ElseIf option == milkDrinkAnimationDiagnosticOption
        SetInfoText("Report whether PLAYER or NPC triggered the drink animation, what was detected, and why it started or skipped.")
    ElseIf option == npcDrinkNarrationOption
        SetInfoText("Ask Skyrim.Net for one immediate reaction when an NPC Milkmaid drinks supported milk. Uses LLM tokens.")
    ElseIf option == npcDrinkNarrationCooldownOption
        SetInfoText("Set the global real-time delay between token-using NPC drink narrations.")
    ElseIf option == npcDrinkNarrationDiagnosticOption
        SetInfoText("Report NPC drink detection, dialogue drinks, narration gates, cooldowns, and API results.")
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
    ElseIf option == dialogueDiagnosticOption
        SetInfoText("Report dialogue target detection and MME Milkmaid validation.")
    ElseIf option == sexLabBreastfeedingDebugOption
        SetInfoText("Diagnose MME's original SexLab breastfeeding route when Hey there executes. Never changes eligibility.")
    EndIf
EndEvent

; Persists toggle changes and refreshes only controllers affected by that option.
Event OnOptionSelect(Int option)
    ; Each branch commits one setting and performs only the minimal live refresh
    ; required by that feature (controller polling, action registration, etc.).
    If option == masterEnableOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMMEExtensions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMMEExtensions", value)
        SetToggleOptionValue(option, value == 1)
        MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If controller != None
            If value == 1
                controller.InitializeController()
            Else
                controller.DisableController()
            EndIf
        EndIf
    ElseIf option == soundsOption
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
    ElseIf option == milkHalfFullNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkHalfFullNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == milkHalfFullNarrationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkHalfFullNarrationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == playerDrinkNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarration", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == milkmaidCreatedNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == playerDrinkNarrationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNarrationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkmaidCreatedNarrationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidCreatedNarrationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcDrinkNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == npcDrinkNarrationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNarrationDiagnostic", value)
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
    ElseIf option == npcDrinkNotificationsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNotifications", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == playerDrinkNotificationsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkNotifications", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == selfMilkingActionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSelfMilkingAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingAction", value)
        SetToggleOptionValue(option, value == 1)
        If value == 1
            MMESkyrimNetVoiceControls.RegisterSelfMilkingAction()
        ElseIf MMEAlertsSkyrimNet.IsAvailable()
            SkyrimNetApi.UnregisterAction("StartMilkMaidSelfMilking")
        EndIf
    ElseIf option == pairedMilkingActionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePairedMilkingAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingAction", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcMilkConsumptionDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcDrinkNotificationsDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNotificationsDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkNotificationsDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorStrippingCheckDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorOverflowDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorOverflowDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == extensionsArmorStrippingOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableExtensionsArmorStripping", value)
        SetToggleOptionValue(option, value == 1)
        MMEArmorScript.ApplyArmorStrippingMasterToggle()
        ForcePageReset()
    ElseIf option == armorStripNotificationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotification", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorStripMoanOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripMoan", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoan", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorStripNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == armorStripNotificationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNotificationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotificationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorStripMoanDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripMoanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoanDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorStripNarrationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarrationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == blacksmithDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBlacksmithDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableBlacksmithDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == playerMilkingArmorEquipMoanOption
        ToggleArmorSetting(option, "enablePlayerMilkingArmorEquipMoan", 1)
    ElseIf option == playerMilkingArmorEquipAnimationOption
        ToggleArmorSetting(option, "enablePlayerMilkingArmorEquipAnimation", 0)
    ElseIf option == npcMilkingArmorEquipMoanOption
        ToggleArmorSetting(option, "enableNPCMilkingArmorEquipMoan", 1)
    ElseIf option == npcMilkingArmorEquipAnimationOption
        ToggleArmorSetting(option, "enableNPCMilkingArmorEquipAnimation", 1)
    ElseIf option == playerLivingArmorEquipMoanOption
        ToggleArmorSetting(option, "enablePlayerLivingArmorEquipMoan", 1)
    ElseIf option == playerLivingArmorEquipAnimationOption
        ToggleArmorSetting(option, "enablePlayerLivingArmorEquipAnimation", 0)
    ElseIf option == npcLivingArmorEquipMoanOption
        ToggleArmorSetting(option, "enableNPCLivingArmorEquipMoan", 1)
    ElseIf option == npcLivingArmorEquipAnimationOption
        ToggleArmorSetting(option, "enableNPCLivingArmorEquipAnimation", 1)
    ElseIf option == playerLivingParasiteEquipMoanOption
        ToggleArmorSetting(option, "enablePlayerLivingParasiteEquipMoan", 1)
    ElseIf option == playerLivingParasiteEquipAnimationOption
        ToggleArmorSetting(option, "enablePlayerLivingParasiteEquipAnimation", 0)
    ElseIf option == npcLivingParasiteEquipMoanOption
        ToggleArmorSetting(option, "enableNPCLivingParasiteEquipMoan", 1)
    ElseIf option == npcLivingParasiteEquipAnimationOption
        ToggleArmorSetting(option, "enableNPCLivingParasiteEquipAnimation", 1)
    ElseIf option == nearbyMilkArmorStatusOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNearbyMilkArmorStatus", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNearbyMilkArmorStatus", value)
        SetToggleOptionValue(option, value == 1)
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
    ElseIf option == playerMilkArmorEquipNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == npcMilkArmorEquipNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == selfMilkingActionDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSelfMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingActionDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == pairedMilkingActionDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePairedMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingActionDiagnostic", value)
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
    ElseIf option == skyrimNetOStimTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetOStimTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetOStimTrace", value)
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
    ElseIf option == dialogueDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDialogueDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
        MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If controller != None
            controller.UpdatePolling()
        EndIf
    ElseIf option == skyrimNetSexLabTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == sexLabBreastfeedingDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == ostimBreastfeedingOption && MMEOStimBreastfeeding.IsOStimDetected()
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableOStimBreastfeeding", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimBreastfeeding", value)
        SetToggleOptionValue(option, value == 1)
        MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If controller != None
            controller.RefreshOStimDialogueAvailability()
        EndIf
    ElseIf option == ostimDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableOStimDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcDrinkAnimationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == playerDrinkAnimationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerDrinkAnimation", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkDrinkAnimationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == playerHalfFullSelfMilkAnimationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerHalfFullSelfMilkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerHalfFullSelfMilkAnimation", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == playerFullSelfMilkAnimationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerFullSelfMilkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerFullSelfMilkAnimation", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcHalfFullSelfMilkAnimationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCHalfFullSelfMilkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCHalfFullSelfMilkAnimation", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == npcFullSelfMilkAnimationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNPCFullSelfMilkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNPCFullSelfMilkAnimation", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == fullnessSelfMilkAnimationDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableFullnessSelfMilkAnimationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessSelfMilkAnimationDiagnostic", value)
        SetToggleOptionValue(option, value == 1)
    EndIf
    JsonUtil.Save(SettingsFile, False)
EndEvent

Function ToggleArmorSetting(Int option, String settingKey, Int defaultValue)
    Int value = 1 - JsonUtil.GetIntValue(SettingsFile, settingKey, defaultValue)
    JsonUtil.SetIntValue(SettingsFile, settingKey, value)
    SetToggleOptionValue(option, value == 1)
EndFunction

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
    ElseIf option == milkHalfFullNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkHalfFullNarrationCooldown", 60.0))
        SetSliderDialogDefaultValue(60.0)
        SetSliderDialogRange(10.0, 3600.0)
        SetSliderDialogInterval(10.0)
    ElseIf option == playerDrinkNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "playerDrinkNarrationCooldown", 60.0))
        SetSliderDialogDefaultValue(60.0)
        SetSliderDialogRange(10.0, 3600.0)
        SetSliderDialogInterval(10.0)
    ElseIf option == playerDrinkNarrationChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "playerDrinkNarrationChance", 25))
        SetSliderDialogDefaultValue(25.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == milkmaidCreatedNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkmaidCreatedNarrationCooldown", 60.0))
        SetSliderDialogDefaultValue(60.0)
        SetSliderDialogRange(10.0, 3600.0)
        SetSliderDialogInterval(10.0)
    ElseIf option == npcDrinkNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "npcDrinkNarrationCooldown", 60.0))
        SetSliderDialogDefaultValue(60.0)
        SetSliderDialogRange(10.0, 3600.0)
        SetSliderDialogInterval(10.0)
    ElseIf option == npcDrinkAnimationDurationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "npcDrinkAnimationDuration", 3.0))
        SetSliderDialogDefaultValue(3.0)
        SetSliderDialogRange(0.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == playerDrinkAnimationDurationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "playerDrinkAnimationDuration", 3.0))
        SetSliderDialogDefaultValue(3.0)
        SetSliderDialogRange(0.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == playerFullnessSelfMilkAnimationDurationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "playerFullnessSelfMilkAnimationDuration", 3.0))
        SetSliderDialogDefaultValue(3.0)
        SetSliderDialogRange(0.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == npcFullnessSelfMilkAnimationDurationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "npcFullnessSelfMilkAnimationDuration", 3.0))
        SetSliderDialogDefaultValue(3.0)
        SetSliderDialogRange(0.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == ostimBreastfeedingDurationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "ostimBreastfeedingDuration", 20.0))
        SetSliderDialogDefaultValue(20.0)
        SetSliderDialogRange(5.0, 60.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == playerMilkingArmorNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "playerMilkingArmorNarrationCooldown", 120.0))
        SetSliderDialogDefaultValue(120.0)
        SetSliderDialogRange(10.0, 3600.0)
        SetSliderDialogInterval(10.0)
    ElseIf option == npcMilkingArmorNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "npcMilkingArmorNarrationCooldown", 300.0))
        SetSliderDialogDefaultValue(300.0)
        SetSliderDialogRange(10.0, 3600.0)
        SetSliderDialogInterval(10.0)
    ElseIf option == armorStripHeavyThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorStripHeavyPercent", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == armorStripLightThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorStripLightPercent", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == armorStripClothingThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorStripClothingPercent", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == armorStripNarrationChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "armorStripNarrationChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == armorStripNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorStripNarrationCooldown", 300.0) / 60.0)
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(0.0, 60.0)
        SetSliderDialogInterval(5.0)
    EndIf
EndEvent

; Saves accepted slider values and reschedules polling when its interval changes.
Event OnOptionSliderAccept(Int option, Float value)
    ; Slider values are clamped by their dialog ranges. Persist the accepted value
    ; immediately so runtime scripts and subsequent page renders agree.
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
    ElseIf option == milkHalfFullNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "milkHalfFullNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == playerDrinkNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "playerDrinkNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == playerDrinkNarrationChanceOption
        JsonUtil.SetIntValue(SettingsFile, "playerDrinkNarrationChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == milkmaidCreatedNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "milkmaidCreatedNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == npcDrinkNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "npcDrinkNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == npcDrinkAnimationDurationOption
        JsonUtil.SetFloatValue(SettingsFile, "npcDrinkAnimationDuration", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == playerDrinkAnimationDurationOption
        JsonUtil.SetFloatValue(SettingsFile, "playerDrinkAnimationDuration", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == playerFullnessSelfMilkAnimationDurationOption
        JsonUtil.SetFloatValue(SettingsFile, "playerFullnessSelfMilkAnimationDuration", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == npcFullnessSelfMilkAnimationDurationOption
        JsonUtil.SetFloatValue(SettingsFile, "npcFullnessSelfMilkAnimationDuration", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == ostimBreastfeedingDurationOption
        JsonUtil.SetFloatValue(SettingsFile, "ostimBreastfeedingDuration", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == playerMilkingArmorNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "playerMilkingArmorNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == npcMilkingArmorNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "npcMilkingArmorNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == armorStripHeavyThresholdOption
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyPercent", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == armorStripLightThresholdOption
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightPercent", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == armorStripClothingThresholdOption
        JsonUtil.SetFloatValue(SettingsFile, "armorStripClothingPercent", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == armorStripNarrationChanceOption
        JsonUtil.SetIntValue(SettingsFile, "armorStripNarrationChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == armorStripNarrationCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "armorStripNarrationCooldown", value * 60.0)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} minutes")
    EndIf
EndEvent
