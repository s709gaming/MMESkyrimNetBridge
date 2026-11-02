Scriptname MMEAlertsMCM extends SKI_ConfigBase

; ---------------------------------------------------------------------------
; MCM settings schema and migrations
; ---------------------------------------------------------------------------
; JsonUtil is the persistent authority for Extensions settings. Original MME
; shortcuts use MMEOriginalSettings and keep MME itself authoritative.
; JsonUtil is read by runtime scripts. This menu writes
; settings asks only affected controllers to refresh; it must not implement
; gameplay. EnsureDefaults is append-only migration history for existing saves.

String SettingsFile = "/MMEAlerts/Settings"
Int installedBackendOption = -1
Int rosterOpenOption = -1
Int rosterEnabledOption = -1
Int rosterKeyOption = -1
Int narrationReloadOption
Int narrationImportOption
Int reverseDurationOption
Int reversePlayerLevelOption
Int reverseApplyOption
Int reverseRemoveOption
Int reverseTraceOption
Int timedArmorDurationOption
Int timedArmorReleaseOption
Int timedNPCArmorReleaseOption
Int chestArmorTrapOption
Int repeatTrapArmorStoriesOption
Int armorTrapNearbyAlliesOption
Int livingArmorChestTrapOption
Int parasiteArmorChestTrapOption
Int dwemerArmorChestTrapOption
Int dwemerArmorOutsideRuinsOption
Int dwemerRuinArmorTrapChanceOption
Int chestArmorTrapChanceOption
Int chestArmorTrapCooldownOption
Int dungeonChestMilkMaidOption
Int milkMaidTrapNearbyAlliesOption
Int chestCurseNarrationOption
Int milkMaidCurseMasterOption
Int milkMaidCurseSurgeOption
Int dungeonChestMilkMaidChanceOption
Int regularChestMilkMaidOption
Int regularChestMilkMaidChanceOption
Int chestMilkTrapOption
Int milkDrinkTrapNearbyAlliesOption
Int chestMilkTrapChanceOption
Int chestMilkTrapCooldownOption
Int chestMilkTrapVariationOption
Int chestMilkTrapNotificationOption
Int chestMilkTrapNarrationOption
Int innPalaceMilkDrinkingOption
Int guildTavernMilkDrinkingOption
Int jarlResidenceMilkDrinkingOption
Int townMilkDrinkOption
Int townMilkDrinkChanceOption
Int townUniqueNPCPreferenceOption
Int townUniqueNPCPreferenceChanceOption
Int innPalaceDrinkDelayOption
Int innPalaceDrinkVariationOption
Int innPalaceDrinkCooldownOption
Int milkCravingsOption
Int milkCravingNarrationOption
Int milkCravingIntervalOption
Int milkCravingVariationOption
Int milkCravingChanceOption
Int milkCravingGiveInDelayOption
Int autoSelfMilkingOption
Int autoSelfMilkingDelayOption
Int forcedMilkMaidNotificationOption
Int forcedMilkMaidLactacidStoryOption
Int forcedMilkMaidNarrationOption
Int forcedMilkMaidDiagnosticOption
Int movementSlapOption
Int movementSlapVolumeOption
Int movementSlapNotificationsOption
Int movementSlapNotificationCooldownOption
Int flatMilkStrippingOption
Int flatMilkHeavyOption
Int flatMilkLightOption
Int flatMilkClothingOption
Int soundsOption
Int volumeOption
Int capacityOption
Int pollingOption
Int notificationOption
Int pollingIntervalOption
Int breastBounceNotificationOption
Int breastBounceSoundOption
Int breastBounceIntervalOption
Int breastBounceVariationOption
Int breastBounceDelayOption
Int debugMilkReportOption
Int debugMilkingEventsOption
Int milkmaidLevelBonusOption
Int flatMilkBonusOption
Int maidBodyScalingOption
Int maidBodyMaxLevelOption
Int maidBodyHipsOption
Int maidBodyButtOption
Int maidBodyThighsOption
Int maidBodyCalfSizeOption
Int maidBodyWaistOption
Int maidBodyBellyOption
Int maidBodyBigBellyOption
Int maidBodyChubbyArmsOption
Int maidBodyChubbyLegsOption
Int maidBodyChubbyWaistOption
Int maidWeightScalingOption
Int maidWeightPerLevelOption
Int customMilkSpeedDebuffOption
Int milkSpeedMediumThresholdOption
Int milkSpeedMediumPenaltyOption
Int milkSpeedHighThresholdOption
Int milkSpeedHighPenaltyOption
Int maidLevelSpeedScalingOption
Int customMilkWeightOption
Int milkWeightMultiplierOption
Int addMilkDebugOption
Int breastfeedingMilkEffectsOption
Int elsieDetectedOption
Int elsieBreastfeedingMilkEffectsOption
Int estrusTestTypeOption
Int estrusTestRunOption
Int estrusTestResultOption
Int estrusTestType = 0
String estrusTestResult = "Not run"
Int elsieBreastfeedingTestOption
Int breastfeedingMilkEffectsDebugOption
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
Int newMilkMaidMoansOption
Int skyrimNetStatusOption
Int arousalStatusOption
Int milkDrinkArousalOption
Int milkDrinkArousalAmountOption
Int arousalEffectsOption
Int arousalEffectNotificationsOption
Int arousalEffectSoundsOption
Int arousalEffectAnimationsOption
Int arousalMilkMaidRouteOption
Int arousalMilkDrinkRouteOption
Int arousalEveryoneRouteOption
Int arousalEffectDelayOption
Int arousalEffectCooldownOption
Int arousalEffectCooldownVariationOption
Int arousalLowThresholdOption
Int arousalMediumThresholdOption
Int arousalHighThresholdOption
Int sexLabBreastfeedingDebugOption
Int newMilkmaidDialogueTraceOption
Int newMilkmaidSexLabTraceOption
Int blacksmithDialogueTraceOption
Int alchemistDialogueTraceOption
Int mageDialogueTraceOption
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
Int playerMilkMaidConversionOption
Int playerMilkMaidConversionChanceOption
Int giveMilkEasyModeOption
Int nonMilkmaidFemaleDrinkingOption
Int nonMilkmaidFemaleArousalOption
Int nonMilkmaidMaleDrinkingOption
Int nonMilkmaidMaleArousalOption
Int nonMilkmaidDrinkNotificationsOption
Int armorStrippingCheckDiagnosticOption
Int lifecycleDiagnosticOption
Int milkmaidCreationDiagnosticOption
Int nativeScanDiagnosticOption
Int skyrimNetMilkStatusesOption
Int skyrimNetMilkDrinksOption
Int skyrimNetMilkingEventsOption
Int skyrimNetMilkmaidCreatedOption
Int skyrimNetStatusIntervalOption
Int postMilkingNarrationOption
Int postMilkingCooldownOption
Int postMilkingChanceOption
Int fullHistoryOption
Int milkFullNarrationChanceOption
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
Int breastfeedingActionCooldownOption
Int giveMilkActionOption
Int createMilkMaidActionOption
Int giveMilkActionCooldownOption
Int actorDrinkMilkRemovalOption
Int selfMilkingActionDiagnosticOption
Int pairedMilkingActionDiagnosticOption
Int giveMilkActionDiagnosticOption
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
Int armorLookupForensicsOption
Int extensionsArmorStrippingOption
Int milkingEquipmentRefitOption
Int repeatOrdinaryArmorStoriesOption
Int armorStripHeavyEnabledOption
Int armorStripLightEnabledOption
Int armorStripClothingEnabledOption
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
Int stripAllArmorOverrideOption
Int armorCheckReminderOption
Int armorCheckReminderCooldownOption
Int milkMaidThoughtsOption
Int milkMaidThoughtsIntervalOption
Int milkMaidThoughtsRandomnessOption
Int milkMaidThoughtNarrationOption
Int armorThoughtSoundsOption
Int boundMilkMaidThoughtsOption
Int boundMilkMaidThoughtsIntervalOption
Int boundMilkMaidThoughtsRandomnessOption
Int boundMilkMaidThoughtsChanceOption
Int boundMilkMaidThoughtNarrationOption
Int boundMilkMaidThoughtNarrationChanceOption
Int boundMilkMaidThoughtSoundsOption
Int boundMilkDrinkReactionOption
Int boundMilkDrinkReactionChanceOption
Int milkMaidThoughtsDebugOption
Int traceMilkMaidThoughtsLogicOption
Int[] tentacleChanceOptions
Int[] tentacleDurationOptions

Int armorInjectionOption
Int armorInjectionIntervalOption
Int armorInjectionVariationOption
Int armorInjectionChanceOption
Int armorInjectionNotificationOption
Int armorInjectionSoundOption
Int armorInjectionDiagnosticOption
Int armorInjectionNarrationOption
Int armorInjectionPlayerNarrationOption
Int armorInjectionNarrationChanceOption
Int dwemerEffectOption
Int dwemerEffectIntervalOption
Int dwemerEffectVariationOption
Int dwemerEffectChanceOption
Int dwemerEffectNotificationOption
Int dwemerEffectSoundOption
Int dwemerEffectDiagnosticOption
Int dwemerEffectNarrationOption
Int dwemerEffectPlayerNarrationOption
Int dwemerEffectNarrationChanceOption
Int runDwemerEffectCheckOption
Int runArmorInjectionCheckOption
Int diagnosticNotificationsOption
Int papyrusTraceOption
Int verbosePapyrusTraceOption
Int diagnosticRefreshGateOption
Int diagnosticInstallAuditOption
Int diagnosticMilkDrinkAuditOption
Int diagnosticSpawnOManiaPotionOption
Int diagnosticGlobalNPCDrinkTestOption
Int diagnosticDialogueAuditOption
Int diagnosticNewMilkmaidSexLabBusOption
Int diagnosticRefreshSexLabBusOption
Int diagnosticShowSexLabBusOption
Int diagnosticBlacksmithBusOption
Int diagnosticShowBlacksmithBusOption
Int diagnosticAlchemistBusOption
Int diagnosticShowAlchemistBusOption
Int diagnosticMageBusOption
Int diagnosticShowMageBusOption
Int diagnosticInstallStatusOption
Int diagnosticOStimStatusOption
Int diagnosticSexLabStatusOption
Int diagnosticGateStatusOption
Int diagnosticSexLabBusStateOption
Int diagnosticSexLabBusStopOption
Int diagnosticSexLabBusFailureOption
Int diagnosticBlacksmithBusStateOption
Int diagnosticBlacksmithBusStopOption
Int diagnosticBlacksmithBusFailureOption
Int diagnosticAlchemistBusStateOption
Int diagnosticAlchemistBusStopOption
Int diagnosticAlchemistBusFailureOption
Int diagnosticMageBusStateOption
Int diagnosticMageBusStopOption
Int diagnosticMageBusFailureOption

; SkyUI uses this version to run settings migrations on existing saves.
Int Function GetVersion()
    Return 172
EndFunction

Function SetPageNames()
    Pages = new String[11]
    Pages[0] = MMELocalization.Text("General")
    Pages[1] = MMELocalization.Text("Milk Drinking")
    ; Runtime spelling preserves SkyUI capitalization despite Papyrus interning.
    Pages[2] = MMELocalization.Text("Body ")
    Pages[3] = MMELocalization.Text("Arousal ")
    Pages[4] = MMELocalization.Text("Armor & Stripping")
    Pages[5] = MMELocalization.Text("Armor Effects")
    Pages[6] = MMELocalization.Text("Armor Reactions")
    Pages[7] = MMELocalization.Text("Traps & Curses")
    Pages[8] = MMELocalization.Text("Skyrim.Net")
    Pages[9] = MMELocalization.Text("Debug")
    Pages[10] = MMELocalization.Text("Troubleshoot")
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
    MMELocalization.Initialize()
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
    MMEPostMilking.EnsureDefaults()
    MMEFixedLactacid.EnsureDefaults()
    MMEMilkLeakAPI.EnsureDefaults()
    MMETentacleTiers.Configure()
    If !JsonUtil.HasIntValue(SettingsFile, "enableChestCurseNarration")
        JsonUtil.SetIntValue(SettingsFile, "enableChestCurseNarration", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If !JsonUtil.HasIntValue(SettingsFile, "enableMilkMaidCurseTrap")
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidCurseTrap", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If !JsonUtil.HasIntValue(SettingsFile, "milkMaidCurseSurgePercent")
        JsonUtil.SetIntValue(SettingsFile, "milkMaidCurseSurgePercent", 50)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "maidRosterMigration160", 0) == 0
        If !JsonUtil.HasIntValue(SettingsFile, "maidRosterUiEnabled")
            JsonUtil.SetIntValue(SettingsFile, "maidRosterUiEnabled", 1)
        EndIf
        If !JsonUtil.HasIntValue(SettingsFile, "maidRosterHotkey")
            JsonUtil.SetIntValue(SettingsFile, "maidRosterHotkey", -1)
        EndIf
        JsonUtil.SetIntValue(SettingsFile, "maidRosterMigration160", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf

    ; Safe opt-in migration for both new games and existing saves.
    If JsonUtil.GetIntValue(SettingsFile, "maidBodyScalingMigration158", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMaidBodyScaling", 0)
        JsonUtil.SetIntValue(SettingsFile, "maidBodyScalingMaxLevel", 100)
        JsonUtil.SetIntValue(SettingsFile, "maidBodyScalingRevision", 0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphHips", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphButt", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphThighs", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphCalfSize", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphWaist", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphBelly", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphBigBelly", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphChubbyArms", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphChubbyLegs", 0.0)
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphChubbyWaist", 0.0)
        JsonUtil.SetIntValue(SettingsFile, "maidBodyScalingMigration158", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; New installations enter the first-version defaults block. Later blocks are
    ; individually guarded migrations so upgrades never overwrite user choices.
    If !JsonUtil.IsPendingSave(SettingsFile) && JsonUtil.GetIntValue(SettingsFile, "initialized", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "initialized", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMMEExtensions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableReactionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableFullnessMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkMaidMoans", 1)
        JsonUtil.SetFloatValue(SettingsFile, "reactionSoundVolume", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityReactions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", 1)
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDungeonChestMilkMaid", 1)
        JsonUtil.SetIntValue(SettingsFile, "dungeonChestMilkMaidChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "enableRegularChestMilkMaid", 1)
        JsonUtil.SetIntValue(SettingsFile, "regularChestMilkMaidChance", 10)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "chestMilkTrapChance", 33)
        JsonUtil.SetFloatValue(SettingsFile, "chestMilkTrapCooldownHours", 1.0)
        JsonUtil.SetFloatValue(SettingsFile, "chestMilkTrapCooldownVariation", 0.0)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrapNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrapNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestArmorTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableRepeatTrapArmorStories", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableLivingArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableParasiteArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDwemerArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDwemerArmorOutsideRuins", 0)
        JsonUtil.SetIntValue(SettingsFile, "dwemerRuinArmorTrapChance", 25)
        JsonUtil.SetIntValue(SettingsFile, "chestArmorTrapChance", 5)
        JsonUtil.SetFloatValue(SettingsFile, "chestArmorTrapCooldownHours", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "chestArmorTrapMigration137", 1)
        JsonUtil.SetIntValue(SettingsFile, "repeatTrapArmorStoriesMigration150", 1)
        JsonUtil.SetIntValue(SettingsFile, "chestArmorCategoryMigration138", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "chestNearbyAlliesMigration140", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableInnPalaceMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableGuildTavernMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableJarlResidenceMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableTownMilkDrink", 1)
        JsonUtil.SetIntValue(SettingsFile, "townMilkDrinkChance", 25)
        JsonUtil.SetIntValue(SettingsFile, "enableTownUniqueNPCPreference", 1)
        JsonUtil.SetIntValue(SettingsFile, "townUniqueNPCPreferenceChance", 75)
        JsonUtil.SetIntValue(SettingsFile, "townUniqueNPCPreferenceMigration139", 1)
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkDelaySeconds", 11.0)
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkDelayVariation", 10.0)
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkCooldownHours", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "innPalaceDrinkMigration130", 1)
        JsonUtil.SetIntValue(SettingsFile, "townMilkDrinkMigration132", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkCravings", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkCravingNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingIntervalHours", 48.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingIntervalVariation", 24.0)
        JsonUtil.SetIntValue(SettingsFile, "milkCravingTriggerChance", 100)
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingGiveInDelayHours", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "milkCravingMigration133", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableAutoSelfMilking", 1)
        JsonUtil.SetFloatValue(SettingsFile, "autoSelfMilkingDelayHours", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "autoSelfMilkingMigration134", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidStory", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEventDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1)
        JsonUtil.SetFloatValue(SettingsFile, "flatMilkBonus", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMaidLevelWeightScaling", 1)
        JsonUtil.SetFloatValue(SettingsFile, "maidWeightPerLevel", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCustomMilkSpeedDebuff", 0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedMediumThreshold", 50.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedMediumPenalty", 3.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedHighThreshold", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedHighPenalty", 10.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMaidLevelSpeedScaling", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableCustomMilkWeight", 0)
        JsonUtil.SetFloatValue(SettingsFile, "milkWeightMultiplier", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "bodyEffectsMigration155", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEquipmentRefits", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableRepeatOrdinaryArmorStories", 1)
        JsonUtil.SetIntValue(SettingsFile, "repeatOrdinaryArmorStoriesMigration151", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableAddMilkDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastfeedingMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableElsieBreastfeedingMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastfeedingMilkEffectsDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "breastfeedingMilkEffectsMigration86", 1)
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
        JsonUtil.SetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingAction", 1)
        JsonUtil.SetFloatValue(SettingsFile, "breastfeedingActionCooldown", 45.0)
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCreateMilkMaidAction", 1)
        JsonUtil.SetFloatValue(SettingsFile, "giveMilkActionCooldown", 0.0)
        JsonUtil.SetIntValue(SettingsFile, "enableActorDrinkMilkRemoval", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSelfMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePairedMilkingActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimBreastfeeding", MMEOStimBreastfeeding.IsOStimDetected() as Int)
        JsonUtil.SetFloatValue(SettingsFile, "ostimBreastfeedingDuration", 20.0)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "ostimBreastfeedingMigration70", 1)
        SetArmorReactionDefaults()
        JsonUtil.SetIntValue(SettingsFile, "milkingArmorMigration71", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilk", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVoiceGiveMilkDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkFullNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkFullNarrationCooldown", 120.0)
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
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectAnimations", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalMilkMaidRoute", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalMilkDrinkRoute", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEveryoneRoute", 0)
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectDelay", 5.0)
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectCooldown", 5.0)
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectCooldownVariation", 0.0)
        JsonUtil.SetIntValue(SettingsFile, "arousalLowThreshold", 20)
        JsonUtil.SetIntValue(SettingsFile, "arousalMediumThreshold", 50)
        JsonUtil.SetIntValue(SettingsFile, "arousalHighThreshold", 80)
        JsonUtil.SetIntValue(SettingsFile, "arousalEffectsMigration147", 1)
        JsonUtil.SetIntValue(SettingsFile, "arousalMonitorDefaultsMigration148", 1)
        JsonUtil.SetIntValue(SettingsFile, "arousalAnimationsMigration152", 1)
        JsonUtil.SetIntValue(SettingsFile, "arousalEligibilityMigration154", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkmaidDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkmaidSexLabTrace", 0)
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
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkMaidConversion", 1)
        JsonUtil.SetIntValue(SettingsFile, "playerMilkMaidConversionChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorOverflowDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyPercent", 70.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightPercent", 85.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripClothingPercent", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoan", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorStripNarrationChance", 100)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripNarrationCooldown", 300.0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNotificationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripMoanDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripNarrationDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableStripAllArmor", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorCheckReminder", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorCheckReminderMigration101", 1)
        JsonUtil.SetFloatValue(SettingsFile, "armorCheckReminderCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "armorCheckReminderCooldownMigration102", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorCheckReminderCooldownMigration103", 1)
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
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughts", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkMaidThoughtsInterval", 12.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkMaidThoughtsRandomness", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "mirrorMilkMaidThoughtsToSkyrimNet", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorThoughtSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorThoughtSoundsMigration94", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughts", 1)
        JsonUtil.SetFloatValue(SettingsFile, "boundMilkMaidThoughtsInterval", 24.0)
        JsonUtil.SetFloatValue(SettingsFile, "boundMilkMaidThoughtsRandomness", 12.0)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtsChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtsMigration122", 1)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtsChanceMigration123", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughtNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationMigration124", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughtSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtSoundsMigration125", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkDrinkReaction", 1)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkDrinkReactionChance", 50)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkDrinkReactionMigration131", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "traceMilkMaidThoughtsLogic", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkMaidThoughtsMigration87", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjections", 1)
        JsonUtil.SetFloatValue(SettingsFile, "armorInjectionInterval", 12.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorInjectionVariation", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionMigration104", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationMigration105", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationMigration106", 1)
        SetDwemerEffectDefaults()
        JsonUtil.SetIntValue(SettingsFile, "dwemerEffectMigration135", 1)
        JsonUtil.SetFloatValue(SettingsFile, "timedArmorLockDays", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "timedArmorMigration136", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDiagnosticNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDiagnosticPapyrusTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "diagnosticsPageMigration91", 1)
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
        JsonUtil.SetFloatValue(SettingsFile, "milkFullNarrationCooldown", 120.0)
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
        JsonUtil.SetIntValue(SettingsFile, "releaseDefaultsMigration51", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Applies quieter release defaults once without overriding later player choices.
    If JsonUtil.GetIntValue(SettingsFile, "quietDiagnosticsMigration32", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "quietDiagnosticsMigration32", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "npcDrinkAnimationMigration31", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNPCDrinkAnimation", 1)
        JsonUtil.SetIntValue(SettingsFile, "npcDrinkAnimationMigration31", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "arousalIntegrationMigration27", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 20.0)
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
        JsonUtil.SetFloatValue(SettingsFile, "breastfeedingActionCooldown", 45.0)
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
    ; capacity-poll stripping for the player. Defaults reflect armor weight.
    If JsonUtil.GetIntValue(SettingsFile, "armorStrippingFeatureMigration80", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyPercent", 70.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightPercent", 85.0)
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
    ; The stripping thresholds are now fullness percentages. Establish 70/85/100
    ; once for saves that already carried the earlier absolute keys; the old
    ; absolute keys are left inert and are no longer read anywhere.
    If JsonUtil.GetIntValue(SettingsFile, "armorStrippingPercentMigration82", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyPercent", 70.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightPercent", 85.0)
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
    ; Strip All Armor override: brand-new diagnostic toggle. Seeding once keeps
    ; the schema explicit for existing saves while never overwriting later
    ; user choices.
    If JsonUtil.GetIntValue(SettingsFile, "armorArrayCheckMigration84", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableStripAllArmor", 0)
        JsonUtil.SetIntValue(SettingsFile, "armorArrayCheckMigration84", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Point-in-time armor lookup forensics: log-only diagnostic toggle proving
    ; exactly which array entry a protection/classification decision matched.
    ; Default OFF; Papyrus log output only, never a HUD notification.
    If JsonUtil.GetIntValue(SettingsFile, "armorLookupForensicsMigration85", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorLookupForensics", 0)
        JsonUtil.SetIntValue(SettingsFile, "armorLookupForensicsMigration85", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the optional scene-completion milk/arousal effect. It starts enabled
    ; for both new and existing installations; its dedicated diagnostic is quiet.
    If JsonUtil.GetIntValue(SettingsFile, "breastfeedingMilkEffectsMigration86", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBreastfeedingMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastfeedingMilkEffectsDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "breastfeedingMilkEffectsMigration86", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds ambient Thoughts and the rapid shared-scan debug hook. Each value is
    ; seeded once so existing user choices remain
    ; untouched on all later MCM updates.
    If JsonUtil.GetIntValue(SettingsFile, "milkMaidThoughtsMigration87", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughts", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkMaidThoughtsInterval", 12.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkMaidThoughtsRandomness", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "mirrorMilkMaidThoughtsToSkyrimNet", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkMaidThoughtsMigration87", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkMaidThoughtsTraceMigration88", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "traceMilkMaidThoughtsLogic", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkMaidThoughtsTraceMigration88", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Category toggles are additive. Existing saves retain their threshold
    ; choices, while fresh saves inherit the stratified defaults above.
    If JsonUtil.GetIntValue(SettingsFile, "armorStripCategoriesMigration142", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripHeavy", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripLight", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripClothing", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorStripCategoriesMigration142", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf

    If JsonUtil.GetIntValue(SettingsFile, "chestArmorCategoryMigration138", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableLivingArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableParasiteArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDwemerArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "chestArmorCategoryMigration138", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds a Skyrim.Net-only recursion guard without changing dialogue access.
    If JsonUtil.GetIntValue(SettingsFile, "breastfeedingActionCooldownMigration89", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "breastfeedingActionCooldown", 45.0)
        JsonUtil.SetIntValue(SettingsFile, "breastfeedingActionCooldownMigration89", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Preserve the user's former mirror choice while upgrading the output from a
    ; short-lived context event to token-using direct narration.
    If JsonUtil.GetIntValue(SettingsFile, "milkMaidThoughtNarrationMigration90", 0) == 0
        Int previousMirrorValue = JsonUtil.GetIntValue(SettingsFile, "mirrorMilkMaidThoughtsToSkyrimNet", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughtNarration", previousMirrorValue)
        JsonUtil.SetIntValue(SettingsFile, "milkMaidThoughtNarrationMigration90", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds a focused, player-triggered audit page. HUD summaries start on while
    ; the more verbose Papyrus trace remains explicitly opt-in.
    If JsonUtil.GetIntValue(SettingsFile, "diagnosticsPageMigration91", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDiagnosticNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDiagnosticPapyrusTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "diagnosticsPageMigration91", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Dedicated breadcrumb trail for the breastfeeding-to-Milk-Maid route.
    ; It is intentionally independent of the broad OStim diagnostic.
    If JsonUtil.GetIntValue(SettingsFile, "newMilkmaidDialogueTraceMigration92", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkmaidDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "newMilkmaidDialogueTraceMigration92", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "newMilkmaidSexLabTraceMigration93", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkmaidSexLabTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "newMilkmaidSexLabTraceMigration93", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds an independent default-on sound gate for Armor Thoughts while the
    ; existing reaction-sound setting remains the global master switch.
    If JsonUtil.GetIntValue(SettingsFile, "armorThoughtSoundsMigration94", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorThoughtSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorThoughtSoundsMigration94", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds an opt-in live breadcrumb trail plus the read-only Troubleshoot bus.
    If JsonUtil.GetIntValue(SettingsFile, "blacksmithDialogueTraceMigration98", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBlacksmithDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "blacksmithDialogueTraceMigration98", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "alchemistDialogueTraceMigration99", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableAlchemistDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "alchemistDialogueTraceMigration99", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "mageDialogueTraceMigration100", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMageDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "mageDialogueTraceMigration100", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the default-on, notification-only service armor reminder. Expected
    ; eligibility skips stay silent; unexpected stops are Papyrus-log only.
    If JsonUtil.GetIntValue(SettingsFile, "armorCheckReminderMigration101", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorCheckReminder", 1)
        JsonUtil.SetIntValue(SettingsFile, "armorCheckReminderMigration101", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Replaces the unreliable dialogue-menu session guard with a predictable
    ; real-time cooldown while preserving the reminder toggle on existing saves.
    If JsonUtil.GetIntValue(SettingsFile, "armorCheckReminderCooldownMigration102", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "armorCheckReminderCooldown", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "armorCheckReminderCooldownMigration102", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; The original 15-second value could repeat during one long conversation.
    ; Upgrade existing installations to the safer one-minute default.
    If JsonUtil.GetIntValue(SettingsFile, "armorCheckReminderCooldownMigration103", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "armorCheckReminderCooldown", 60.0)
        JsonUtil.SetIntValue(SettingsFile, "armorCheckReminderCooldownMigration103", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the local Living/Parasite armor gameplay and notification system.
    ; Narration is initialized separately without resetting these gameplay settings.
    If JsonUtil.GetIntValue(SettingsFile, "armorInjectionMigration104", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjections", 1)
        JsonUtil.SetFloatValue(SettingsFile, "armorInjectionInterval", 12.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorInjectionVariation", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionMigration104", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "armorInjectionNarrationMigration105", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionNarration", JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionNarration", 1))
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationChance", JsonUtil.GetIntValue(SettingsFile, "armorInjectionNarrationChance", 10))
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationMigration105", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "armorInjectionSoundsMigration108", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionSounds", JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionSounds", 1))
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionSoundsMigration108", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "armorInjectionPlayerNarrationMigration107", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionPlayerNarration", JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionPlayerNarration", 1))
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionPlayerNarrationMigration107", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Raise the former 10% default without overwriting a custom percentage.
    If JsonUtil.GetIntValue(SettingsFile, "armorInjectionNarrationMigration106", 0) == 0
        If JsonUtil.GetIntValue(SettingsFile, "armorInjectionNarrationChance", 10) == 10
            JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationChance", 100)
        EndIf
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationMigration106", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Master/subsystem Papyrus tracing for the post-dialogue vendor animation bus.
    If JsonUtil.GetIntValue(SettingsFile, "vendorAnimationTraceMigration111", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enablePapyrusTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVerbosePapyrusLogging", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVendorAnimationTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "vendorAnimationTraceMigration111", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds a shared parent gate for routine, problem-specific Papyrus output.
    ; Existing feature trace choices are preserved but remain inert until both
    ; logging parents are enabled.
    If JsonUtil.GetIntValue(SettingsFile, "specificDiagnosticTraceMigration112", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableSpecificDiagnosticTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "specificDiagnosticTraceMigration112", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Opt-in timestamp chain for the Give Milk dialogue. This does not alter
    ; dialogue, inventory, effects, or animation behavior.
    If JsonUtil.GetIntValue(SettingsFile, "milkDialogueTimingTraceMigration113", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDialogueTimingTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "milkDialogueTimingTraceMigration113", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Give Milk no longer uses Lactacid. Existing saves receive the requested
    ; default-on fallback that supplies one temporary HearthFires Jug.
    If JsonUtil.GetIntValue(SettingsFile, "giveMilkEasyModeMigration114", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkEasyMode", 1)
        JsonUtil.SetIntValue(SettingsFile, "giveMilkEasyModeMigration114", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Universal Give Milk remains isolated from MME Milkmaid storage/effects.
    ; These settings only govern eligible adult non-Milkmaid receivers.
    If JsonUtil.GetIntValue(SettingsFile, "universalNPCDrinkMigration115", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableNonMilkmaidFemaleDrinking", 1)
        JsonUtil.SetFloatValue(SettingsFile, "nonMilkmaidFemaleArousal", 20.0)
        JsonUtil.SetIntValue(SettingsFile, "enableNonMilkmaidMaleDrinking", 1)
        JsonUtil.SetFloatValue(SettingsFile, "nonMilkmaidMaleArousal", 20.0)
        JsonUtil.SetIntValue(SettingsFile, "enableNonMilkmaidDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "universalNPCDrinkMigration115", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the static Skyrim.Net player-to-speaker Give Milk action. Its own
    ; cooldown is independent from drink narration and breastfeeding actions.
    If JsonUtil.GetIntValue(SettingsFile, "giveMilkActionMigration116", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkAction", 1)
        JsonUtil.SetFloatValue(SettingsFile, "giveMilkActionCooldown", 0.0)
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "giveMilkActionMigration116", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Generalizes Give Milk to speaker/target actor pairs. The HearthFires Jug
    ; remains the universal baseline; confirmed Milkmaid givers may fund it
    ; from one unit of MilkCurrent with transactional rollback on failure.
    If JsonUtil.GetIntValue(SettingsFile, "actorDrinkMigration117", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableActorDrinkMilkRemoval", 1)
        JsonUtil.SetIntValue(SettingsFile, "actorDrinkMigration117", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adopt the quieter repeat-action policy and stronger arousal defaults once,
    ; without overwriting values a player already customized away from the old defaults.
    If JsonUtil.GetIntValue(SettingsFile, "drinkBalanceDefaultsMigration118", 0) == 0
        If JsonUtil.GetFloatValue(SettingsFile, "giveMilkActionCooldown", 45.0) == 45.0
            JsonUtil.SetFloatValue(SettingsFile, "giveMilkActionCooldown", 0.0)
        EndIf
        If JsonUtil.GetFloatValue(SettingsFile, "milkDrinkArousal", 10.0) == 10.0
            JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 20.0)
        EndIf
        If JsonUtil.GetFloatValue(SettingsFile, "nonMilkmaidFemaleArousal", 10.0) == 10.0
            JsonUtil.SetFloatValue(SettingsFile, "nonMilkmaidFemaleArousal", 20.0)
        EndIf
        If JsonUtil.GetFloatValue(SettingsFile, "nonMilkmaidMaleArousal", 10.0) == 10.0
            JsonUtil.SetFloatValue(SettingsFile, "nonMilkmaidMaleArousal", 20.0)
        EndIf
        JsonUtil.SetIntValue(SettingsFile, "drinkBalanceDefaultsMigration118", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Enables the static, runtime-validated Skyrim.Net conversion action on
    ; existing saves without changing any original MME dialogue settings.
    If JsonUtil.GetIntValue(SettingsFile, "createMilkMaidActionMigration120", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableCreateMilkMaidAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "createMilkMaidActionMigration120", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Extend MME's native Lactacid creation behavior to recognized ordinary
    ; player milk drinks. Existing saves receive the requested default-on 100%.
    If JsonUtil.GetIntValue(SettingsFile, "playerMilkMaidConversionMigration121", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkMaidConversion", 1)
        JsonUtil.SetIntValue(SettingsFile, "playerMilkMaidConversionChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "playerMilkMaidConversionMigration121", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the optional DD heavy-bondage Thought sibling. Its production
    ; schedule is independent and defaults to one attempt every 24 +/- 12 game
    ; hours; DD absence makes the schedule inert without a hard dependency.
    If JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtsMigration122", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughts", 1)
        JsonUtil.SetFloatValue(SettingsFile, "boundMilkMaidThoughtsInterval", 24.0)
        JsonUtil.SetFloatValue(SettingsFile, "boundMilkMaidThoughtsRandomness", 12.0)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtsMigration122", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds a separately adjustable roll to the bound route. Existing saves get
    ; the requested default-on behavior without changing their saved schedule.
    If JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtsChanceMigration123", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtsChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtsChanceMigration123", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Separates the local bound Thought from its optional Skyrim.Net reaction.
    ; Existing saves keep the previous behavior: narration enabled at 100%.
    If JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationMigration124", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughtNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationMigration124", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds an independent default-on moan gate for the heavy-restraint Thought.
    ; The global Reaction Sounds toggle remains the master sound switch.
    If JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtSoundsMigration125", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughtSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtSoundsMigration125", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds one-shot forced conversion traps to curated vanilla/DLC dungeon boss
    ; chests. Existing saves receive the requested default-on 100% behavior.
    If JsonUtil.GetIntValue(SettingsFile, "dungeonChestMilkMaidMigration126", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDungeonChestMilkMaid", 1)
        JsonUtil.SetIntValue(SettingsFile, "dungeonChestMilkMaidChance", 100)
        JsonUtil.SetIntValue(SettingsFile, "dungeonChestMilkMaidMigration126", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Extends forced conversion feedback and adds a separately controlled 10%
    ; one-shot roll for curated ordinary vanilla/DLC treasure chests.
    If JsonUtil.GetIntValue(SettingsFile, "forcedMilkMaidFeedbackMigration127", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableRegularChestMilkMaid", 1)
        JsonUtil.SetIntValue(SettingsFile, "regularChestMilkMaidChance", 10)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidLactacidStory", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "forcedMilkMaidFeedbackMigration127", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Replaces the drink-specific forced story with trigger-neutral prose and
    ; adds one shared high conversion moan for every confirmed creation route.
    If JsonUtil.GetIntValue(SettingsFile, "newMilkMaidFeedbackMigration128", 0) == 0
        Int previousStoryValue = JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidLactacidStory", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidStory", previousStoryValue)
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkMaidMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "newMilkMaidFeedbackMigration128", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the shared boss/regular exotic-milk chest trap. Failed rolls do not
    ; consume its game-time cooldown; verified forced drinks do.
    If JsonUtil.GetIntValue(SettingsFile, "chestMilkTrapMigration129", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "chestMilkTrapChance", 33)
        JsonUtil.SetFloatValue(SettingsFile, "chestMilkTrapCooldownHours", 1.0)
        JsonUtil.SetFloatValue(SettingsFile, "chestMilkTrapCooldownVariation", 0.0)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrapNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrapNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "chestMilkTrapMigration129", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds delayed normal-milk drinks on entry to inns, the three curated
    ; guild/tavern spaces and the nine vanilla jarl residences.
    If JsonUtil.GetIntValue(SettingsFile, "innPalaceDrinkMigration130", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableInnPalaceMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableGuildTavernMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableJarlResidenceMilkDrinking", 1)
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkDelaySeconds", 11.0)
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkDelayVariation", 10.0)
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkCooldownHours", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "innPalaceDrinkMigration130", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds an independent drink-triggered caller of the complete heavy-restraint
    ; reaction. It has its own chance and does not consume or alter the hourly
    ; bound Thought schedule.
    If JsonUtil.GetIntValue(SettingsFile, "boundMilkDrinkReactionMigration131", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkDrinkReaction", 1)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkDrinkReactionChance", 50)
        JsonUtil.SetIntValue(SettingsFile, "boundMilkDrinkReactionMigration131", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds a broad city-location entry roll. City interiors are intentionally
    ; accepted, and the transaction shares the inn/palace timer and cooldown.
    If JsonUtil.GetIntValue(SettingsFile, "townMilkDrinkMigration132", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableTownMilkDrink", 1)
        JsonUtil.SetIntValue(SettingsFile, "townMilkDrinkChance", 25)
        JsonUtil.SetIntValue(SettingsFile, "townMilkDrinkMigration132", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds the two-stage, game-time Milk Maid craving cycle. Existing saves
    ; receive the same enabled defaults as a fresh installation.
    If JsonUtil.GetIntValue(SettingsFile, "milkCravingMigration133", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkCravings", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkCravingNarration", 1)
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingIntervalHours", 48.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingIntervalVariation", 24.0)
        JsonUtil.SetIntValue(SettingsFile, "milkCravingTriggerChance", 100)
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingGiveInDelayHours", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "milkCravingMigration133", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Connects the existing Milk Full crossing to MME's own MilkSelf spell
    ; after a configurable game-time delay. No duplicate milking implementation
    ; or narration channel is introduced.
    If JsonUtil.GetIntValue(SettingsFile, "autoSelfMilkingMigration134", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableAutoSelfMilking", 1)
        JsonUtil.SetFloatValue(SettingsFile, "autoSelfMilkingDelayHours", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "autoSelfMilkingMigration134", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "dwemerEffectMigration135", 0) == 0
        SetDwemerEffectDefaults()
        JsonUtil.SetIntValue(SettingsFile, "dwemerEffectMigration135", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "timedArmorMigration136", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "timedArmorLockDays", 3.0)
        JsonUtil.SetIntValue(SettingsFile, "timedArmorMigration136", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "chestArmorTrapMigration137", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableChestArmorTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDwemerArmorOutsideRuins", 0)
        JsonUtil.SetIntValue(SettingsFile, "dwemerRuinArmorTrapChance", 25)
        JsonUtil.SetIntValue(SettingsFile, "chestArmorTrapChance", 5)
        JsonUtil.SetFloatValue(SettingsFile, "chestArmorTrapCooldownHours", 4.0)
        JsonUtil.SetIntValue(SettingsFile, "chestArmorTrapMigration137", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Favors named, unique NPCs over generic actors for town-entry drinks while
    ; preserving a safe fallback to whichever eligible pool is available.
    If JsonUtil.GetIntValue(SettingsFile, "townUniqueNPCPreferenceMigration139", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableTownUniqueNPCPreference", 1)
        JsonUtil.SetIntValue(SettingsFile, "townUniqueNPCPreferenceChance", 75)
        JsonUtil.SetIntValue(SettingsFile, "townUniqueNPCPreferenceMigration139", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds independent player-only targeting controls for all three treasure-
    ; chest outcomes. Existing saves retain the established nearby-ally behavior.
    If JsonUtil.GetIntValue(SettingsFile, "chestNearbyAlliesMigration140", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArmorTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "chestNearbyAlliesMigration140", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "maidWeightScalingMigration143", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMaidLevelWeightScaling", 1)
        JsonUtil.SetFloatValue(SettingsFile, "maidWeightPerLevel", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "maidWeightScalingMigration143", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "milkingEquipmentRefitMigration144", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEquipmentRefits", 1)
        JsonUtil.SetIntValue(SettingsFile, "milkingEquipmentRefitMigration144", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Optional Elsie scenes use the established breastfeeding transaction but
    ; retain an independent, default-on control for existing saves.
    If JsonUtil.GetIntValue(SettingsFile, "elsieBreastfeedingMigration145", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableElsieBreastfeedingMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "elsieBreastfeedingMigration145", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Consolidates the four former developer-facing trace categories behind one
    ; high-volume switch. Preserve an explicitly enabled legacy category once.
    If JsonUtil.GetIntValue(SettingsFile, "verbosePapyrusLoggingMigration146", 0) == 0
        Int verboseLogging = 0
        If JsonUtil.GetIntValue(SettingsFile, "enableSpecificDiagnosticTrace", 0) == 1 \
        || JsonUtil.GetIntValue(SettingsFile, "enableDiagnosticPapyrusTrace", 0) == 1 \
        || JsonUtil.GetIntValue(SettingsFile, "enableVendorAnimationTrace", 0) == 1 \
        || JsonUtil.GetIntValue(SettingsFile, "enableMilkDialogueTimingTrace", 0) == 1
            verboseLogging = 1
        EndIf
        JsonUtil.SetIntValue(SettingsFile, "enableVerbosePapyrusLogging", verboseLogging)
        JsonUtil.SetIntValue(SettingsFile, "verbosePapyrusLoggingMigration146", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds nearby adult arousal-threshold notifications and sex-aware sounds.
    ; Presentation is crossing-based and intentionally contains no animation or
    ; Skyrim.Net behavior in this release.
    If JsonUtil.GetIntValue(SettingsFile, "arousalEffectsMigration147", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectSounds", 1)
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectCooldown", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "arousalLowThreshold", 20)
        JsonUtil.SetIntValue(SettingsFile, "arousalMediumThreshold", 50)
        JsonUtil.SetIntValue(SettingsFile, "arousalHighThreshold", 80)
        JsonUtil.SetIntValue(SettingsFile, "arousalEffectsMigration147", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Arousal Reactions is an observational monitor. Milk drinking retains its
    ; separate, modest compatibility boost.
    If JsonUtil.GetIntValue(SettingsFile, "arousalMonitorDefaultsMigration148", 0) == 0
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 10.0)
        JsonUtil.SetIntValue(SettingsFile, "arousalMonitorDefaultsMigration148", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Correct the short-lived zero-default build without changing any nonzero
    ; value a player deliberately configured.
    If JsonUtil.GetIntValue(SettingsFile, "milkDrinkArousalDefaultMigration149", 0) == 0
        If JsonUtil.GetFloatValue(SettingsFile, "milkDrinkArousal", 10.0) == 0.0
            JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", 10.0)
        EndIf
        JsonUtil.SetIntValue(SettingsFile, "milkDrinkArousalDefaultMigration149", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "repeatTrapArmorStoriesMigration150", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableRepeatTrapArmorStories", 1)
        JsonUtil.SetIntValue(SettingsFile, "repeatTrapArmorStoriesMigration150", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "repeatOrdinaryArmorStoriesMigration151", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableRepeatOrdinaryArmorStories", 1)
        JsonUtil.SetIntValue(SettingsFile, "repeatOrdinaryArmorStoriesMigration151", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Adds registered three-second arousal clips without changing the existing
    ; threshold, notification, sound, selection, or cooldown defaults.
    If JsonUtil.GetIntValue(SettingsFile, "arousalAnimationsMigration152", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectAnimations", 1)
        JsonUtil.SetIntValue(SettingsFile, "arousalAnimationsMigration152", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "breastBounceEffectsMigration153", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableBreastBounceNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastBounceSounds", 1)
        JsonUtil.SetFloatValue(SettingsFile, "breastBounceIntervalHours", 24.0)
        JsonUtil.SetFloatValue(SettingsFile, "breastBounceVariationHours", 4.0)
        JsonUtil.SetFloatValue(SettingsFile, "breastBounceMaximumDelaySeconds", 30.0)
        JsonUtil.SetIntValue(SettingsFile, "breastBounceEffectsMigration153", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Restricts ordinary nearby reactions to Milk Maids while allowing any
    ; recognized milk drink to qualify when it directly crosses a threshold.
    If JsonUtil.GetIntValue(SettingsFile, "arousalEligibilityMigration154", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableArousalMilkMaidRoute", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalMilkDrinkRoute", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEveryoneRoute", 0)
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectDelay", 5.0)
        If JsonUtil.GetFloatValue(SettingsFile, "arousalEffectCooldown", 15.0) == 15.0
            JsonUtil.SetFloatValue(SettingsFile, "arousalEffectCooldown", 5.0)
        EndIf
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectCooldownVariation", 0.0)
        JsonUtil.SetIntValue(SettingsFile, "arousalEligibilityMigration154", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Opt-in replacements for MME's original unmilked speed/carry penalties.
    ; Existing maid appearance-weight keys are intentionally untouched.
    If JsonUtil.GetIntValue(SettingsFile, "bodyEffectsMigration155", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableCustomMilkSpeedDebuff", 0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedMediumThreshold", 50.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedMediumPenalty", 3.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedHighThreshold", 100.0)
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedHighPenalty", 10.0)
        JsonUtil.SetIntValue(SettingsFile, "enableMaidLevelSpeedScaling", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableCustomMilkWeight", 0)
        JsonUtil.SetFloatValue(SettingsFile, "milkWeightMultiplier", 1.0)
        JsonUtil.SetIntValue(SettingsFile, "bodyEffectsMigration155", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Additive settings only: preserve every existing sound and strip choice.
    If JsonUtil.GetIntValue(SettingsFile, "movementSlapFlatStripMigration156", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMovementSlap", 1)
        JsonUtil.SetFloatValue(SettingsFile, "movementSlapVolume", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "enableFlatMilkStripping", 0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripHeavyMilk", 4.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripLightMilk", 8.0)
        JsonUtil.SetFloatValue(SettingsFile, "armorStripClothingMilk", 12.0)
        JsonUtil.SetIntValue(SettingsFile, "movementSlapFlatStripMigration156", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "movementSlapNotificationsMigration157", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableMovementSlapNotifications", 1)
        JsonUtil.SetFloatValue(SettingsFile, "movementSlapNotificationCooldownHours", 8.0)
        JsonUtil.SetIntValue(SettingsFile, "movementSlapNotificationsMigration157", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
EndFunction

Function SetDwemerEffectDefaults()
    JsonUtil.SetIntValue(SettingsFile, "enableDwemerEffects", 1)
    JsonUtil.SetFloatValue(SettingsFile, "dwemerEffectInterval", 12.0)
    JsonUtil.SetFloatValue(SettingsFile, "dwemerEffectVariation", 4.0)
    JsonUtil.SetIntValue(SettingsFile, "dwemerEffectChance", 100)
    JsonUtil.SetIntValue(SettingsFile, "enableDwemerEffectNotifications", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableDwemerEffectSounds", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableDwemerEffectNarration", 1)
    JsonUtil.SetIntValue(SettingsFile, "enableDwemerEffectPlayerNarration", 1)
    JsonUtil.SetIntValue(SettingsFile, "dwemerEffectNarrationChance", 100)
    JsonUtil.SetIntValue(SettingsFile, "enableDwemerEffectDiagnostics", 0)
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
    installedBackendOption = -1
    rosterOpenOption = -1
    rosterEnabledOption = -1
    rosterKeyOption = -1
    reverseDurationOption = -1
    reversePlayerLevelOption = -1
    reverseApplyOption = -1
    reverseRemoveOption = -1
    reverseTraceOption = -1
    timedArmorDurationOption = -1
    timedArmorReleaseOption = -1
    timedNPCArmorReleaseOption = -1
    chestArmorTrapOption = -1
    repeatTrapArmorStoriesOption = -1
    armorTrapNearbyAlliesOption = -1
    livingArmorChestTrapOption = -1
    parasiteArmorChestTrapOption = -1
    dwemerArmorChestTrapOption = -1
    dwemerArmorOutsideRuinsOption = -1
    dwemerRuinArmorTrapChanceOption = -1
    chestArmorTrapChanceOption = -1
    chestArmorTrapCooldownOption = -1
    dungeonChestMilkMaidOption = -1
    milkMaidTrapNearbyAlliesOption = -1
    chestCurseNarrationOption = -1
    milkMaidCurseMasterOption = -1
    milkMaidCurseSurgeOption = -1
    dungeonChestMilkMaidChanceOption = -1
    regularChestMilkMaidOption = -1
    regularChestMilkMaidChanceOption = -1
    chestMilkTrapOption = -1
    milkDrinkTrapNearbyAlliesOption = -1
    chestMilkTrapChanceOption = -1
    chestMilkTrapCooldownOption = -1
    chestMilkTrapVariationOption = -1
    chestMilkTrapNotificationOption = -1
    chestMilkTrapNarrationOption = -1
    innPalaceMilkDrinkingOption = -1
    guildTavernMilkDrinkingOption = -1
    jarlResidenceMilkDrinkingOption = -1
    townMilkDrinkOption = -1
    townMilkDrinkChanceOption = -1
    townUniqueNPCPreferenceOption = -1
    townUniqueNPCPreferenceChanceOption = -1
    innPalaceDrinkDelayOption = -1
    innPalaceDrinkVariationOption = -1
    innPalaceDrinkCooldownOption = -1
    milkCravingsOption = -1
    milkCravingNarrationOption = -1
    milkCravingIntervalOption = -1
    milkCravingVariationOption = -1
    milkCravingChanceOption = -1
    milkCravingGiveInDelayOption = -1
    autoSelfMilkingOption = -1
    autoSelfMilkingDelayOption = -1
    forcedMilkMaidNotificationOption = -1
    forcedMilkMaidLactacidStoryOption = -1
    forcedMilkMaidNarrationOption = -1
    forcedMilkMaidDiagnosticOption = -1
    ; Rebuild option IDs on every page render; SkyUI IDs are ephemeral and must
    ; never be persisted. Runtime values are always reread from JsonUtil.
    EnsureDefaults()
    NormalizeArousalThresholdSettings()
    movementSlapOption = -1
    movementSlapVolumeOption = -1
    movementSlapNotificationsOption = -1
    movementSlapNotificationCooldownOption = -1
    flatMilkStrippingOption = -1
    flatMilkHeavyOption = -1
    flatMilkLightOption = -1
    flatMilkClothingOption = -1
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
    maidBodyScalingOption = -1
    maidBodyMaxLevelOption = -1
    maidBodyHipsOption = -1
    maidBodyButtOption = -1
    maidBodyThighsOption = -1
    maidBodyCalfSizeOption = -1
    maidBodyWaistOption = -1
    maidBodyBellyOption = -1
    maidBodyBigBellyOption = -1
    maidBodyChubbyArmsOption = -1
    maidBodyChubbyLegsOption = -1
    maidBodyChubbyWaistOption = -1
    maidWeightScalingOption = -1
    maidWeightPerLevelOption = -1
    customMilkSpeedDebuffOption = -1
    milkSpeedMediumThresholdOption = -1
    milkSpeedMediumPenaltyOption = -1
    milkSpeedHighThresholdOption = -1
    milkSpeedHighPenaltyOption = -1
    maidLevelSpeedScalingOption = -1
    customMilkWeightOption = -1
    milkWeightMultiplierOption = -1
    addMilkDebugOption = -1
    breastfeedingMilkEffectsOption = -1
    elsieDetectedOption = -1
    elsieBreastfeedingMilkEffectsOption = -1
    estrusTestTypeOption = -1
    estrusTestRunOption = -1
    estrusTestResultOption = -1
    elsieBreastfeedingTestOption = -1
    breastfeedingMilkEffectsDebugOption = -1
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
    newMilkMaidMoansOption = -1
    skyrimNetStatusOption = -1
    arousalStatusOption = -1
    milkDrinkArousalOption = -1
    milkDrinkArousalAmountOption = -1
    arousalEffectsOption = -1
    arousalEffectNotificationsOption = -1
    arousalEffectSoundsOption = -1
    arousalEffectAnimationsOption = -1
    arousalMilkMaidRouteOption = -1
    arousalMilkDrinkRouteOption = -1
    arousalEveryoneRouteOption = -1
    arousalEffectDelayOption = -1
    arousalEffectCooldownOption = -1
    arousalEffectCooldownVariationOption = -1
    arousalLowThresholdOption = -1
    arousalMediumThresholdOption = -1
    arousalHighThresholdOption = -1
    sexLabBreastfeedingDebugOption = -1
    newMilkmaidDialogueTraceOption = -1
    newMilkmaidSexLabTraceOption = -1
    blacksmithDialogueTraceOption = -1
    alchemistDialogueTraceOption = -1
    mageDialogueTraceOption = -1
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
    playerMilkMaidConversionOption = -1
    playerMilkMaidConversionChanceOption = -1
    giveMilkEasyModeOption = -1
    nonMilkmaidFemaleDrinkingOption = -1
    nonMilkmaidFemaleArousalOption = -1
    nonMilkmaidMaleDrinkingOption = -1
    nonMilkmaidMaleArousalOption = -1
    nonMilkmaidDrinkNotificationsOption = -1
    armorStrippingCheckDiagnosticOption = -1
    lifecycleDiagnosticOption = -1
    milkmaidCreationDiagnosticOption = -1
    nativeScanDiagnosticOption = -1
    skyrimNetMilkStatusesOption = -1
    skyrimNetMilkDrinksOption = -1
    skyrimNetMilkingEventsOption = -1
    skyrimNetMilkmaidCreatedOption = -1
    skyrimNetStatusIntervalOption = -1
    postMilkingNarrationOption = -1
    postMilkingCooldownOption = -1
    postMilkingChanceOption = -1
    fullHistoryOption = -1
    milkFullNarrationChanceOption = -1
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
    breastfeedingActionCooldownOption = -1
    giveMilkActionOption = -1
    createMilkMaidActionOption = -1
    giveMilkActionCooldownOption = -1
    actorDrinkMilkRemovalOption = -1
    selfMilkingActionDiagnosticOption = -1
    pairedMilkingActionDiagnosticOption = -1
    giveMilkActionDiagnosticOption = -1
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
    armorLookupForensicsOption = -1
    extensionsArmorStrippingOption = -1
    milkingEquipmentRefitOption = -1
    repeatOrdinaryArmorStoriesOption = -1
    armorStripHeavyEnabledOption = -1
    armorStripLightEnabledOption = -1
    armorStripClothingEnabledOption = -1
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
    stripAllArmorOverrideOption = -1
    armorCheckReminderOption = -1
    armorCheckReminderCooldownOption = -1
    milkMaidThoughtsOption = -1
    milkMaidThoughtsIntervalOption = -1
    milkMaidThoughtsRandomnessOption = -1
    milkMaidThoughtNarrationOption = -1
    armorThoughtSoundsOption = -1
    boundMilkMaidThoughtsOption = -1
    boundMilkMaidThoughtsIntervalOption = -1
    boundMilkMaidThoughtsRandomnessOption = -1
    boundMilkMaidThoughtsChanceOption = -1
    boundMilkMaidThoughtNarrationOption = -1
    boundMilkMaidThoughtNarrationChanceOption = -1
    boundMilkMaidThoughtSoundsOption = -1
    boundMilkDrinkReactionOption = -1
    boundMilkDrinkReactionChanceOption = -1
    milkMaidThoughtsDebugOption = -1
    traceMilkMaidThoughtsLogicOption = -1
    tentacleChanceOptions = new Int[4]
    tentacleDurationOptions = new Int[4]
    Int tentacleIndex = 0
    While tentacleIndex < 4
        tentacleChanceOptions[tentacleIndex] = -1
        tentacleDurationOptions[tentacleIndex] = -1
        tentacleIndex += 1
    EndWhile
    armorInjectionOption = -1
    armorInjectionIntervalOption = -1
    armorInjectionVariationOption = -1
    armorInjectionChanceOption = -1
    armorInjectionNotificationOption = -1
    armorInjectionSoundOption = -1
    armorInjectionDiagnosticOption = -1
    armorInjectionNarrationOption = -1
    armorInjectionPlayerNarrationOption = -1
    armorInjectionNarrationChanceOption = -1
    runArmorInjectionCheckOption = -1
    dwemerEffectOption = -1
    dwemerEffectIntervalOption = -1
    dwemerEffectVariationOption = -1
    dwemerEffectChanceOption = -1
    dwemerEffectNotificationOption = -1
    dwemerEffectSoundOption = -1
    dwemerEffectDiagnosticOption = -1
    dwemerEffectNarrationOption = -1
    dwemerEffectPlayerNarrationOption = -1
    dwemerEffectNarrationChanceOption = -1
    runDwemerEffectCheckOption = -1
    diagnosticNotificationsOption = -1
    papyrusTraceOption = -1
    verbosePapyrusTraceOption = -1
    diagnosticRefreshGateOption = -1
    diagnosticInstallAuditOption = -1
    diagnosticMilkDrinkAuditOption = -1
    diagnosticSpawnOManiaPotionOption = -1
    diagnosticGlobalNPCDrinkTestOption = -1
    diagnosticDialogueAuditOption = -1
    diagnosticNewMilkmaidSexLabBusOption = -1
    diagnosticRefreshSexLabBusOption = -1
    diagnosticShowSexLabBusOption = -1
    diagnosticBlacksmithBusOption = -1
    diagnosticShowBlacksmithBusOption = -1
    diagnosticAlchemistBusOption = -1
    diagnosticShowAlchemistBusOption = -1
    diagnosticMageBusOption = -1
    diagnosticShowMageBusOption = -1
    diagnosticInstallStatusOption = -1
    diagnosticOStimStatusOption = -1
    diagnosticSexLabStatusOption = -1
    diagnosticGateStatusOption = -1
    diagnosticSexLabBusStateOption = -1
    diagnosticSexLabBusStopOption = -1
    diagnosticSexLabBusFailureOption = -1
    diagnosticBlacksmithBusStateOption = -1
    diagnosticBlacksmithBusStopOption = -1
    diagnosticBlacksmithBusFailureOption = -1
    diagnosticAlchemistBusStateOption = -1
    diagnosticAlchemistBusStopOption = -1
    diagnosticAlchemistBusFailureOption = -1
    diagnosticMageBusStateOption = -1
    diagnosticMageBusStopOption = -1
    diagnosticMageBusFailureOption = -1
    SetCursorFillMode(TOP_TO_BOTTOM)
    If page == Pages[2] || page == "Body"
        DrawBodyPage()
    ElseIf page == Pages[7] || page == "Traps & Curses" || page == "Misc"
        DrawTrapsPage()
    ElseIf page == Pages[1] || page == "Milk Drinking"
        DrawMilkDrinkingPage()
    ElseIf page == Pages[3] || page == "Arousal"
        DrawArousalPage()
    ElseIf page == Pages[4] || page == "Armor & Stripping" || page == "Armor"
        DrawArmorPage()
    ElseIf page == Pages[8] || page == "Skyrim.Net"
        DrawSkyrimNetPage()
    ElseIf page == Pages[6] || page == "Armor Reactions" || page == "Milk Armor Thoughts"
        DrawArmorThoughtsPage()
    ElseIf page == Pages[5] || page == "Armor Effects"
        DrawArmorEffectsPage()
    ElseIf page == Pages[10] || page == "Troubleshoot"
        DrawTroubleshootPage()
    ElseIf page == Pages[9] || page == "Debug"
        DrawDebugPage()
    Else
        DrawGeneralPage()
    EndIf
EndEvent

; Gives every visible setting a short explanation for players and screen readers.
Event OnOptionHighlight(Int option)
    If option == postMilkingNarrationOption
        SetInfoText(MMELocalization.Text("Speak after successful milking, with a reaction matching hands, pump, equipment, tendrils or Dwemer machinery. Turning speech off still allows tracked history."))
        Return
    ElseIf option == postMilkingCooldownOption
        SetInfoText(MMELocalization.Text("Real seconds between accepted completion reactions across all Milk Maids, including the player. One accepted reaction starts the shared cooldown."))
        Return
    ElseIf option == postMilkingChanceOption || option == milkFullNarrationChanceOption
        SetInfoText(MMELocalization.Text("Chance of a spoken reaction. Zero disables that reaction; tracked history is still recorded."))
        Return
    ElseIf option == fullHistoryOption
        SetInfoText(MMELocalization.Text("Record when each observed Milk Maid reaches full capacity and begins leaking. No speech is required; dropping below full allows another crossing to be recorded."))
        Return
    EndIf
    If option == installedBackendOption
        SetInfoText(MMELocalization.Text("Read-only installed backend selected by the FOMOD: Standard SexLab, SexLab P+, or OStim-only. Change the installed backend by reinstalling the matching FOMOD choice. The OStim breastfeeding toggle only controls breastfeeding routes."))
        Return
    EndIf
    Int teaseTierIndex = TentacleOptionIndex(option, False)
    If teaseTierIndex >= 0
        If teaseTierIndex == 0
            SetInfoText(MMELocalization.Text("A little wriggle, a little blush - the armor is only saying hello. Sets the chance of Low intensity after a successful effect. Adjusts in 5% steps; the other tiers rebalance to total 100%. Separate from Effect Chance above."))
        ElseIf teaseTierIndex == 1
            SetInfoText(MMELocalization.Text("Those wandering tendrils have discovered that their wearer is delightfully ticklish. Sets the chance of Medium intensity after a successful effect. Adjusts in 5% steps; the other tiers rebalance to total 100%. Separate from Effect Chance above."))
        ElseIf teaseTierIndex == 2
            SetInfoText(MMELocalization.Text("Oh dear. The armor has abandoned its manners, and standing gracefully may require some concentration. Sets the chance of High intensity after a successful effect. Adjusts in 5% steps; the other tiers rebalance to total 100%. Separate from Effect Chance above."))
        ElseIf teaseTierIndex == 3
            SetInfoText(MMELocalization.Text("A proper fairy-tale predicament: enchanted armor, rosy cheeks, and absolutely no interest in behaving. Sets the chance of Extreme intensity after a successful effect. Adjusts in 5% steps; the other tiers rebalance to total 100%. Separate from Effect Chance above."))
        EndIf
        Return
    EndIf
    teaseTierIndex = TentacleOptionIndex(option, True)
    If teaseTierIndex >= 0
        If teaseTierIndex == 0
            SetInfoText(MMELocalization.Text("How many seconds our heroine spends composing herself after that entirely innocent little wriggle. Controls the Low-tier animation duration, in seconds. Animation type is fixed. Applies only to Living/Parasite effects."))
        ElseIf teaseTierIndex == 1
            SetInfoText(MMELocalization.Text("Give those fluttering knees a moment to remember their royal duties. Controls the Medium-tier animation duration, in seconds. Animation type is fixed. Applies only to Living/Parasite effects."))
        ElseIf teaseTierIndex == 2
            SetInfoText(MMELocalization.Text("Even a brave adventuress needs a moment when her wardrobe becomes this affectionate. Controls the High-tier animation duration, in seconds. Animation type is fixed. Applies only to Living/Parasite effects."))
        ElseIf teaseTierIndex == 3
            SetInfoText(MMELocalization.Text("The armor requests an encore. Her dignity requests a curtain. Controls the Extreme-tier animation duration, in seconds. Animation type is fixed. Applies only to Living/Parasite effects."))
        EndIf
        Return
    EndIf
    If option == rosterOpenOption || option == rosterEnabledOption || option == rosterKeyOption
        SetInfoText(MMELocalization.Text("Optional Milk Maid roster: requires the Maid Roster add-on plugin and Magelight UI 1.5.0 or newer. Open, then close MCM to show it. Assign an optional keyboard hotkey; PageUp is reserved by Magelight. Displays stored milk amounts and fullness. Give Milk/Drink uses player inventory and the Free Jug setting; Self Milk starts eligible maids."))
        Return
    EndIf
    If option == narrationReloadOption || option == narrationImportOption
        SetInfoText(MMELocalization.Text("Edit SKSE/Plugins/StorageUtilData/MMEAlerts/Narration JSON in a text editor. Reload reads your edits without saving over them. Import copies recognized legacy text only into unchanged defaults; customized entries are kept. Back up presets before updating the mod."))
        Return
    EndIf
    If option == movementSlapNotificationsOption
        SetInfoText(MMELocalization.Text("Show one of five player-only messages when an eligible movement slap loop starts. Notifications have a shared cooldown; turning them off does not affect the sound."))
        Return
    ElseIf option == movementSlapNotificationCooldownOption
        SetInfoText(MMELocalization.Text("Minimum in-game hours between movement slap notifications. Default 8, range 0-48. Zero removes the cooldown; messages still occur only on eligible playback starts. Saved across reloads."))
        Return
    ElseIf option == movementSlapOption
        SetInfoText(MMELocalization.Text("Loop the slap sound while the player moves on foot above 50% milk fullness. Stops in menus, on mounts, swimming, or during incompatible scenes. Uses the sound master and volume."))
        Return
    ElseIf option == movementSlapVolumeOption
        SetInfoText(MMELocalization.Text("Movement slap only. 0% mutes, 100% is the original level, 200% doubles amplitude (+6 dB). Default 100%. Also scaled by Moaning Sound Volume."))
        Return
    ElseIf option == flatMilkStrippingOption
        SetInfoText(MMELocalization.Text("Player only. Also strip when milk amount exceeds the category's flat threshold, OR when its existing fullness threshold is reached. Requires Override MME Armor Stripping and respects category toggles and protections. Default off."))
        Return
    ElseIf option == flatMilkHeavyOption || option == flatMilkLightOption || option == flatMilkClothingOption
        SetInfoText(MMELocalization.Text("Strip when the player's milk amount is strictly greater than this value. Range 0-100 milk units. Original MME defaults: heavy 4, light 8, clothing 12. Zero triggers with any positive milk; category toggles disable stripping."))
        Return
    EndIf
    If option == timedArmorDurationOption
        SetInfoText(MMELocalization.Text("How many game days supported chest armor remains locked after equip. Zero releases immediately; default 3 days, range 0-30. This standalone system does not require Devious Devices."))
        Return
    ElseIf option == timedArmorReleaseOption
        SetInfoText(MMELocalization.Text("Debug release for the player's current timed armor bond. It clears MME Extensions' lock and unequips that chest piece."))
        Return
    ElseIf option == breastBounceNotificationOption
        SetInfoText(MMELocalization.Text("Shows occasional playful breast-bounce flavor for one nearby adult female Milk Maid."))
        Return
    ElseIf option == breastBounceSoundOption
        SetInfoText(MMELocalization.Text("Plays a mild sound below half capacity, or a medium moan and breast-slap sound at half capacity or higher."))
        Return
    ElseIf option == breastBounceIntervalOption
        SetInfoText(MMELocalization.Text("Base time between nearby Milk Maid reactions. Default 24 game hours; range 1-36."))
        Return
    ElseIf option == breastBounceVariationOption
        SetInfoText(MMELocalization.Text("Random variation added to or subtracted from the reaction interval. Default 4 game hours."))
        Return
    ElseIf option == breastBounceDelayOption
        SetInfoText(MMELocalization.Text("Maximum random real-time delay after a Milk Maid is selected. Default 30 seconds; range 0-60."))
        Return
    ElseIf option == timedNPCArmorReleaseOption
        SetInfoText(MMELocalization.Text("Debug release for nearby allied or follower NPCs wearing supported Living, Parasite, or Dwemer armor. Armor stays in their inventory."))
        Return
    ElseIf option == innPalaceMilkDrinkingOption
        SetInfoText(MMELocalization.Text("After entering an inn or enabled special social venue, wait a randomized delay and make one random eligible loaded NPC drink ordinary HearthFires milk through the normal API. Default on."))
        Return
    ElseIf option == guildTavernMilkDrinkingOption
        SetInfoText(MMELocalization.Text("Include Jorrvaskr, the Ragged Flagon and the Drunken Huntsman, which vanilla does not classify as inns. Default on."))
        Return
    ElseIf option == jarlResidenceMilkDrinkingOption
        SetInfoText(MMELocalization.Text("Include the nine vanilla jarl residences without treating Castle Dour as a palace. Default on."))
        Return
    ElseIf option == townMilkDrinkOption
        SetInfoText(MMELocalization.Text("On entering a major-city location, including its interiors, roll for one delayed normal-milk drink. Shares the inn and palace timer and cooldown. Default on."))
        Return
    ElseIf option == townMilkDrinkChanceOption
        SetInfoText(MMELocalization.Text("Chance to schedule a drink when entering a major-city location. Failed rolls are silent and do not start the cooldown. Default 25%, range 0-100% in 5% steps."))
        Return
    ElseIf option == townUniqueNPCPreferenceOption
        SetInfoText(MMELocalization.Text("Favor named, unique NPCs over generic NPCs such as guards when a town drink selects its actor. Safely falls back when only one pool is available. Default on."))
        Return
    ElseIf option == townUniqueNPCPreferenceChanceOption
        SetInfoText(MMELocalization.Text("Chance to choose an eligible unique NPC when both unique and generic town candidates are nearby. Default 75%, range 0-100% in 5% steps."))
        Return
    ElseIf option == innPalaceDrinkDelayOption
        SetInfoText(MMELocalization.Text("Base real-time delay after entering a supported venue. Default 11 seconds."))
        Return
    ElseIf option == innPalaceDrinkVariationOption
        SetInfoText(MMELocalization.Text("Random seconds added to or subtracted from the base delay. The final delay is at least one second. Default +/-10 seconds."))
        Return
    ElseIf option == innPalaceDrinkCooldownOption
        SetInfoText(MMELocalization.Text("Shared game-time cooldown started only after verified consumption. Zero disables the cooldown. Default 4 hours, range 0-24."))
        Return
    ElseIf option == milkCravingsOption
        SetInfoText(MMELocalization.Text("Periodically select one nearby loaded MME Milk Maid, announce a craving, then make her drink ordinary milk after a random game-time delay. Includes the player. Default on."))
        Return
    ElseIf option == milkCravingNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for one short first-person reaction from the affected Milk Maid when her craving begins. Available only when Skyrim.Net is installed. Default on."))
        Return
    ElseIf option == milkCravingIntervalOption
        SetInfoText(MMELocalization.Text("Base delay between craving attempts in Skyrim game-time hours. A new interval is rolled after every completed or skipped attempt. Default 48 hours."))
        Return
    ElseIf option == milkCravingVariationOption
        SetInfoText(MMELocalization.Text("Randomly subtract or add this many game-time hours. Runtime clamps the final interval to at least one hour. Default 24 hours."))
        Return
    ElseIf option == milkCravingChanceOption
        SetInfoText(MMELocalization.Text("Chance that a due craving begins after at least one valid nearby Milk Maid is found. Default 100%, adjustable in 5% steps."))
        Return
    ElseIf option == milkCravingGiveInDelayOption
        SetInfoText(MMELocalization.Text("Maximum random game-time delay between the craving notification and giving in. The actual delay is rolled from zero to this value. Default four hours."))
        Return
    ElseIf option == autoSelfMilkingOption
        SetInfoText(MMELocalization.Text("After the existing Milk Full trigger, queue that Milk Maid for MME's original self-milking scene. Includes the player and nearby NPC Milk Maids. Default on."))
        Return
    ElseIf option == autoSelfMilkingDelayOption
        SetInfoText(MMELocalization.Text("Game-time delay between the Milk Full trigger and MME's original self-milking scene. The actor must still be nearby, full, valid, and not already milking. Default 1 hour, range 0-24."))
        Return
    EndIf
    If option == chestArmorTrapOption
        SetInfoText(MMELocalization.Text("Master switch for JSON-backed Living, Parasite and Dwemer treasure-chest armor traps. Default on."))
        Return
    ElseIf option == armorTrapNearbyAlliesOption
        SetInfoText(MMELocalization.Text("Allow treasure-chest armor traps to select and lock eligible nearby allied female NPCs as well as the player. Turn off for player-only targeting and to prevent new NPC armor locks. Default on."))
        Return
    ElseIf option == repeatTrapArmorStoriesOption
        SetInfoText(MMELocalization.Text("Replay the category story, sound, and animation whenever a treasure-chest trap successfully equips Living, Parasite, or Dwemer armor. Protective forced re-equips do not count. Default on."))
        Return
    ElseIf option == livingArmorChestTrapOption
        SetInfoText(MMELocalization.Text("Allow configured Living Armor pieces in the general treasure-chest trap pool. Default on."))
        Return
    ElseIf option == parasiteArmorChestTrapOption
        SetInfoText(MMELocalization.Text("Allow configured Parasite Armor pieces in the general treasure-chest trap pool. Default on."))
        Return
    ElseIf option == dwemerArmorChestTrapOption
        SetInfoText(MMELocalization.Text("Allow configured Dwemer Armor pieces in Dwemer-ruin and permitted outside-ruin trap pools. Default on."))
        Return
    ElseIf option == dwemerArmorOutsideRuinsOption
        SetInfoText(MMELocalization.Text("Allow configured Dwemer armor to join the general random armor pool outside Dwemer ruins. Default off."))
        Return
    ElseIf option == dwemerRuinArmorTrapChanceOption
        SetInfoText(MMELocalization.Text("Separate first roll in Dwemer ruins. A success selects only configured Dwemer armor. Default 25%, adjustable in 5% steps."))
        Return
    ElseIf option == chestArmorTrapChanceOption
        SetInfoText(MMELocalization.Text("General random Living or Parasite armor roll after the Dwemer-only roll misses. Default 5%, adjustable in 5% steps."))
        Return
    ElseIf option == chestArmorTrapCooldownOption
        SetInfoText(MMELocalization.Text("Shared cooldown started only after armor is successfully equipped and locked. Default 4 game hours, range 0-24."))
        Return
    EndIf
    If option == milkMaidCurseMasterOption
        SetInfoText(MMELocalization.Text("Enable chest-triggered Milk Maid conversion and existing-maid milk surges. Boss/regular chest settings are preserved while off. Armor traps, exotic milk traps, and non-chest conversion sources remain independent."))
        Return
    ElseIf option == dungeonChestMilkMaidOption
        SetInfoText(MMELocalization.Text("Curated boss chests curse an eligible nearby allied female: convert a non-maid first, otherwise surge an existing maid. Each chest resolves once after a committed curse or missed roll. Default on."))
        Return
    ElseIf option == milkMaidTrapNearbyAlliesOption
        SetInfoText(MMELocalization.Text("Allow treasure-chest Milk Maid curses to select eligible nearby allied female NPCs as well as the player. Turn off for player-only targeting. Default on."))
        Return
    ElseIf option == milkMaidCurseSurgeOption
        SetInfoText(MMELocalization.Text("When no eligible non-Milk Maid remains, the chest curse adds this percentage of an existing maid's maximum milk, allowing overflow. Default 50%; zero disables the surge. Later MME cycles retain normal leak/limit behavior."))
    ElseIf option == dungeonChestMilkMaidChanceOption
        SetInfoText(MMELocalization.Text("Chance that an eligible dungeon boss chest activation attempts Milk Maid conversion or a milk surge. Default 100%, range 0-100 in 5% steps."))
        Return
    ElseIf option == regularChestMilkMaidOption
        SetInfoText(MMELocalization.Text("Curated ordinary vanilla and DLC treasure chests can forcibly convert their eligible activator. Merchant, evidence, player-storage, EMPTY and boss containers are excluded. Default on."))
        Return
    ElseIf option == regularChestMilkMaidChanceOption
        SetInfoText(MMELocalization.Text("One-shot conversion chance for each eligible ordinary treasure chest. Default 10%, range 0-100 in 5% steps."))
        Return
    ElseIf option == chestMilkTrapOption
        SetInfoText(MMELocalization.Text("After the conversion trap declines, curated boss and ordinary treasure chests may force one nearby adult humanoid to drink random Succubus, Vampire, or Werewolf milk. Player and allies are prioritized. Default on."))
        Return
    ElseIf option == milkDrinkTrapNearbyAlliesOption
        SetInfoText(MMELocalization.Text("Allow exotic-milk chest curses to select eligible nearby allied female NPCs as well as the player. Turn off for player-only targeting. Default on."))
        Return
    ElseIf option == chestMilkTrapChanceOption
        SetInfoText(MMELocalization.Text("Chance per eligible chest activation. A failed roll does not start the shared cooldown. Default 33%, range 0-100 in 5% steps."))
        Return
    ElseIf option == chestMilkTrapCooldownOption
        SetInfoText(MMELocalization.Text("Shared game-time cooldown started only after a verified forced drink. Default 1 game hour."))
        Return
    ElseIf option == chestMilkTrapVariationOption
        SetInfoText(MMELocalization.Text("Random hours added to or subtracted from the base cooldown. The final cooldown is never below one game hour. Default 0 hours."))
        Return
    ElseIf option == chestMilkTrapNotificationOption
        SetInfoText(MMELocalization.Text("Show a factual HUD notification naming the selected actor and exotic milk after the forced drink. Works without Skyrim.Net. Default on."))
        Return
    ElseIf option == chestMilkTrapNarrationOption
        SetInfoText(MMELocalization.Text("Send one immediate Skyrim.Net event with the selected drinker prioritized as speaker. The gameplay trap already owns chance and cooldown. Default on."))
        Return
    ElseIf option == forcedMilkMaidNotificationOption
        SetInfoText(MMELocalization.Text("Show brief Milk Maid notifications for Extensions forced-conversion and curse routes, including non-chest sources. Native MME notifications have their own controls."))
        Return
    ElseIf option == forcedMilkMaidLactacidStoryOption
        SetInfoText(MMELocalization.Text("Show one randomly selected Milk Maid story for player forced conversions and curse surges. Uses the shared editable five-story pool. NPCs do not open story popups; native MME Lactacid stories remain separate."))
        Return
    ElseIf option == forcedMilkMaidNarrationOption
        SetInfoText(MMELocalization.Text("Enable Skyrim.Net reactions for Extensions forced-conversion and curse routes, including non-chest sources. Skyrim.Net remains optional."))
        Return
    ElseIf option == chestCurseNarrationOption
        SetInfoText(MMELocalization.Text("One playful Skyrim.Net reaction after a chest's magical Milk Maid conversion or milk surge. Default on; requires Enable Skyrim.Net Narration. Notifications and stories remain separate. Skyrim.Net is optional."))
        Return
    ElseIf option == forcedMilkMaidDiagnosticOption
        SetInfoText(MMELocalization.Text("Enable detailed diagnostics for Extensions forced-conversion and curse routes. Routine Papyrus footprints still use the master Papyrus logging toggle."))
        Return
    EndIf
    If option == reverseTraceOption
        SetInfoText(MMELocalization.Text("Log reverse-leveling application, milking completion, level changes and skipped writes to the Papyrus log. Default off."))
        Return
    EndIf
    If option == reverseDurationOption
        SetInfoText(MMELocalization.Text("Duration in game hours. Applying again refreshes the duration. Default 24, range 1-72."))
        Return
    ElseIf option == reversePlayerLevelOption
        SetInfoText(MMELocalization.Text("Minimum player Milk Maid level required to see the Court Wizard dialogue. Default 5, range 1-10. This setting never changes your actual level."))
        Return
    ElseIf option == reverseApplyOption
        SetInfoText(MMELocalization.Text("Apply or refresh the same reverse-leveling ability offered by Court Wizards."))
        Return
    ElseIf option == reverseRemoveOption
        SetInfoText(MMELocalization.Text("Remove reverse leveling immediately. Progress already lost stays lost."))
        Return
    EndIf
    If option == masterEnableOption
        SetInfoText(MMELocalization.Text("Turn MME Extensions on or off."))
    ElseIf option == soundsOption
        SetInfoText(MMELocalization.Text("Play reaction sounds for milking and milk drinking."))
    ElseIf option == volumeOption
        SetInfoText(MMELocalization.Text("Set the reaction sound volume."))
    ElseIf option == drinkMoansOption
        SetInfoText(MMELocalization.Text("Play a moan when the player drinks recognized milk."))
    ElseIf option == fullnessMoansOption
        SetInfoText(MMELocalization.Text("Play moans when a Milkmaid crosses half or full capacity."))
    ElseIf option == milkingMoansOption
        SetInfoText(MMELocalization.Text("Play moans when milking starts and ends."))
    ElseIf option == newMilkMaidMoansOption
        SetInfoText(MMELocalization.Text("Play one high moan near the beginning of every confirmed new Milk Maid conversion. Default on and controlled by the master sound switch and volume."))
    ElseIf option == capacityOption
        SetInfoText(MMELocalization.Text("React when a Milkmaid reaches half capacity."))
    ElseIf option == pollingOption
        SetInfoText(MMELocalization.Text("Periodically checks nearby Milkmaid fullness and player armor stripping. Disabling this also disables passive armor stripping checks, but drink and equip checks still work."))
    ElseIf option == pollingIntervalOption
        SetInfoText(MMELocalization.Text("Set seconds between capacity checks."))
    ElseIf option == notificationOption
        SetInfoText(MMELocalization.Text("Show capacity reaction notifications."))
    ElseIf option == milkmaidLevelBonusOption
        SetInfoText(MMELocalization.Text("Add MME Milkmaid Level divided by 2 to every recognized milk drink."))
    ElseIf option == flatMilkBonusOption
        SetInfoText(MMELocalization.Text("Add this much milk per MME or regular milk drink."))
    ElseIf option == customMilkSpeedDebuffOption
        SetInfoText(MMELocalization.Text("Use MME Extensions' threshold-based player speed penalty. Default off. Disable MME's original unmilked speed debuff first to prevent stacking."))
    ElseIf option == milkSpeedMediumThresholdOption
        SetInfoText(MMELocalization.Text("Milk fullness percentage that activates the medium penalty. The high tier replaces it rather than stacking."))
    ElseIf option == milkSpeedMediumPenaltyOption
        SetInfoText(MMELocalization.Text("Player movement-speed penalty at the medium milk threshold."))
    ElseIf option == milkSpeedHighThresholdOption
        SetInfoText(MMELocalization.Text("Milk fullness percentage that activates the high penalty. High wins if both thresholds are equal."))
    ElseIf option == milkSpeedHighPenaltyOption
        SetInfoText(MMELocalization.Text("Player movement-speed penalty at the high milk threshold."))
    ElseIf option == maidLevelSpeedScalingOption
        SetInfoText(MMELocalization.Text("Scale the selected speed penalty from 1x at Maid level 0 to 2x at level 100. Default off."))
    ElseIf option == customMilkWeightOption
        SetInfoText(MMELocalization.Text("Reduce player carry capacity by current milk times the multiplier. Default off. Disable MME's matching unmilked debuff first to prevent stacking."))
    ElseIf option == milkWeightMultiplierOption
        SetInfoText(MMELocalization.Text("Carry-weight penalty applied per unit of milk, from 1x to 10x."))
    ElseIf option == maidBodyScalingOption
        SetInfoText(MMELocalization.Text("Optional RaceMenu body morphs for player and NPC Milk Maids. Default off. Disable to remove only MME Extensions' morph contributions. Breasts remain controlled by MME. Requires bodies and outfits built with matching morphs."))
    ElseIf option == maidBodyMaxLevelOption
        SetInfoText(MMELocalization.Text("Maid level at which body morphs reach their selected maximum. Range 10-100, default 100. Higher Maid levels add no further scaling. This does not change MME's actual level or capacity."))
    ElseIf option == maidBodyHipsOption
        SetInfoText(MMELocalization.Text("Maximum hips morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyButtOption
        SetInfoText(MMELocalization.Text("Maximum butt morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyThighsOption
        SetInfoText(MMELocalization.Text("Maximum thighs morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyCalfSizeOption
        SetInfoText(MMELocalization.Text("Maximum calves morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyWaistOption
        SetInfoText(MMELocalization.Text("Maximum waist morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyBellyOption
        SetInfoText(MMELocalization.Text("Maximum belly morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyBigBellyOption
        SetInfoText(MMELocalization.Text("Maximum big belly morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyChubbyArmsOption
        SetInfoText(MMELocalization.Text("Maximum chubby arms morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyChubbyLegsOption
        SetInfoText(MMELocalization.Text("Maximum chubby legs morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidBodyChubbyWaistOption
        SetInfoText(MMELocalization.Text("Maximum chubby waist morph contribution at the selected Maid level. 0% disables this morph. Intermediate levels scale proportionally. Requires the matching body/outfit morph; this is a slider percentage, not an anatomical size percentage."))
    ElseIf option == maidWeightScalingOption
        SetInfoText(MMELocalization.Text("Increase every registered Milk Maid's actor weight as her MME Maid level rises. Turning this off restores the baseline recorded before MME Extensions changed it. Weight changes can expose neck seams on some NPC replacers."))
    ElseIf option == maidWeightPerLevelOption
        SetInfoText(MMELocalization.Text("Add this many actor-weight points per MME Maid level. Range 0-10; final Skyrim actor weight is clamped to 100."))
    ElseIf option == lactacidMultiplierOption
        SetInfoText(MMELocalization.Text("Multiply Lactacid's Flat Bonus from 0 to 2. MME Level Bonus is separate."))
    ElseIf option == npcDrinkAnimationOption
        SetInfoText(MMELocalization.Text("Play MME's original Lactacid/New Milkmaid reaction animation after a Milkmaid drinks through dialogue."))
    ElseIf option == npcDrinkAnimationDurationOption
        SetInfoText(MMELocalization.Text("Set how long the NPC Milk-Drink Animation plays before the actor returns to idle."))
    ElseIf option == playerDrinkAnimationOption
        SetInfoText(MMELocalization.Text("Play MME's original Lactacid/New Milkmaid reaction animation after you drink recognized milk."))
    ElseIf option == playerDrinkAnimationDurationOption
        SetInfoText(MMELocalization.Text("Set how long your Milk-Drink Animation plays before you return to idle."))
    ElseIf option == playerHalfFullSelfMilkAnimationOption
        SetInfoText(MMELocalization.Text("Play MME's Self-Milk animation when you cross 50% fullness."))
    ElseIf option == playerFullSelfMilkAnimationOption
        SetInfoText(MMELocalization.Text("Play MME's standing milking animation when you cross 100% fullness, without triggering milking."))
    ElseIf option == playerFullnessSelfMilkAnimationDurationOption
        SetInfoText(MMELocalization.Text("Set how long your fullness self-milk animations play before you return to idle."))
    ElseIf option == npcHalfFullSelfMilkAnimationOption
        SetInfoText(MMELocalization.Text("Play MME's Self-Milk animation when an NPC Milkmaid crosses 50% fullness."))
    ElseIf option == npcFullSelfMilkAnimationOption
        SetInfoText(MMELocalization.Text("Play MME's standing milking animation when an NPC Milkmaid crosses 100% fullness, without triggering milking."))
    ElseIf option == npcFullnessSelfMilkAnimationDurationOption
        SetInfoText(MMELocalization.Text("Set how long NPC fullness self-milk animations play before the actor returns to idle."))
    ElseIf option == ostimBreastfeedingOption
        SetInfoText(MMELocalization.Text("Enable OStim breastfeeding dialogue and scenes when OStim is available. This controls breastfeeding only; it does not switch the installed Standard SexLab, P+, or OStim-only backend. For OStim-only installs, keep this enabled to use breastfeeding."))
    ElseIf option == ostimBreastfeedingDurationOption
        SetInfoText(MMELocalization.Text("Set how long the dedicated fixed OStim breastfeeding scene runs. This is independent of MME milking completion."))
    ElseIf option == ostimStatusOption
        SetInfoText("Read-only. Shows whether OStim.esp is active. The installed backend is shown separately; plugin detection alone does not verify scene readiness.")
    ElseIf option == ostimDebugOption
        SetInfoText(MMELocalization.Text("Show in-game reasons when OStim breastfeeding is unavailable, blocked, or fails to start."))
    ElseIf option == newMilkmaidDialogueTraceOption
        SetInfoText(MMELocalization.Text("Show concise in-game and Papyrus breadcrumbs for the breastfeeding-to-Milk-Maid creation route."))
    ElseIf option == newMilkmaidSexLabTraceOption
        SetInfoText(MMELocalization.Text("Show numbered 01-16 bus stops for the dedicated SexLab breastfeeding-to-Milk-Maid transaction."))
    ElseIf option == npcMilkEffectsOption
        SetInfoText(MMELocalization.Text("Apply milk, arousal, and moan effects when an MME Milkmaid consumes recognized milk."))
    ElseIf option == npcDrinkNotificationsOption
        SetInfoText(MMELocalization.Text("Show a notification after an NPC Milkmaid drinks recognized milk."))
    ElseIf option == playerDrinkNotificationsOption
        SetInfoText(MMELocalization.Text("Show a notification after you drink recognized milk."))
    ElseIf option == playerMilkMaidConversionOption
        SetInfoText(MMELocalization.Text("Allow recognized ordinary milk to transform a non-Milk-Maid player through MME's original Lactacid creation effect. Real Lactacid keeps its native behavior."))
    ElseIf option == playerMilkMaidConversionChanceOption
        SetInfoText(MMELocalization.Text("Set the chance that a recognized ordinary milk drink transforms the eligible player into an MME Milk Maid."))
    ElseIf option == giveMilkEasyModeOption
        SetInfoText(MMELocalization.Text("When Give Milk finds no eligible milk, supply and immediately consume one temporary HearthFires Jug of Milk. Lactacid is never used. Default on."))
    ElseIf option == nonMilkmaidFemaleDrinkingOption
        SetInfoText(MMELocalization.Text("Allow eligible adult female non-Milkmaids to receive milk through Give Milk."))
    ElseIf option == nonMilkmaidFemaleArousalOption
        SetInfoText(MMELocalization.Text("Optional SexLab Aroused exposure added after an adult female non-Milkmaid successfully drinks. Zero disables it."))
    ElseIf option == nonMilkmaidMaleDrinkingOption
        SetInfoText(MMELocalization.Text("Allow eligible adult male non-Milkmaids to receive milk through Give Milk."))
    ElseIf option == nonMilkmaidMaleArousalOption
        SetInfoText(MMELocalization.Text("Optional SexLab Aroused exposure added after an adult male non-Milkmaid successfully drinks. Zero disables it."))
    ElseIf option == nonMilkmaidDrinkNotificationsOption
        SetInfoText(MMELocalization.Text("Show local flavor text after a non-Milkmaid drinks. This does not call Skyrim.Net."))
    ElseIf option == selfMilkingActionOption
        SetInfoText(MMELocalization.Text("Allow Skyrim.Net to start self-milking for a selected Milk Maid."))
    ElseIf option == pairedMilkingActionOption
        SetInfoText(MMELocalization.Text("Allow Skyrim.Net to start a milk-sharing scene with the selected source and the player."))
    ElseIf option == breastfeedingActionCooldownOption
        SetInfoText(MMELocalization.Text("Prevent Skyrim.Net from starting another breastfeeding action for this many real-time seconds. Dialogue breastfeeding remains available."))
    ElseIf option == giveMilkActionOption
        SetInfoText(MMELocalization.Text("Allow three explicit Skyrim.Net routes: player gives to speaker to drink, speaker gives to player to drink, or speaker gives to another NPC to drink."))
    ElseIf option == createMilkMaidActionOption
        SetInfoText(MMELocalization.Text("Allow Skyrim.Net to convert one explicitly selected adult female NPC through MME's native Lactacid registration and animation flow. Every target and capacity check is repeated before commit."))
    ElseIf option == actorDrinkMilkRemovalOption
        SetInfoText(MMELocalization.Text("When the giver is a confirmed MME Milkmaid with at least one stored milk, spend one milk to fund the jug. Failed transactions restore the deducted milk; other givers receive the baseline free jug."))
    ElseIf option == giveMilkActionCooldownOption
        SetInfoText(MMELocalization.Text("Prevent Skyrim.Net from starting another Give Milk action for this many real-time seconds. Normal Give Milk dialogue remains available."))
    ElseIf option == npcMilkConsumptionDiagnosticOption
        SetInfoText(MMELocalization.Text("Report native NPC milk detection, Milkmaid validation, duplicates, and applied effects."))
    ElseIf option == npcDrinkNotificationsDiagnosticOption
        SetInfoText(MMELocalization.Text("Report NPC drink notification skips and the effective milk and arousal results shown."))
    ElseIf option == debugMilkingEventsOption
        SetInfoText(MMELocalization.Text("Report each detected milking start and end."))
    ElseIf option == lifecycleDiagnosticOption
        SetInfoText(MMELocalization.Text("Report native wait, sleep, location, and load events with nearby Milkmaid status."))
    ElseIf option == milkmaidCreationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report MME creation effects and confirmed new Milkmaids."))
    ElseIf option == nativeScanDiagnosticOption
        SetInfoText(MMELocalization.Text("Report native nearby actor counts and scanner failures."))
    ElseIf option == debugMilkReportOption
        SetInfoText(MMELocalization.Text("Report nearby Milkmaid capacity every five seconds."))
    ElseIf option == addMilkDebugOption
        SetInfoText(MMELocalization.Text("Report the full player milk-drink transaction: detection, sound, milk bonus math, arousal, notification, and MME add results."))
    ElseIf option == breastfeedingMilkEffectsOption
        SetInfoText(MMELocalization.Text("After a validated OStim or SexLab breastfeeding scene completes, apply only the milk and milk-drink arousal bonuses to the drinker."))
    ElseIf option == elsieDetectedOption
        SetInfoText(MMELocalization.Text("Read-only detection status for Elsie LaVache 3.4. Install the recommended Elsie FOMOD compatibility patch to enable its breastfeeding integration."))
    ElseIf option == elsieBreastfeedingMilkEffectsOption
        SetInfoText(MMELocalization.Text("After a completed Elsie ELV_Taste breastfeeding scene, give the drinker the normal MME Extensions breastfeeding milk effects. Also requires Breastfeeding Gives Milk above. Default on."))
    ElseIf option == estrusTestTypeOption
        SetInfoText(MMELocalization.Text("Click to cycle Chaurus, Spider and Dwemer. The test affects only the player."))
    ElseIf option == estrusTestRunOption
        SetInfoText(MMELocalization.Text("Request the selected Estrus pregnancy without animation. Close MCM to run; respects Estrus settings and existing pregnancies. Requires the installed Estrus compatibility option."))
    ElseIf option == elsieBreastfeedingTestOption
        SetInfoText(MMELocalization.Text("Start one checked Elsie-style breastfeeding scene using a nearby Milk Maid and customer. Uses the same repaired SexLab starter and completion route as Elsie's autonomous scene."))
    ElseIf option == breastfeedingMilkEffectsDebugOption
        SetInfoText(MMELocalization.Text("Show one short result when breastfeeding milk and arousal effects apply or are skipped."))
    ElseIf option == skyrimNetDrinkDiagnosticOption
        SetInfoText(MMELocalization.Text("Report SkyrimNet milk-drink payloads and API results."))
    ElseIf option == skyrimNetMilkingDiagnosticOption
        SetInfoText(MMELocalization.Text("Report SkyrimNet milking start/end payloads and API results."))
    ElseIf option == skyrimNetCreationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report SkyrimNet new-Milkmaid schema, payload, and API results."))
    ElseIf option == skyrimNetStatusDiagnosticOption
        SetInfoText(MMELocalization.Text("Detailed actor prompt snapshots require master and verbose Papyrus logging. Changed snapshots use master logging."))
    ElseIf option == skyrimNetPromptDiagnosticOption
        SetInfoText(MMELocalization.Text("Report when Skyrim.Net renders the optional Milkmaid bio prompt for an actor."))
    ElseIf option == skyrimNetOStimTraceOption
        SetInfoText(MMELocalization.Text("Show Skyrim.Net breastfeeding action selection, semantic roles, OStim routing, and startup. If no SN BF intent appears, another action was selected before this mod ran."))
    ElseIf option == skyrimNetSexLabTraceOption
        SetInfoText(MMELocalization.Text("Trace a Skyrim.Net breastfeeding request through actor validation, acquisition, SexLab startup, and MME Mode 4 confirmation."))
    ElseIf option == skyrimNetStatusOption
        SetInfoText("Read-only. Enabled when SkyrimNet.esp is active in the load order.")
    ElseIf option == skyrimNetMilkStatusesOption
        SetInfoText(MMELocalization.Text("Include current milk amounts, fullness and confirmed leaking in each Milk Maid's Skyrim.Net prompt. Current state takes precedence over older memories."))
    ElseIf option == skyrimNetStatusIntervalOption
        SetInfoText(MMELocalization.Text("Retired: milk and armor state are read when actor prompts render. The saved interval is preserved for compatibility."))
    ElseIf option == milkFullNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for one immediate Milk Maid reaction at full capacity. Uses LLM tokens."))
    ElseIf option == milkFullNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the global real-time delay between token-using milk-full narrations."))
    ElseIf option == milkFullNarrationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report milk-full narration triggers, cooldowns, payload calls, and API results."))
    ElseIf option == milkHalfFullNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for one immediate Milk Maid reaction at half capacity. Uses LLM tokens."))
    ElseIf option == milkHalfFullNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the global real-time delay between token-using half-full narrations."))
    ElseIf option == milkHalfFullNarrationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report half-full narration triggers, cooldowns, payload calls, and API results."))
    ElseIf option == playerDrinkNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for one immediate reaction after you drink recognized milk. Uses LLM tokens."))
    ElseIf option == playerDrinkNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the global real-time delay between token-using player drink narrations."))
    ElseIf option == playerDrinkNarrationChanceOption
        SetInfoText(MMELocalization.Text("Set the chance that an eligible player drink requests narration after normal drink tracking."))
    ElseIf option == playerDrinkNarrationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report player drink narration detection, cooldowns, and API results."))
    ElseIf option == milkmaidCreatedNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for one immediate reaction when an actor becomes a new Milk Maid. Uses LLM tokens."))
    ElseIf option == milkmaidCreatedNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the global real-time delay between token-using new-Milk-Maid narrations."))
    ElseIf option == milkmaidCreatedNarrationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report new-Milk-Maid narration detection, cooldowns, and API results."))
    ElseIf option == armorStrippingCheckDiagnosticOption
        SetInfoText(MMELocalization.Text("Report the full armor stripping transaction: drink attempt, delayed timer, milk values, slot 32, armor type, threshold, override state, protection, and strip result."))
    ElseIf option == armorStripNotificationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report armor-strip notification triggers, feature state, and shown/skipped results."))
    ElseIf option == armorStripMoanDiagnosticOption
        SetInfoText(MMELocalization.Text("Report armor-strip moan triggers, feature state, sound lookup, and playback results."))
    ElseIf option == armorStripNarrationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report armor-strip narration triggers, gates, chance, cooldown, and Skyrim.Net results."))
    ElseIf option == extensionsArmorStrippingOption
        SetInfoText(MMELocalization.Text("Take over armor stripping from Milk Mod Economy. While enabled, MME's original stripping is disabled and these fullness thresholds are used instead."))
    ElseIf option == milkingEquipmentRefitOption
        SetInfoText(MMELocalization.Text("After the player's personal Maid Level increases, ordinary Milking Equipment and unlocked Dwemer Armor follow normal fullness stripping rules until a blacksmith refits them. Timed locks, Devious Devices, Living Armor, Parasite Armor, and original MME cuirasses remain protected."))
    ElseIf option == repeatOrdinaryArmorStoriesOption
        SetInfoText(MMELocalization.Text("Replay Living, Parasite, or Dwemer armor stories for ordinary player/NPC equips and successful blacksmith, alchemist, or court-wizard installations. Chest traps use their separate Misc toggle; timed-lock recovery is excluded. Default on."))
    ElseIf option == armorCheckReminderOption
        SetInfoText(MMELocalization.Text("Show one brief notification when an eligible blacksmith, alchemist, or court wizard notices the armor state recognized by MME."))
    ElseIf option == armorCheckReminderCooldownOption
        SetInfoText(MMELocalization.Text("Set the real-time delay after a service armor reminder appears before another eligible conversation can show one."))
    ElseIf option == stripAllArmorOverrideOption
        SetInfoText(MMELocalization.Text("Temporary workaround: ignore MME armor protection classification and strip whatever is in slot 32 when the fullness threshold says strip. Devious Devices and SexLab no-strip protections still apply."))
    ElseIf option == armorStripHeavyEnabledOption
        SetInfoText(MMELocalization.Text("Allow milk fullness to remove heavy slot-32 armor. Disable this to protect all heavy body armor regardless of fullness."))
    ElseIf option == armorStripHeavyThresholdOption
        SetInfoText(MMELocalization.Text("Unequip heavy body armor when the player's fullness reaches this percentage. Use the Heavy Armor toggle to forbid stripping this category."))
    ElseIf option == armorStripLightEnabledOption
        SetInfoText(MMELocalization.Text("Allow milk fullness to remove light slot-32 armor. Disable this to protect all light body armor regardless of fullness."))
    ElseIf option == armorStripLightThresholdOption
        SetInfoText(MMELocalization.Text("Unequip light body armor when the player's fullness reaches this percentage. Use the Light Armor toggle to forbid stripping this category."))
    ElseIf option == armorStripClothingEnabledOption
        SetInfoText(MMELocalization.Text("Allow milk fullness to remove slot-32 clothing and untyped outfits. Disable this to protect the entire clothing category."))
    ElseIf option == armorStripClothingThresholdOption
        SetInfoText(MMELocalization.Text("Unequip clothing when the player's fullness reaches this percentage. Use the Clothing toggle to forbid stripping this category."))
    ElseIf option == armorStripNotificationOption
        SetInfoText(MMELocalization.Text("Show a notification when milk fullness forces your worn armor or clothing off."))
    ElseIf option == armorStripMoanOption
        SetInfoText(MMELocalization.Text("Play a strong reaction moan when milk fullness forces your worn armor or clothing off."))
    ElseIf option == armorStripNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for an immediate exaggerated reaction when milk fullness forces armor or clothing off. Uses LLM tokens."))
    ElseIf option == armorStripNarrationChanceOption
        SetInfoText(MMELocalization.Text("Set the chance that an eligible armor-strip event requests Skyrim.Net narration."))
    ElseIf option == armorStripNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the minimum real-time delay between successful armor-strip narrations."))
    ElseIf option == armorDebugOption
        SetInfoText(MMELocalization.Text("Report armor classification, matched MME list, equip reactions, nearby tracking, narration gates, and Skyrim.Net results."))
    ElseIf option == armorLookupForensicsOption
        SetInfoText(MMELocalization.Text("Log the live MME armor-name arrays and exact Find() results at the instant each armor protection/classification decision is made. Papyrus log only."))
    ElseIf option == playerMilkingArmorEquipMoanOption || option == npcMilkingArmorEquipMoanOption
        SetInfoText(MMELocalization.Text("Play the mild equip moan whenever the matching Milk Maid equips supported Milking Armor."))
    ElseIf option == playerMilkingArmorEquipAnimationOption || option == npcMilkingArmorEquipAnimationOption
        SetInfoText(MMELocalization.Text("Play the shared three-second Standing reaction whenever supported Milking Armor is equipped."))
    ElseIf option == playerLivingArmorEquipMoanOption || option == npcLivingArmorEquipMoanOption
        SetInfoText(MMELocalization.Text("Play the strongest equip moan pool whenever the matching Milk Maid equips configured AM Living Armor."))
    ElseIf option == playerLivingArmorEquipAnimationOption || option == npcLivingArmorEquipAnimationOption
        SetInfoText(MMELocalization.Text("Play the shared three-second Kneeling reaction whenever configured AM Living Armor is equipped."))
    ElseIf option == playerLivingParasiteEquipMoanOption || option == npcLivingParasiteEquipMoanOption
        SetInfoText(MMELocalization.Text("Play the strongest equip moan pool whenever the matching Milk Maid equips configured AM Living Parasite armor."))
    ElseIf option == playerLivingParasiteEquipAnimationOption || option == npcLivingParasiteEquipAnimationOption
        SetInfoText(MMELocalization.Text("Play the shared three-second Kneeling reaction whenever configured AM Living Parasite armor is equipped."))
    ElseIf option == nearbyMilkArmorStatusOption
        SetInfoText(MMELocalization.Text("Include the currently worn living, parasite, milking or Dwemer body armor in each Milk Maid actor prompt. Dwemer attachments are described separately from full suits."))
    ElseIf option == playerMilkArmorEquipNarrationOption
        SetInfoText(MMELocalization.Text("Directly narrate supported Player Milk Armor equips through Skyrim.Net."))
    ElseIf option == npcMilkArmorEquipNarrationOption
        SetInfoText(MMELocalization.Text("Directly narrate supported NPC Milk Maid armor equips through Skyrim.Net."))
    ElseIf option == playerMilkingArmorNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the global real-time delay between token-using Player Milking Armor narrations."))
    ElseIf option == npcMilkingArmorNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the global real-time delay between token-using NPC Milking Armor narrations."))
    ElseIf option == selfMilkingActionDiagnosticOption
        SetInfoText(MMELocalization.Text("Report self-milking action registration, Milk Maid checks, and spell requests."))
    ElseIf option == pairedMilkingActionDiagnosticOption
        SetInfoText(MMELocalization.Text("Report paired milking action registration, actor selection, dependency checks, and scene results."))
    ElseIf option == fullnessSelfMilkAnimationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report PLAYER/NPC fullness animation triggers, selected animation, start, skip, and reset reasons."))
    ElseIf option == milkDrinkAnimationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report whether PLAYER or NPC triggered the drink animation, what was detected, and why it started or skipped."))
    ElseIf option == npcDrinkNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for one immediate humorous and suggestive reaction after supported Give Milk dialogue or globally detected adult NPC milk drinking. Covers men, women, and Milkmaids. Uses LLM tokens."))
    ElseIf option == npcDrinkNarrationCooldownOption
        SetInfoText(MMELocalization.Text("Set the global real-time delay between token-using NPC drink narrations."))
    ElseIf option == npcDrinkNarrationDiagnosticOption
        SetInfoText(MMELocalization.Text("Report NPC drink detection, dialogue drinks, narration gates, cooldowns, and API results."))
    ElseIf option == skyrimNetMilkDrinksOption
        SetInfoText(MMELocalization.Text("Send recognized player milk drinks to SkyrimNet."))
    ElseIf option == skyrimNetMilkingEventsOption
        SetInfoText(MMELocalization.Text("Send nearby Milkmaid milking start and end events to SkyrimNet."))
    ElseIf option == skyrimNetMilkmaidCreatedOption
        SetInfoText(MMELocalization.Text("Record confirmed new Milkmaids in SkyrimNet event history."))
    ElseIf option == arousalStatusOption
        SetInfoText("Read-only. Enabled when SexLabAroused.esm is active.")
    ElseIf option == milkDrinkArousalOption
        SetInfoText(MMELocalization.Text("Optionally raise arousal after drinking recognized milk. The nearby Arousal Reactions monitor remains observational. Default gain is 0."))
    ElseIf option == milkDrinkArousalAmountOption
        SetInfoText(MMELocalization.Text("Set optional arousal added per recognized milk drink. Default 0; this does not control the observational Arousal Reactions monitor."))
    ElseIf option == arousalEffectsOption
        SetInfoText(MMELocalization.Text("Every five seconds, watch nearby adult humanoids for upward arousal-threshold crossings and select at most one random actor for a reaction. Includes the player. Default on."))
    ElseIf option == arousalEffectNotificationsOption
        SetInfoText(MMELocalization.Text("Show one random sex-appropriate notification for the selected actor and arousal tier. Default on."))
    ElseIf option == arousalEffectSoundsOption
        SetInfoText(MMELocalization.Text("Play the existing mild, medium, or strong sex-aware reaction sound for the selected actor. Also respects the global moaning-sounds toggle. Default on."))
    ElseIf option == arousalEffectAnimationsOption
        SetInfoText(MMELocalization.Text("Play a sex- and tier-specific three-second animation while holding the actor in place. Never starts in combat or an active scene. Requires rerunning Pandora, Nemesis, or FNIS after installation. Default on."))
    ElseIf option == arousalMilkMaidRouteOption
        SetInfoText(MMELocalization.Text("Allow established Milk Maids to react whenever they cross an arousal threshold. Combined with the other eligibility routes using OR logic. Default on."))
    ElseIf option == arousalMilkDrinkRouteOption
        SetInfoText(MMELocalization.Text("Allow any valid adult to react when a recognized milk drink directly raises them across an arousal threshold. Default on."))
    ElseIf option == arousalEveryoneRouteOption
        SetInfoText(MMELocalization.Text("Allow unrelated nearby adults to react to threshold crossings. Leave this off to keep reactions tied to Milk Maids and milk drinking."))
    ElseIf option == arousalEffectDelayOption
        SetInfoText(MMELocalization.Text("Wait before presenting a qualified threshold reaction, allowing the drink animation to finish. Default 5 seconds, range 0-60."))
    ElseIf option == arousalEffectCooldownOption
        SetInfoText(MMELocalization.Text("Minimum real-time delay between presented arousal reactions. Default 5 seconds, range 0-600 in 5-second steps."))
    ElseIf option == arousalEffectCooldownVariationOption
        SetInfoText(MMELocalization.Text("Randomly subtract or add up to this many seconds to each new reaction cooldown. Default 0 seconds."))
    ElseIf option == arousalLowThresholdOption
        SetInfoText(MMELocalization.Text("Minimum arousal for mild reactions. Must remain at least 5 points below Medium. Default 20."))
    ElseIf option == arousalMediumThresholdOption
        SetInfoText(MMELocalization.Text("Minimum arousal for noticeable reactions. Must remain between Low and High with 5-point gaps. Default 50."))
    ElseIf option == arousalHighThresholdOption
        SetInfoText(MMELocalization.Text("Minimum arousal for the strongest reactions. Must remain at least 5 points above Medium. Default 80."))
    ElseIf option == sexLabBreastfeedingDebugOption
        SetInfoText(MMELocalization.Text("Diagnose MME's original SexLab breastfeeding route when Hey there executes. Never changes eligibility."))
    ElseIf option == milkMaidThoughtsOption
        SetInfoText(MMELocalization.Text("Show occasional non-LLM flavor notifications about one nearby Milk Maid."))
    ElseIf option == milkMaidThoughtsIntervalOption
        SetInfoText(MMELocalization.Text("Set the base interval in Skyrim game-time hours. Each completed normal poll schedules a fresh interval."))
    ElseIf option == milkMaidThoughtsRandomnessOption
        SetInfoText(MMELocalization.Text("Randomly subtract or add up to this many game-time hours. The final interval never falls below two hours."))
    ElseIf option == milkMaidThoughtNarrationOption
        SetInfoText(MMELocalization.Text("Ask Skyrim.Net for a direct, AI-generated reaction to each normal game-hour Thought. The 15-second test remains local-only."))
    ElseIf option == armorThoughtSoundsOption
        SetInfoText(MMELocalization.Text("Play a mild or hot reaction sound on the selected Milk Maid when an Armor Thought appears. The global reaction-sound setting must also be enabled."))
    ElseIf option == boundMilkMaidThoughtsOption
        SetInfoText(MMELocalization.Text("When Devious Devices is present, select one nearby Milk Maid wearing the heavy-bondage keyword and send her JSON Thought to Skyrim.Net. Milk fullness is not required."))
    ElseIf option == boundMilkMaidThoughtsIntervalOption
        SetInfoText(MMELocalization.Text("Set the independent base delay between bound Milk Maid Thought attempts in game-time hours."))
    ElseIf option == boundMilkMaidThoughtsRandomnessOption
        SetInfoText(MMELocalization.Text("Randomly subtract or add this many game-time hours. Randomness is automatically capped so the final interval never falls below one hour; a one-hour base disables randomness."))
    ElseIf option == boundMilkMaidThoughtsChanceOption
        SetInfoText(MMELocalization.Text("Set the chance that a due bound Thought proceeds after at least one eligible restrained Milk Maid is found."))
    ElseIf option == boundMilkMaidThoughtNarrationOption
        SetInfoText(MMELocalization.Text("Let a successful local bound Thought request a targeted Skyrim.Net reaction. Disabling this does not suppress the HUD Thought."))
    ElseIf option == boundMilkMaidThoughtNarrationChanceOption
        SetInfoText(MMELocalization.Text("Set the chance that a successful local bound Thought is also sent to Skyrim.Net."))
    ElseIf option == boundMilkMaidThoughtSoundsOption
        SetInfoText(MMELocalization.Text("Play a hot reaction moan on the selected restrained Milk Maid when a bound Thought appears. The global Reaction Sounds setting must also be enabled."))
    ElseIf option == boundMilkDrinkReactionOption
        SetInfoText(MMELocalization.Text("After a confirmed milk drink, let an existing Milk Maid in Devious heavy bondage trigger the complete bound notification, moan, and optional Skyrim.Net reaction."))
    ElseIf option == boundMilkDrinkReactionChanceOption
        SetInfoText(MMELocalization.Text("Set the independent chance that an eligible restrained Milk Maid reacts after drinking milk. This does not use or reset the hourly bound Thought chance or schedule."))
    ElseIf option == milkMaidThoughtsDebugOption
        SetInfoText(MMELocalization.Text("Attempt one local Thought notification every 15 real-time seconds using the controller's shared single-update scheduler. Debug Thoughts are not mirrored to Skyrim.Net."))
    ElseIf option == traceMilkMaidThoughtsLogicOption
        SetInfoText(MMELocalization.Text("Show an in-game notification explaining why a 15-second Thought attempt was skipped."))
    ElseIf option == armorInjectionOption
        SetInfoText(MMELocalization.Text("Periodically let nearby Milk Maids wearing Living or Parasite Armor receive the configured milk and arousal bonuses."))
    ElseIf option == armorInjectionIntervalOption
        SetInfoText(MMELocalization.Text("Set the base delay between checks in game-time hours. The maximum is 36 game days."))
    ElseIf option == armorInjectionVariationOption
        SetInfoText(MMELocalization.Text("Randomly subtract or add up to this many game-time hours. The final interval never falls below one hour."))
    ElseIf option == armorInjectionChanceOption
        SetInfoText(MMELocalization.Text("Set each eligible Milk Maid's independent chance to be affected during a check."))
    ElseIf option == armorInjectionNotificationOption
        SetInfoText(MMELocalization.Text("Show one flavor notification per successful cycle, with '...and others.' when several Milk Maids are affected."))
    ElseIf option == armorInjectionSoundOption
        SetInfoText(MMELocalization.Text("Play the existing random low sound on the affected wearer when an effect notification appears. Uses the global sound toggle and volume. Independent of Skyrim.Net narration."))
    ElseIf option == armorInjectionDiagnosticOption
        SetInfoText(MMELocalization.Text("Report nearby Milk Maids, armor classes, effects, focus, and narration chance/results or skip reasons."))
    ElseIf option == armorInjectionNarrationOption
        SetInfoText(MMELocalization.Text("Let the focused armor wearer react through Skyrim.Net after a successful check. Gameplay and HUD notifications are independent."))
    ElseIf option == armorInjectionPlayerNarrationOption
        SetInfoText(MMELocalization.Text("Let the affected player speak about herself. When off, a check focused on the player sends no narration and does not select an NPC instead. Requires Skyrim.Net Narration above."))
    ElseIf option == armorInjectionNarrationChanceOption
        SetInfoText(MMELocalization.Text("Chance of one Skyrim.Net request per successful effect check. Only confirmed milk/arousal increases are described. Default 100%."))
    ElseIf option == runArmorInjectionCheckOption
        SetInfoText(MMELocalization.Text("Run the real Tentacle Effects production path immediately without waiting for its timer."))
    ElseIf option == dwemerEffectOption
        SetInfoText(MMELocalization.Text("Periodically apply the configured milk and arousal bonuses to nearby Milk Maids wearing independent class-4 Dwemer Armor."))
    ElseIf option == dwemerEffectIntervalOption
        SetInfoText(MMELocalization.Text("Set the independent base delay between Dwemer checks in game-time hours."))
    ElseIf option == dwemerEffectVariationOption
        SetInfoText(MMELocalization.Text("Randomly subtract or add this many game-time hours. The final interval never falls below one hour."))
    ElseIf option == dwemerEffectChanceOption
        SetInfoText(MMELocalization.Text("Set each eligible Dwemer Armor wearer's independent chance to be affected during a check."))
    ElseIf option == dwemerEffectNotificationOption
        SetInfoText(MMELocalization.Text("Show one JSON-driven Dwemer flavor notification per successful cycle."))
    ElseIf option == dwemerEffectSoundOption
        SetInfoText(MMELocalization.Text("Play the existing low reaction sound on the notification wearer. Uses the global sound toggle and volume."))
    ElseIf option == dwemerEffectDiagnosticOption
        SetInfoText(MMELocalization.Text("Show detailed Dwemer candidate and effect results. Master Papyrus Logging records sparse footprints independently."))
    ElseIf option == dwemerEffectNarrationOption
        SetInfoText(MMELocalization.Text("Let the focused Dwemer Armor wearer react through Skyrim.Net after a successful effect."))
    ElseIf option == dwemerEffectPlayerNarrationOption
        SetInfoText(MMELocalization.Text("Allow player-only TTS when the affected wearer is the player. No NPC fallback is selected when disabled."))
    ElseIf option == dwemerEffectNarrationChanceOption
        SetInfoText(MMELocalization.Text("Chance of one Skyrim.Net request per successful Dwemer effect check."))
    ElseIf option == runDwemerEffectCheckOption
        SetInfoText(MMELocalization.Text("Run the real Dwemer Effects production path immediately without waiting for its timer."))
    ElseIf option == diagnosticNotificationsOption
        SetInfoText(MMELocalization.Text("Show short audit results as in-game notifications. Enabled by default."))
    ElseIf option == papyrusTraceOption
        SetInfoText(MMELocalization.Text("Record useful feature milestones, state changes, and rejection reasons in Papyrus.0.log. Logging is off by default and does not control gameplay."))
    ElseIf option == verbosePapyrusTraceOption
        SetInfoText(MMELocalization.Text("Record high-volume audit, timing, animation, API, lookup, and transaction details. Enable only while reproducing a problem. Requires Papyrus Logging."))
    ElseIf option == diagnosticRefreshGateOption
        SetInfoText(MMELocalization.Text("Recalculate the shared OStim dialogue gate without relying on the optional native DLL."))
    ElseIf option == diagnosticInstallAuditOption
        SetInfoText(MMELocalization.Text("Check the controller, MME, OStim, dialogue records, setting, and live dialogue gate."))
    ElseIf option == diagnosticMilkDrinkAuditOption
        SetInfoText(MMELocalization.Text("Trace the player milk-drink route through quest, alias, tracker attachment, settings, supported forms, equip event, and accepted drink stages."))
    ElseIf option == diagnosticSpawnOManiaPotionOption
        SetInfoText(MMELocalization.Text("Add exactly one OMania Dragon Egg Concoction to the player. This manual test does not change pregnancy state or use a one-time latch."))
    ElseIf option == diagnosticGlobalNPCDrinkTestOption
        SetInfoText(MMELocalization.Text("Simulate a global HearthFires milk consumption on the crosshair adult NPC. Inventory is untouched; configured gameplay effects are real. Skyrim.Net narration bypasses cooldown for this test and writes a short Papyrus route."))
    ElseIf option == diagnosticDialogueAuditOption
        SetInfoText(MMELocalization.Text("Check whether the NPC under your crosshair and the player satisfy the New Milk Maid runtime requirements."))
    ElseIf option == diagnosticNewMilkmaidSexLabBusOption
        SetInfoText(MMELocalization.Text("Automatically test the enabled OStim or SexLab New Milk Maid route against the crosshair NPC. Stops 01-05 are immediate; selecting the dialogue continues stops 06-16. Trace toggles are optional."))
    ElseIf option == diagnosticRefreshSexLabBusOption
        SetInfoText(MMELocalization.Text("Repair AnimationEnding, AnimationEnd, and timeout listeners on an existing save."))
    ElseIf option == diagnosticShowSexLabBusOption
        SetInfoText(MMELocalization.Text("Show the persistent last bus stop or failure as one in-game notification and Papyrus trace line."))
    ElseIf option == diagnosticBlacksmithBusOption
        SetInfoText(MMELocalization.Text("Audit the crosshair NPC, player Milk Maid state, slot-32 armor, protected precedence, and MME registry without changing anything. A passing preflight waits for the live greeting trace."))
    ElseIf option == diagnosticShowBlacksmithBusOption
        SetInfoText(MMELocalization.Text("Show the persistent Blacksmith dialogue bus state, last stop, or failure as one readable notification."))
    ElseIf option == diagnosticAlchemistBusOption
        SetInfoText(MMELocalization.Text("Audit the crosshair Alchemist, player Milk Maid state, slot-32 armor, protected precedence, and BasicLivingArmor registry without changing anything."))
    ElseIf option == diagnosticShowAlchemistBusOption
        SetInfoText(MMELocalization.Text("Show the persistent Alchemist dialogue bus state, last stop, or failure as one readable notification."))
    ElseIf option == diagnosticMageBusOption
        SetInfoText(MMELocalization.Text("Audit the crosshair court wizard, player Milk Maid state, slot-32 armor, protected precedence, and ParasiteLivingArmor registry without changing anything."))
    ElseIf option == diagnosticShowMageBusOption
        SetInfoText(MMELocalization.Text("Show the persistent Mage dialogue bus state, last stop, or failure as one readable notification."))
    ElseIf option == diagnosticInstallStatusOption
        SetInfoText("Read-only status for the quest and New Milk Maid dialogue records in MMEAlert.esp.")
    ElseIf option == diagnosticOStimStatusOption
        SetInfoText(MMELocalization.Text("Read-only OStim plugin and MCM setting status."))
    ElseIf option == diagnosticSexLabStatusOption
        SetInfoText(MMELocalization.Text("Read-only SexLab status. NOT ACTIVATED means SexLab is installed but still needs activation in its own MCM."))
    ElseIf option == diagnosticGateStatusOption
        SetInfoText(MMELocalization.Text("Read-only value used by the original OStim and New Milk Maid dialogue choices."))
    ElseIf option == diagnosticSexLabBusStateOption
        SetInfoText(MMELocalization.Text("Persistent SexLab New Milk Maid route state: IDLE, RUNNING, FAILED, or COMPLETE."))
    ElseIf option == diagnosticSexLabBusStopOption
        SetInfoText(MMELocalization.Text("The latest persisted bus stop and message, retained after the scene ends."))
    ElseIf option == diagnosticSexLabBusFailureOption
        SetInfoText(MMELocalization.Text("The last persisted failing stop, or none when the current test has not failed."))
    ElseIf option == diagnosticBlacksmithBusStateOption
        SetInfoText(MMELocalization.Text("Persistent Blacksmith route state: IDLE, RUNNING, WAITING, BLOCKED, FAILED, or COMPLETE."))
    ElseIf option == diagnosticBlacksmithBusStopOption
        SetInfoText(MMELocalization.Text("The latest Blacksmith bus stop. Stops 12-13 require selecting [MME] Hey there! while the live trace is enabled."))
    ElseIf option == diagnosticBlacksmithBusFailureOption
        SetInfoText(MMELocalization.Text("The last structural or runtime failure. Legitimate eligibility exclusions are reported as BLOCKED instead."))
    ElseIf option == diagnosticAlchemistBusStateOption
        SetInfoText(MMELocalization.Text("Persistent Alchemist route state: IDLE, RUNNING, WAITING, BLOCKED, FAILED, or COMPLETE."))
    ElseIf option == diagnosticAlchemistBusStopOption
        SetInfoText(MMELocalization.Text("The latest Alchemist bus stop. Stops 12-13 require selecting [MME] Hey there! while the live trace is enabled."))
    ElseIf option == diagnosticAlchemistBusFailureOption
        SetInfoText(MMELocalization.Text("The last Alchemist structural or runtime failure. Eligibility exclusions are BLOCKED."))
    ElseIf option == diagnosticMageBusStateOption
        SetInfoText(MMELocalization.Text("Persistent Mage route state: IDLE, RUNNING, WAITING, BLOCKED, FAILED, or COMPLETE."))
    ElseIf option == diagnosticMageBusStopOption
        SetInfoText(MMELocalization.Text("The latest Mage bus stop. Stops 12-13 require selecting [MME] Hey there! while the live trace is enabled."))
    ElseIf option == diagnosticMageBusFailureOption
        SetInfoText(MMELocalization.Text("The last Mage structural or runtime failure. Eligibility exclusions are BLOCKED."))
    ElseIf option == blacksmithDialogueTraceOption
        SetInfoText(MMELocalization.Text("Trace the Blacksmith Add/Remove route when [MME] Hey there! opens, then report whether the expected INFO became visible. Default off."))
    ElseIf option == alchemistDialogueTraceOption
        SetInfoText(MMELocalization.Text("Trace the Alchemist Living Armor Add/Remove route when [MME] Hey there! opens. Default off."))
    ElseIf option == mageDialogueTraceOption
        SetInfoText(MMELocalization.Text("Trace the Mage Parasite Armor Add/Remove route when [MME] Hey there! opens. Default off."))
    EndIf
EndEvent

; Persists toggle changes and refreshes only controllers affected by that option.
Event OnOptionSelect(Int option)
    If option == fullHistoryOption
        Int postValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetFullEvents", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetFullEvents", postValue)
        JsonUtil.Save(SettingsFile, False)
        ForcePageReset()
        Return
    EndIf
    If option == postMilkingNarrationOption
        Int postValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePostMilkingNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePostMilkingNarration", postValue)
        JsonUtil.Save(SettingsFile, False)
        ForcePageReset()
        Return
    EndIf
    If option == rosterOpenOption
        If RosterUiAvailable() && JsonUtil.GetIntValue(SettingsFile, "enableMMEExtensions", 1) == 1 && JsonUtil.GetIntValue(SettingsFile, "maidRosterUiEnabled", 1) == 1
            SendModEvent("MMEExtensions_RosterOpen")
            SetTextOptionValue(option, MMELocalization.Text("Close MCM to open"))
            MMELog.MasterDiagnostic("[MME Maid Roster UI] open queued | source=MCM")
        EndIf
        Return
    ElseIf option == rosterEnabledOption
        Int rosterEnabled = 1 - JsonUtil.GetIntValue(SettingsFile, "maidRosterUiEnabled", 1)
        JsonUtil.SetIntValue(SettingsFile, "maidRosterUiEnabled", rosterEnabled)
        JsonUtil.Save(SettingsFile, False)
        SendModEvent("MMEExtensions_RosterSettings")
        ForcePageReset()
        Return
    EndIf
    If option == narrationReloadOption
        Int narrationLoaded = MMENarrationText.ReloadAll()
        SetTextOptionValue(option, (narrationLoaded as String) + MMELocalization.Text(" complete files"))
        Return
    ElseIf option == narrationImportOption
        Debug.MessageBox(MMENarrationText.ImportLegacy())
        Return
    EndIf
    If option == movementSlapNotificationsOption
        Int enabled = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMovementSlapNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMovementSlapNotifications", enabled)
        JsonUtil.Save(SettingsFile, False)
        MMELog.MasterDiagnostic("[MME Extensions Movement Slap] notification setting changed | enabled=" + enabled)
        ForcePageReset()
        Return
    EndIf
    If option == movementSlapOption
        Int enabled = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMovementSlap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMovementSlap", enabled)
        JsonUtil.Save(SettingsFile, False)
        RefreshMovementSlapSettings()
        ForcePageReset()
        Return
    ElseIf option == flatMilkStrippingOption
        Int enabled = 1 - JsonUtil.GetIntValue(SettingsFile, "enableFlatMilkStripping", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableFlatMilkStripping", enabled)
        JsonUtil.Save(SettingsFile, False)
        ForcePageReset()
        Return
    EndIf
    If option == timedArmorReleaseOption
        MMETimedArmorLock.Release(Game.GetPlayer(), "MCM Debug")
        ForcePageReset()
        Return
    ElseIf option == timedNPCArmorReleaseOption
        MMEFollowerArmorRescue.TryDebugRescueNearbyCompanions()
        ForcePageReset()
        Return
    ElseIf option == chestArmorTrapOption
        Int armorTrapValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableChestArmorTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestArmorTrap", armorTrapValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, armorTrapValue == 1)
        ForcePageReset()
        Return
    ElseIf option == armorTrapNearbyAlliesOption
        Int armorAlliesValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorTrapNearbyAllies", armorAlliesValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, armorAlliesValue == 1)
        Return
    ElseIf option == repeatTrapArmorStoriesOption
        Int repeatTrapStoryValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableRepeatTrapArmorStories", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableRepeatTrapArmorStories", repeatTrapStoryValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, repeatTrapStoryValue == 1)
        Return
    ElseIf option == livingArmorChestTrapOption
        Int livingTrapValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableLivingArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableLivingArmorChestTrap", livingTrapValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, livingTrapValue == 1)
        Return
    ElseIf option == parasiteArmorChestTrapOption
        Int parasiteTrapValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableParasiteArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableParasiteArmorChestTrap", parasiteTrapValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, parasiteTrapValue == 1)
        Return
    ElseIf option == dwemerArmorChestTrapOption
        Int dwemerTrapValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDwemerArmorChestTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDwemerArmorChestTrap", dwemerTrapValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, dwemerTrapValue == 1)
        ForcePageReset()
        Return
    ElseIf option == dwemerArmorOutsideRuinsOption
        Int outsideValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDwemerArmorOutsideRuins", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDwemerArmorOutsideRuins", outsideValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, outsideValue == 1)
        Return
    ElseIf option == milkMaidCurseMasterOption
        Int curseValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidCurseTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidCurseTrap", curseValue)
        JsonUtil.Save(SettingsFile, False)
        MMELog.MasterDiagnostic("[MME Extensions Milk Maid Curse] chest master changed | enabled=" + curseValue)
        ForcePageReset()
        Return
    ElseIf option == dungeonChestMilkMaidOption
        Int dungeonChestValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDungeonChestMilkMaid", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDungeonChestMilkMaid", dungeonChestValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, dungeonChestValue == 1)
        ForcePageReset()
        Return
    ElseIf option == milkMaidTrapNearbyAlliesOption
        Int maidAlliesValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidTrapNearbyAllies", maidAlliesValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, maidAlliesValue == 1)
        Return
    ElseIf option == regularChestMilkMaidOption
        Int regularChestValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableRegularChestMilkMaid", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableRegularChestMilkMaid", regularChestValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, regularChestValue == 1)
        ForcePageReset()
        Return
    ElseIf option == chestMilkTrapOption
        Int chestMilkTrapValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableChestMilkTrap", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrap", chestMilkTrapValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, chestMilkTrapValue == 1)
        ForcePageReset()
        Return
    ElseIf option == milkDrinkTrapNearbyAlliesOption
        Int drinkAlliesValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkTrapNearbyAllies", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkTrapNearbyAllies", drinkAlliesValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, drinkAlliesValue == 1)
        Return
    ElseIf option == chestMilkTrapNotificationOption
        Int chestNotificationValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableChestMilkTrapNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrapNotification", chestNotificationValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, chestNotificationValue == 1)
        Return
    ElseIf option == chestMilkTrapNarrationOption
        Int chestNarrationValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableChestMilkTrapNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestMilkTrapNarration", chestNarrationValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, chestNarrationValue == 1)
        Return
    ElseIf option == innPalaceMilkDrinkingOption
        Int innPalaceValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableInnPalaceMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableInnPalaceMilkDrinking", innPalaceValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, innPalaceValue == 1)
        ForcePageReset()
        Return
    ElseIf option == guildTavernMilkDrinkingOption
        Int guildTavernValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableGuildTavernMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableGuildTavernMilkDrinking", guildTavernValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, guildTavernValue == 1)
        Return
    ElseIf option == jarlResidenceMilkDrinkingOption
        Int jarlResidenceValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableJarlResidenceMilkDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableJarlResidenceMilkDrinking", jarlResidenceValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, jarlResidenceValue == 1)
        Return
    ElseIf option == townMilkDrinkOption
        Int townDrinkValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableTownMilkDrink", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableTownMilkDrink", townDrinkValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, townDrinkValue == 1)
        ForcePageReset()
        Return
    ElseIf option == townUniqueNPCPreferenceOption
        Int uniquePreferenceValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableTownUniqueNPCPreference", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableTownUniqueNPCPreference", uniquePreferenceValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, uniquePreferenceValue == 1)
        ForcePageReset()
        Return
    ElseIf option == milkCravingsOption
        Int cravingValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkCravings", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkCravings", cravingValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, cravingValue == 1)
        RefreshMilkCravingSchedule()
        ForcePageReset()
        Return
    ElseIf option == milkCravingNarrationOption
        Int cravingNarrationValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkCravingNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkCravingNarration", cravingNarrationValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, cravingNarrationValue == 1)
        Return
    ElseIf option == autoSelfMilkingOption
        Int autoSelfMilkingValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableAutoSelfMilking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableAutoSelfMilking", autoSelfMilkingValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, autoSelfMilkingValue == 1)
        RefreshAutoSelfMilkingSchedule()
        ForcePageReset()
        Return
    ElseIf option == forcedMilkMaidNotificationOption
        Int notificationValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidNotification", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidNotification", notificationValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, notificationValue == 1)
        Return
    ElseIf option == forcedMilkMaidLactacidStoryOption
        Int storyValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidStory", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidStory", storyValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, storyValue == 1)
        Return
    ElseIf option == forcedMilkMaidNarrationOption
        Int narrationValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidNarration", narrationValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, narrationValue == 1)
        ForcePageReset()
        Return
    ElseIf option == chestCurseNarrationOption
        Int chestNarrationValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableChestCurseNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableChestCurseNarration", chestNarrationValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, chestNarrationValue == 1)
        MMELog.MasterDiagnostic("[MME Chest Curse Narration] setting changed | enabled=" + chestNarrationValue)
        Return
    ElseIf option == forcedMilkMaidDiagnosticOption
        Int diagnosticValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableForcedMilkMaidDiagnostic", diagnosticValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, diagnosticValue == 1)
        Return
    EndIf
    If option == reverseTraceOption
        Int traceValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableReverseLevelTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableReverseLevelTrace", traceValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, traceValue == 1)
        Return
    EndIf
    If option == reverseApplyOption || option == reverseRemoveOption
        MMEReverseLevel reverseService = MMEReverseLevel.GetService()
        If reverseService == None
            Debug.Notification(MMELocalization.Text("Reverse leveling requires the SSEEdit installer step."))
        ElseIf option == reverseApplyOption
            reverseService.ApplyReverseLeveling()
        Else
            reverseService.RemoveReverseLeveling()
        EndIf
        Return
    EndIf
    ; Each branch commits one setting and performs only the minimal live refresh
    ; required by that feature (controller polling, action registration, etc.).
    If option == masterEnableOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMMEExtensions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMMEExtensions", value)
        SetToggleOptionValue(option, value == 1)
        JsonUtil.Save(SettingsFile, False)
        SendModEvent("MMEExtensions_RosterSettings")
        MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If controller != None
            If value == 1
                controller.InitializeController(True)
            Else
                controller.DisableController()
                MMEReverseLevel reverseService = MMEReverseLevel.GetService()
                If reverseService != None
                    reverseService.RemoveReverseLeveling(False)
                EndIf
            EndIf
        EndIf
    ElseIf option == breastBounceNotificationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBreastBounceNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastBounceNotifications", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        RefreshBreastBounceSchedule()
    ElseIf option == breastBounceSoundOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBreastBounceSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastBounceSounds", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        RefreshBreastBounceSchedule()
    ElseIf option == soundsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableReactionSounds", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        RefreshMovementSlapSettings()
        ForcePageReset()
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
    ElseIf option == newMilkMaidMoansOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNewMilkMaidMoans", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkMaidMoans", value)
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
    ElseIf option == milkMaidThoughtsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughts", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughts", value)
        SetToggleOptionValue(option, value == 1)
        RefreshThoughtSchedule()
    ElseIf option == milkMaidThoughtNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughtNarration", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorThoughtSoundsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorThoughtSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorThoughtSounds", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == boundMilkMaidThoughtsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkMaidThoughts", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughts", value)
        SetToggleOptionValue(option, value == 1)
        RefreshBoundThoughtSchedule()
    ElseIf option == boundMilkMaidThoughtNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkMaidThoughtNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughtNarration", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == boundMilkMaidThoughtSoundsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkMaidThoughtSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkMaidThoughtSounds", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == boundMilkDrinkReactionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkDrinkReaction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBoundMilkDrinkReaction", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == milkMaidThoughtsDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", value)
        SetToggleOptionValue(option, value == 1)
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
    ElseIf option == traceMilkMaidThoughtsLogicOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "traceMilkMaidThoughtsLogic", 0)
        JsonUtil.SetIntValue(SettingsFile, "traceMilkMaidThoughtsLogic", value)
        SetToggleOptionValue(option, value == 1)
        If value == 1 && JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0) != 1
            Debug.Notification(MMELocalization.Text("Thoughts trace enabled; turn on 15 Second Thoughts to run checks"))
        EndIf
    ElseIf option == armorInjectionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorInjections", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjections", value)
        SetToggleOptionValue(option, value == 1)
        RefreshArmorInjectionSchedule(False)
    ElseIf option == armorInjectionSoundOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionSounds", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorInjectionNotificationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionNotifications", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorInjectionDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionDiagnostics", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionDiagnostics", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorInjectionNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionNarration", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorInjectionPlayerNarrationOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionPlayerNarration", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorInjectionPlayerNarration", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == runArmorInjectionCheckOption
        MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If controller != None
            controller.RunArmorInjectionCheckNow()
        Else
            Debug.Notification(MMELocalization.Text("Tentacle Effects: controller unavailable"))
        EndIf
    ElseIf option == dwemerEffectOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDwemerEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDwemerEffects", value)
        SetToggleOptionValue(option, value == 1)
        RefreshDwemerEffectSchedule()
    ElseIf option == dwemerEffectSoundOption
        ToggleArmorSetting(option, "enableDwemerEffectSounds", 1)
    ElseIf option == dwemerEffectNotificationOption
        ToggleArmorSetting(option, "enableDwemerEffectNotifications", 1)
    ElseIf option == dwemerEffectDiagnosticOption
        ToggleArmorSetting(option, "enableDwemerEffectDiagnostics", 0)
    ElseIf option == dwemerEffectNarrationOption
        ToggleArmorSetting(option, "enableDwemerEffectNarration", 1)
    ElseIf option == dwemerEffectPlayerNarrationOption
        ToggleArmorSetting(option, "enableDwemerEffectPlayerNarration", 1)
    ElseIf option == runDwemerEffectCheckOption
        MMEAlertsController dwemerController = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If dwemerController != None
            dwemerController.RunDwemerEffectCheckNow()
        Else
            Debug.Notification(MMELocalization.Text("Dwemer Effects: controller unavailable"))
        EndIf
    ElseIf option == diagnosticNotificationsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDiagnosticNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDiagnosticNotifications", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == papyrusTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePapyrusTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enablePapyrusTrace", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == verbosePapyrusTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableVerbosePapyrusLogging", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableVerbosePapyrusLogging", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == diagnosticRefreshGateOption
        MMEDiagnostics.RefreshDialogueGate()
        ForcePageReset()
    ElseIf option == diagnosticInstallAuditOption
        MMEDiagnostics.RunInstallAudit()
    ElseIf option == diagnosticMilkDrinkAuditOption
        MMEDiagnostics.RunMilkDrinkAudit()
    ElseIf option == diagnosticSpawnOManiaPotionOption
        MMEOManiaCompatibility.SpawnDragonEggPotion(Game.GetPlayer())
    ElseIf option == diagnosticGlobalNPCDrinkTestOption
        MMEDiagnostics.RunGlobalNPCDrinkTest()
    ElseIf option == diagnosticDialogueAuditOption
        MMEDiagnostics.RunCrosshairDialogueAudit()
    ElseIf option == diagnosticNewMilkmaidSexLabBusOption
        MMEDiagnostics.RunNewMilkMaidSexLabBusTest()
        ForcePageReset()
    ElseIf option == diagnosticRefreshSexLabBusOption
        MMEDiagnostics.RefreshNewMilkMaidSexLabBus()
        ForcePageReset()
    ElseIf option == diagnosticShowSexLabBusOption
        MMEDiagnostics.ShowNewMilkMaidSexLabBusReport()
        ForcePageReset()
    ElseIf option == diagnosticBlacksmithBusOption
        MMEDiagnostics.RunBlacksmithDialogueBusTest()
        ForcePageReset()
    ElseIf option == diagnosticShowBlacksmithBusOption
        MMEDiagnostics.ShowBlacksmithDialogueBusReport(True)
        ForcePageReset()
    ElseIf option == diagnosticAlchemistBusOption
        MMEDiagnostics.RunAlchemistDialogueBusTest()
        ForcePageReset()
    ElseIf option == diagnosticShowAlchemistBusOption
        MMEDiagnostics.ShowAlchemistDialogueBusReport(True)
        ForcePageReset()
    ElseIf option == diagnosticMageBusOption
        MMEDiagnostics.RunMageDialogueBusTest()
        ForcePageReset()
    ElseIf option == diagnosticShowMageBusOption
        MMEDiagnostics.ShowMageDialogueBusReport(True)
        ForcePageReset()
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
    ElseIf option == breastfeedingMilkEffectsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBreastfeedingMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastfeedingMilkEffects", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == elsieBreastfeedingMilkEffectsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableElsieBreastfeedingMilkEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableElsieBreastfeedingMilkEffects", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == estrusTestTypeOption
        estrusTestType = (estrusTestType + 1) % 3
        SetTextOptionValue(option, MMEEstrusPregnancyTest.TypeName(estrusTestType))
    ElseIf option == estrusTestRunOption
        estrusTestResult = MMEEstrusPregnancyTest.RunTest(estrusTestType)
    ElseIf option == elsieBreastfeedingTestOption
        MMEElsieBreastfeeding.RunNearbyTest()
    ElseIf option == breastfeedingMilkEffectsDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBreastfeedingMilkEffectsDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableBreastfeedingMilkEffectsDebug", value)
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
    ElseIf option == customMilkSpeedDebuffOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableCustomMilkSpeedDebuff", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableCustomMilkSpeedDebuff", value)
        JsonUtil.Save(SettingsFile, False)
        MMEBodyEffects.Reconcile("MCM speed toggle changed")
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
        ForcePageReset()
    ElseIf option == maidLevelSpeedScalingOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMaidLevelSpeedScaling", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMaidLevelSpeedScaling", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        MMEBodyEffects.Reconcile("MCM level scaling changed")
    ElseIf option == customMilkWeightOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableCustomMilkWeight", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableCustomMilkWeight", value)
        JsonUtil.Save(SettingsFile, False)
        MMEBodyEffects.Reconcile("MCM milk weight toggle changed")
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
        ForcePageReset()
    ElseIf option == maidBodyScalingOption
        JsonUtil.SetIntValue(SettingsFile, "enableMaidBodyScaling", 1 - JsonUtil.GetIntValue(SettingsFile, "enableMaidBodyScaling", 0))
        MMEMaidBodyScaling.SettingsChanged()
        ForcePageReset()
    ElseIf option == maidWeightScalingOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMaidLevelWeightScaling", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMaidLevelWeightScaling", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        SetOptionFlags(maidWeightPerLevelOption, OPTION_FLAG_DISABLED)
        If value == 1
            SetOptionFlags(maidWeightPerLevelOption, OPTION_FLAG_NONE)
        EndIf
        MMEMaidWeightScaling.ReconcileAll("MCM toggle changed")
    ElseIf option == playerMilkMaidConversionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkMaidConversion", 1)
        JsonUtil.SetIntValue(SettingsFile, "enablePlayerMilkMaidConversion", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == giveMilkEasyModeOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableGiveMilkEasyMode", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkEasyMode", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == nonMilkmaidFemaleDrinkingOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidFemaleDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNonMilkmaidFemaleDrinking", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == nonMilkmaidMaleDrinkingOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidMaleDrinking", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNonMilkmaidMaleDrinking", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == nonMilkmaidDrinkNotificationsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidDrinkNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableNonMilkmaidDrinkNotifications", value)
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
        ForcePageReset()
    ElseIf option == giveMilkActionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableGiveMilkAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkAction", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == createMilkMaidActionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableCreateMilkMaidAction", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCreateMilkMaidAction", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == actorDrinkMilkRemovalOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableActorDrinkMilkRemoval", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableActorDrinkMilkRemoval", value)
        JsonUtil.Save(SettingsFile, False)
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
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        MMEArmorScript.ApplyArmorStrippingMasterToggle()
        MMEMilkingEquipmentRefit.HandleSettingsChanged("armor stripping master changed")
        ForcePageReset()
    ElseIf option == milkingEquipmentRefitOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkingEquipmentRefits", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkingEquipmentRefits", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        MMEMilkingEquipmentRefit.HandleSettingsChanged("refit toggle changed")
    ElseIf option == armorCheckReminderOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorCheckReminder", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorCheckReminder", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == stripAllArmorOverrideOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableStripAllArmor", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableStripAllArmor", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == armorStripHeavyEnabledOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripHeavy", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripHeavy", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == armorStripLightEnabledOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripLight", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripLight", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == armorStripClothingEnabledOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorStripClothing", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorStripClothing", value)
        SetToggleOptionValue(option, value == 1)
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
    ElseIf option == armorLookupForensicsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArmorLookupForensics", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArmorLookupForensics", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == blacksmithDialogueTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableBlacksmithDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableBlacksmithDialogueTrace", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == alchemistDialogueTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableAlchemistDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableAlchemistDialogueTrace", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == mageDialogueTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMageDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableMageDialogueTrace", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == repeatOrdinaryArmorStoriesOption
        ToggleArmorSetting(option, "enableRepeatOrdinaryArmorStories", 1)
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
    ElseIf option == giveMilkActionDiagnosticOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableGiveMilkActionDiagnostic", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkActionDiagnostic", value)
        JsonUtil.Save(SettingsFile, False)
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
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 0)
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
    ElseIf option == arousalEffectsOption && MMEArousalBridge.IsAvailable()
        Int arousalEffectsValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalEffects", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffects", arousalEffectsValue)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, arousalEffectsValue == 1)
        MMEArousalEffects.ResetBaselines("MCM master toggle changed")
        MMEAlertsController arousalController = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If arousalController != None
            arousalController.UpdatePolling()
        EndIf
        ForcePageReset()
        Return
    ElseIf option == arousalEffectNotificationsOption
        Int arousalNotificationsValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalEffectNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectNotifications", arousalNotificationsValue)
        SetToggleOptionValue(option, arousalNotificationsValue == 1)
    ElseIf option == arousalEffectSoundsOption
        Int arousalSoundsValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalEffectSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectSounds", arousalSoundsValue)
        SetToggleOptionValue(option, arousalSoundsValue == 1)
    ElseIf option == arousalEffectAnimationsOption
        Int arousalAnimationsValue = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalEffectAnimations", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEffectAnimations", arousalAnimationsValue)
        SetToggleOptionValue(option, arousalAnimationsValue == 1)
    ElseIf option == arousalMilkMaidRouteOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalMilkMaidRoute", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalMilkMaidRoute", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        MMEArousalEffects.ResetBaselines("Milk Maid eligibility changed")
    ElseIf option == arousalMilkDrinkRouteOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalMilkDrinkRoute", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalMilkDrinkRoute", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == arousalEveryoneRouteOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableArousalEveryoneRoute", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableArousalEveryoneRoute", value)
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValue(option, value == 1)
        MMEArousalEffects.ResetBaselines("everyone-else eligibility changed")
    ElseIf option == milkDrinkArousalOption && MMEArousalBridge.IsAvailable()
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkArousal", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableMilkDrinkArousal", value)
        SetToggleOptionValue(option, value == 1)
        ForcePageReset()
    ElseIf option == skyrimNetSexLabTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == sexLabBreastfeedingDebugOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == newMilkmaidDialogueTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNewMilkmaidDialogueTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkmaidDialogueTrace", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == newMilkmaidSexLabTraceOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableNewMilkmaidSexLabTrace", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableNewMilkmaidSexLabTrace", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == ostimBreastfeedingOption && MMEOStimBreastfeeding.IsOStimDetected()
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableOStimBreastfeeding", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableOStimBreastfeeding", value)
        SetToggleOptionValue(option, value == 1)
        MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If controller != None
            controller.RefreshOStimDialogueAvailability()
            controller.BeginSexLabFallbackGrace("OStim breastfeeding toggle changed")
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

Function RefreshThoughtSchedule()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshThoughtScheduling()
    EndIf
EndFunction

Function RefreshBoundThoughtSchedule()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshBoundThoughtScheduling()
    EndIf
EndFunction

Function RefreshArmorInjectionSchedule(Bool reseed = True)
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshInjectionScheduling(reseed)
    EndIf
EndFunction

Function RefreshDwemerEffectSchedule()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshDwemerEffectScheduling()
    EndIf
EndFunction

Function RefreshBreastBounceSchedule()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshBreastBounceScheduling()
    EndIf
EndFunction

Function RefreshMilkCravingSchedule()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshMilkCravingScheduling()
    EndIf
EndFunction

Function RefreshAutoSelfMilkingSchedule()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshAutoSelfMilkingScheduling()
    EndIf
EndFunction

Function NormalizeArousalThresholdSettings()
    Int[] thresholds = MMEArousalEffects.GetNormalizedThresholds()
    Int low = JsonUtil.GetIntValue(SettingsFile, "arousalLowThreshold", 20)
    Int medium = JsonUtil.GetIntValue(SettingsFile, "arousalMediumThreshold", 50)
    Int high = JsonUtil.GetIntValue(SettingsFile, "arousalHighThreshold", 80)
    If low != thresholds[0] || medium != thresholds[1] || high != thresholds[2]
        JsonUtil.SetIntValue(SettingsFile, "arousalLowThreshold", thresholds[0])
        JsonUtil.SetIntValue(SettingsFile, "arousalMediumThreshold", thresholds[1])
        JsonUtil.SetIntValue(SettingsFile, "arousalHighThreshold", thresholds[2])
        JsonUtil.Save(SettingsFile, False)
        MMEArousalEffects.ResetBaselines("invalid MCM thresholds normalized")
    EndIf
EndFunction

; Configures the shared sound-volume and capacity-interval slider dialogs.
Event OnOptionSliderOpen(Int option)
    If option == milkFullNarrationChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "milkFullNarrationChance", 100))
        SetSliderDialogDefaultValue(100)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
        Return
    EndIf
    If option == postMilkingChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "postMilkingNarrationChance", 100))
        SetSliderDialogDefaultValue(100)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
        Return
    EndIf
    If option == postMilkingCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "postMilkingNarrationCooldown", 120.0))
        SetSliderDialogDefaultValue(120.0)
        SetSliderDialogRange(0.0, 3600.0)
        SetSliderDialogInterval(10.0)
        Return
    EndIf
    Int tierIndex = TentacleOptionIndex(option, False)
    If tierIndex >= 0
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, MMETentacleTiers.ChanceKey(tierIndex + 1), MMETentacleTiers.DefaultChance(tierIndex + 1)))
        SetSliderDialogDefaultValue(MMETentacleTiers.DefaultChance(tierIndex + 1))
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    EndIf
    tierIndex = TentacleOptionIndex(option, True)
    If tierIndex >= 0
        SetSliderDialogStartValue(MMETentacleTiers.Duration(tierIndex + 1))
        Float defaultDuration = 3.0
        If tierIndex == 3
            defaultDuration = 4.0
        EndIf
        SetSliderDialogDefaultValue(defaultDuration)
        SetSliderDialogRange(1.0, 10.0)
        SetSliderDialogInterval(0.5)
        Return
    EndIf
    If option == movementSlapNotificationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "movementSlapNotificationCooldownHours", 8.0))
        SetSliderDialogDefaultValue(8.0)
        SetSliderDialogRange(0.0, 48.0)
        SetSliderDialogInterval(1.0)
        Return
    EndIf
    If option == movementSlapVolumeOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "movementSlapVolume", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 200.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == flatMilkHeavyOption || option == flatMilkLightOption || option == flatMilkClothingOption
        String settingKey = "armorStripClothingMilk"
        Float defaultMilk = 12.0
        If option == flatMilkHeavyOption
            settingKey = "armorStripHeavyMilk"
            defaultMilk = 4.0
        ElseIf option == flatMilkLightOption
            settingKey = "armorStripLightMilk"
            defaultMilk = 8.0
        EndIf
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, settingKey, defaultMilk))
        SetSliderDialogDefaultValue(defaultMilk)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
        Return
    EndIf
    If option == breastBounceIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "breastBounceIntervalHours", 24.0))
        SetSliderDialogDefaultValue(24.0)
        SetSliderDialogRange(1.0, 36.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == breastBounceVariationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "breastBounceVariationHours", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 12.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == breastBounceDelayOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "breastBounceMaximumDelaySeconds", 30.0))
        SetSliderDialogDefaultValue(30.0)
        SetSliderDialogRange(0.0, 60.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == timedArmorDurationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "timedArmorLockDays", 3.0))
        SetSliderDialogDefaultValue(3.0)
        SetSliderDialogRange(0.0, 30.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == dwemerRuinArmorTrapChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "dwemerRuinArmorTrapChance", 25))
        SetSliderDialogDefaultValue(25.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == chestArmorTrapChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "chestArmorTrapChance", 5))
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == chestArmorTrapCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "chestArmorTrapCooldownHours", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 24.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == milkMaidCurseSurgeOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "milkMaidCurseSurgePercent", 50))
        SetSliderDialogDefaultValue(50.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == dungeonChestMilkMaidChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "dungeonChestMilkMaidChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == regularChestMilkMaidChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "regularChestMilkMaidChance", 10))
        SetSliderDialogDefaultValue(10.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == chestMilkTrapChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "chestMilkTrapChance", 33))
        SetSliderDialogDefaultValue(33.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == chestMilkTrapCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "chestMilkTrapCooldownHours", 1.0))
        SetSliderDialogDefaultValue(1.0)
        SetSliderDialogRange(1.0, 24.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == chestMilkTrapVariationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "chestMilkTrapCooldownVariation", 0.0))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 12.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == innPalaceDrinkDelayOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "innPalaceDrinkDelaySeconds", 11.0))
        SetSliderDialogDefaultValue(11.0)
        SetSliderDialogRange(1.0, 60.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == townMilkDrinkChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "townMilkDrinkChance", 25))
        SetSliderDialogDefaultValue(25.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == townUniqueNPCPreferenceChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "townUniqueNPCPreferenceChance", 75))
        SetSliderDialogDefaultValue(75.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == innPalaceDrinkVariationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "innPalaceDrinkDelayVariation", 10.0))
        SetSliderDialogDefaultValue(10.0)
        SetSliderDialogRange(0.0, 60.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == innPalaceDrinkCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "innPalaceDrinkCooldownHours", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 24.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == milkCravingIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkCravingIntervalHours", 48.0))
        SetSliderDialogDefaultValue(48.0)
        SetSliderDialogRange(1.0, 168.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == milkCravingVariationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkCravingIntervalVariation", 24.0))
        SetSliderDialogDefaultValue(24.0)
        SetSliderDialogRange(0.0, 48.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == milkCravingChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "milkCravingTriggerChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
        Return
    ElseIf option == milkCravingGiveInDelayOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkCravingGiveInDelayHours", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 4.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == autoSelfMilkingDelayOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "autoSelfMilkingDelayHours", 1.0))
        SetSliderDialogDefaultValue(1.0)
        SetSliderDialogRange(0.0, 24.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == reverseDurationOption
        SetSliderDialogStartValue(MMEReverseLevel.GetDuration())
        SetSliderDialogDefaultValue(24.0)
        SetSliderDialogRange(1.0, 72.0)
        SetSliderDialogInterval(1.0)
        Return
    ElseIf option == reversePlayerLevelOption
        SetSliderDialogStartValue(MMEReverseLevel.GetRequiredLevel())
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(1.0, 10.0)
        SetSliderDialogInterval(1.0)
        Return
    EndIf
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
    ElseIf option == armorCheckReminderCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorCheckReminderCooldown", 60.0))
        SetSliderDialogDefaultValue(60.0)
        SetSliderDialogRange(0.0, 300.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == milkMaidThoughtsIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsInterval", 12.0))
        SetSliderDialogDefaultValue(12.0)
        SetSliderDialogRange(2.0, 48.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == milkMaidThoughtsRandomnessOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsRandomness", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 12.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == boundMilkMaidThoughtsIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "boundMilkMaidThoughtsInterval", 24.0))
        SetSliderDialogDefaultValue(24.0)
        SetSliderDialogRange(1.0, 48.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == boundMilkMaidThoughtsRandomnessOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "boundMilkMaidThoughtsRandomness", 12.0))
        SetSliderDialogDefaultValue(12.0)
        SetSliderDialogRange(0.0, 12.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == boundMilkMaidThoughtsChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtsChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == boundMilkMaidThoughtNarrationChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == boundMilkDrinkReactionChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "boundMilkDrinkReactionChance", 50))
        SetSliderDialogDefaultValue(50.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == armorInjectionIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorInjectionInterval", 12.0))
        SetSliderDialogDefaultValue(12.0)
        SetSliderDialogRange(1.0, 864.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == armorInjectionVariationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorInjectionVariation", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 12.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == armorInjectionChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "armorInjectionChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == armorInjectionNarrationChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "armorInjectionNarrationChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == dwemerEffectIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "dwemerEffectInterval", 12.0))
        SetSliderDialogDefaultValue(12.0)
        SetSliderDialogRange(1.0, 864.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == dwemerEffectVariationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "dwemerEffectVariation", 4.0))
        SetSliderDialogDefaultValue(4.0)
        SetSliderDialogRange(0.0, 12.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == dwemerEffectChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "dwemerEffectChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == dwemerEffectNarrationChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "dwemerEffectNarrationChance", 100))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == skyrimNetStatusIntervalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0))
        SetSliderDialogDefaultValue(15.0)
        SetSliderDialogRange(15.0, 300.0)
        SetSliderDialogInterval(15.0)
    ElseIf option == breastfeedingActionCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "breastfeedingActionCooldown", 45.0))
        SetSliderDialogDefaultValue(45.0)
        SetSliderDialogRange(5.0, 300.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == giveMilkActionCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "giveMilkActionCooldown", 0.0))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 300.0)
        SetSliderDialogInterval(5.0)
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
    ElseIf option == arousalEffectDelayOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "arousalEffectDelay", 5.0))
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(0.0, 60.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == arousalEffectCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "arousalEffectCooldown", 5.0))
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(0.0, 600.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == arousalEffectCooldownVariationOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "arousalEffectCooldownVariation", 0.0))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 600.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == arousalLowThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "arousalLowThreshold", 20))
        SetSliderDialogDefaultValue(20.0)
        SetSliderDialogRange(0.0, JsonUtil.GetIntValue(SettingsFile, "arousalMediumThreshold", 50) - 5)
        SetSliderDialogInterval(5.0)
    ElseIf option == arousalMediumThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "arousalMediumThreshold", 50))
        SetSliderDialogDefaultValue(50.0)
        SetSliderDialogRange(JsonUtil.GetIntValue(SettingsFile, "arousalLowThreshold", 20) + 5, JsonUtil.GetIntValue(SettingsFile, "arousalHighThreshold", 80) - 5)
        SetSliderDialogInterval(5.0)
    ElseIf option == arousalHighThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "arousalHighThreshold", 80))
        SetSliderDialogDefaultValue(80.0)
        SetSliderDialogRange(JsonUtil.GetIntValue(SettingsFile, "arousalMediumThreshold", 50) + 5, 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == milkSpeedMediumThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkSpeedMediumThreshold", 50.0))
        SetSliderDialogDefaultValue(50.0)
        SetSliderDialogRange(0.0, JsonUtil.GetFloatValue(SettingsFile, "milkSpeedHighThreshold", 100.0))
        SetSliderDialogInterval(5.0)
    ElseIf option == milkSpeedMediumPenaltyOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkSpeedMediumPenalty", 3.0))
        SetSliderDialogDefaultValue(3.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == milkSpeedHighThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkSpeedHighThreshold", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(JsonUtil.GetFloatValue(SettingsFile, "milkSpeedMediumThreshold", 50.0), 100.0)
        SetSliderDialogInterval(5.0)
    ElseIf option == milkSpeedHighPenaltyOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkSpeedHighPenalty", 10.0))
        SetSliderDialogDefaultValue(10.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == milkWeightMultiplierOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkWeightMultiplier", 1.0))
        SetSliderDialogDefaultValue(1.0)
        SetSliderDialogRange(1.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyMaxLevelOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaxLevel())
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(10.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyHipsOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("Hips"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyButtOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("Butt"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyThighsOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("Thighs"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyCalfSizeOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("CalfSize"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyWaistOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("Waist"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyBellyOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("Belly"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyBigBellyOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("BigBelly"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyChubbyArmsOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("ChubbyArms"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyChubbyLegsOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("ChubbyLegs"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidBodyChubbyWaistOption
        SetSliderDialogStartValue(MMEMaidBodyScaling.GetMaximum("ChubbyWaist"))
        SetSliderDialogDefaultValue(0.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == maidWeightPerLevelOption
        SetSliderDialogStartValue(MMEMaidWeightScaling.GetWeightPerLevel())
        SetSliderDialogDefaultValue(1.0)
        SetSliderDialogRange(0.0, 10.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == nonMilkmaidFemaleArousalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "nonMilkmaidFemaleArousal", 20.0))
        SetSliderDialogDefaultValue(20.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == nonMilkmaidMaleArousalOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "nonMilkmaidMaleArousal", 20.0))
        SetSliderDialogDefaultValue(20.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == milkFullNarrationCooldownOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkFullNarrationCooldown", 120.0))
        SetSliderDialogDefaultValue(120.0)
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
    ElseIf option == playerMilkMaidConversionChanceOption
        SetSliderDialogStartValue(JsonUtil.GetIntValue(SettingsFile, "playerMilkMaidConversionChance", 100))
        SetSliderDialogDefaultValue(100.0)
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
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorStripHeavyPercent", 70.0))
        SetSliderDialogDefaultValue(70.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    ElseIf option == armorStripLightThresholdOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "armorStripLightPercent", 85.0))
        SetSliderDialogDefaultValue(85.0)
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
        SetSliderDialogInterval(1.0)
    EndIf
EndEvent

; Saves accepted slider values and reschedules polling when its interval changes.
Event OnOptionSliderAccept(Int option, Float value)
    If option == milkFullNarrationChanceOption
        JsonUtil.SetIntValue(SettingsFile, "milkFullNarrationChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    EndIf
    If option == postMilkingChanceOption
        JsonUtil.SetIntValue(SettingsFile, "postMilkingNarrationChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    EndIf
    If option == postMilkingCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "postMilkingNarrationCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
        Return
    EndIf
    Int tierIndex = TentacleOptionIndex(option, False)
    If tierIndex >= 0
        MMETentacleTiers.Configure(tierIndex, value as Int)
        ForcePageReset()
        Return
    EndIf
    tierIndex = TentacleOptionIndex(option, True)
    If tierIndex >= 0
        JsonUtil.SetFloatValue(SettingsFile, MMETentacleTiers.DurationKey(tierIndex + 1), value)
        MMETentacleTiers.Configure()
        SetSliderOptionValue(option, MMETentacleTiers.Duration(tierIndex + 1), "{1} seconds")
        Return
    EndIf
    If option == movementSlapNotificationCooldownOption
        If value < 0.0
            value = 0.0
        ElseIf value > 48.0
            value = 48.0
        EndIf
        JsonUtil.SetFloatValue(SettingsFile, "movementSlapNotificationCooldownHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        MMELog.MasterDiagnostic("[MME Extensions Movement Slap] notification cooldown setting changed | game hours=" + value)
        Return
    EndIf
    If option == movementSlapVolumeOption
        JsonUtil.SetFloatValue(SettingsFile, "movementSlapVolume", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        RefreshMovementSlapSettings()
        Return
    ElseIf option == flatMilkHeavyOption || option == flatMilkLightOption || option == flatMilkClothingOption
        String settingKey = "armorStripClothingMilk"
        If option == flatMilkHeavyOption
            settingKey = "armorStripHeavyMilk"
        ElseIf option == flatMilkLightOption
            settingKey = "armorStripLightMilk"
        EndIf
        JsonUtil.SetFloatValue(SettingsFile, settingKey, value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} milk")
        Return
    EndIf
    If option == breastBounceIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "breastBounceIntervalHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshBreastBounceSchedule()
        Return
    ElseIf option == breastBounceVariationOption
        JsonUtil.SetFloatValue(SettingsFile, "breastBounceVariationHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+/- {0} game hours")
        RefreshBreastBounceSchedule()
        Return
    ElseIf option == breastBounceDelayOption
        JsonUtil.SetFloatValue(SettingsFile, "breastBounceMaximumDelaySeconds", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
        RefreshBreastBounceSchedule()
        Return
    ElseIf option == timedArmorDurationOption
        JsonUtil.SetFloatValue(SettingsFile, "timedArmorLockDays", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game days")
        Return
    ElseIf option == dwemerRuinArmorTrapChanceOption
        JsonUtil.SetIntValue(SettingsFile, "dwemerRuinArmorTrapChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == chestArmorTrapChanceOption
        JsonUtil.SetIntValue(SettingsFile, "chestArmorTrapChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == chestArmorTrapCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "chestArmorTrapCooldownHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        Return
    ElseIf option == milkMaidCurseSurgeOption
        JsonUtil.SetIntValue(SettingsFile, "milkMaidCurseSurgePercent", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}% of capacity")
        Return
    ElseIf option == dungeonChestMilkMaidChanceOption
        JsonUtil.SetIntValue(SettingsFile, "dungeonChestMilkMaidChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == regularChestMilkMaidChanceOption
        JsonUtil.SetIntValue(SettingsFile, "regularChestMilkMaidChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == chestMilkTrapChanceOption
        JsonUtil.SetIntValue(SettingsFile, "chestMilkTrapChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == chestMilkTrapCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "chestMilkTrapCooldownHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        Return
    ElseIf option == chestMilkTrapVariationOption
        JsonUtil.SetFloatValue(SettingsFile, "chestMilkTrapCooldownVariation", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+/- {0} game hours")
        Return
    ElseIf option == innPalaceDrinkDelayOption
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkDelaySeconds", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
        Return
    ElseIf option == townMilkDrinkChanceOption
        JsonUtil.SetIntValue(SettingsFile, "townMilkDrinkChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == townUniqueNPCPreferenceChanceOption
        JsonUtil.SetIntValue(SettingsFile, "townUniqueNPCPreferenceChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == innPalaceDrinkVariationOption
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkDelayVariation", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+/-{0} seconds")
        Return
    ElseIf option == innPalaceDrinkCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "innPalaceDrinkCooldownHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        Return
    ElseIf option == milkCravingIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingIntervalHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshMilkCravingSchedule()
        Return
    ElseIf option == milkCravingVariationOption
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingIntervalVariation", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+/-{0} game hours")
        RefreshMilkCravingSchedule()
        Return
    ElseIf option == milkCravingChanceOption
        JsonUtil.SetIntValue(SettingsFile, "milkCravingTriggerChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        Return
    ElseIf option == milkCravingGiveInDelayOption
        JsonUtil.SetFloatValue(SettingsFile, "milkCravingGiveInDelayHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        Return
    ElseIf option == autoSelfMilkingDelayOption
        JsonUtil.SetFloatValue(SettingsFile, "autoSelfMilkingDelayHours", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshAutoSelfMilkingSchedule()
        Return
    ElseIf option == reverseDurationOption
        JsonUtil.SetIntValue(SettingsFile, "reverseLevelingDuration", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, MMEReverseLevel.GetDuration(), "{0} game hours")
        Return
    ElseIf option == reversePlayerLevelOption
        JsonUtil.SetIntValue(SettingsFile, "reversePlayerMaidLevel", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, MMEReverseLevel.GetRequiredLevel(), "{0}")
        Return
    EndIf
    ; Slider values are clamped by their dialog ranges. Persist the accepted value
    ; immediately so runtime scripts and subsequent page renders agree.
    If option == volumeOption
        JsonUtil.SetFloatValue(SettingsFile, "reactionSoundVolume", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        RefreshMovementSlapSettings()
    ElseIf option == pollingIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
    ElseIf option == armorCheckReminderCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "armorCheckReminderCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == milkMaidThoughtsIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "milkMaidThoughtsInterval", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshThoughtSchedule()
    ElseIf option == milkMaidThoughtsRandomnessOption
        JsonUtil.SetFloatValue(SettingsFile, "milkMaidThoughtsRandomness", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshThoughtSchedule()
    ElseIf option == boundMilkMaidThoughtsIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "boundMilkMaidThoughtsInterval", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshBoundThoughtSchedule()
    ElseIf option == boundMilkMaidThoughtsRandomnessOption
        JsonUtil.SetFloatValue(SettingsFile, "boundMilkMaidThoughtsRandomness", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshBoundThoughtSchedule()
    ElseIf option == boundMilkMaidThoughtsChanceOption
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtsChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == boundMilkMaidThoughtNarrationChanceOption
        JsonUtil.SetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == boundMilkDrinkReactionChanceOption
        JsonUtil.SetIntValue(SettingsFile, "boundMilkDrinkReactionChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == armorInjectionIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "armorInjectionInterval", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshArmorInjectionSchedule()
    ElseIf option == armorInjectionVariationOption
        JsonUtil.SetFloatValue(SettingsFile, "armorInjectionVariation", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshArmorInjectionSchedule()
    ElseIf option == armorInjectionChanceOption
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == armorInjectionNarrationChanceOption
        JsonUtil.SetIntValue(SettingsFile, "armorInjectionNarrationChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == dwemerEffectIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "dwemerEffectInterval", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshDwemerEffectSchedule()
    ElseIf option == dwemerEffectVariationOption
        JsonUtil.SetFloatValue(SettingsFile, "dwemerEffectVariation", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} game hours")
        RefreshDwemerEffectSchedule()
    ElseIf option == dwemerEffectChanceOption
        JsonUtil.SetIntValue(SettingsFile, "dwemerEffectChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == dwemerEffectNarrationChanceOption
        JsonUtil.SetIntValue(SettingsFile, "dwemerEffectNarrationChance", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    ElseIf option == skyrimNetStatusIntervalOption
        JsonUtil.SetFloatValue(SettingsFile, "skyrimNetStatusInterval", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).UpdatePolling()
    ElseIf option == breastfeedingActionCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "breastfeedingActionCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == giveMilkActionCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "giveMilkActionCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == flatMilkBonusOption
        JsonUtil.SetFloatValue(SettingsFile, "flatMilkBonus", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+{1} milk")
    ElseIf option == milkSpeedMediumThresholdOption
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedMediumThreshold", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        MMEBodyEffects.Reconcile("MCM medium threshold changed")
    ElseIf option == milkSpeedMediumPenaltyOption
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedMediumPenalty", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        MMEBodyEffects.Reconcile("MCM medium penalty changed")
    ElseIf option == milkSpeedHighThresholdOption
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedHighThreshold", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        MMEBodyEffects.Reconcile("MCM high threshold changed")
    ElseIf option == milkSpeedHighPenaltyOption
        JsonUtil.SetFloatValue(SettingsFile, "milkSpeedHighPenalty", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
        MMEBodyEffects.Reconcile("MCM high penalty changed")
    ElseIf option == milkWeightMultiplierOption
        JsonUtil.SetFloatValue(SettingsFile, "milkWeightMultiplier", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "x{0}")
        MMEBodyEffects.Reconcile("MCM milk weight multiplier changed")
    ElseIf option == maidBodyMaxLevelOption
        JsonUtil.SetIntValue(SettingsFile, "maidBodyScalingMaxLevel", value as Int)
        SetSliderOptionValue(option, value, "{0}")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyHipsOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphHips", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyButtOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphButt", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyThighsOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphThighs", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyCalfSizeOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphCalfSize", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyWaistOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphWaist", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyBellyOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphBelly", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyBigBellyOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphBigBelly", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyChubbyArmsOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphChubbyArms", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyChubbyLegsOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphChubbyLegs", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidBodyChubbyWaistOption
        JsonUtil.SetFloatValue(SettingsFile, "maidBodyMorphChubbyWaist", value)
        SetSliderOptionValue(option, value, "{0}%")
        MMEMaidBodyScaling.SettingsChanged()
    ElseIf option == maidWeightPerLevelOption
        JsonUtil.SetFloatValue(SettingsFile, "maidWeightPerLevel", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+{0}")
        MMEMaidWeightScaling.ReconcileAll("MCM weight-per-level changed")
    ElseIf option == lactacidMultiplierOption
        JsonUtil.SetFloatValue(SettingsFile, "lactacidFlatMultiplier", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "x{1}")
    ElseIf option == milkDrinkArousalAmountOption
        JsonUtil.SetFloatValue(SettingsFile, "milkDrinkArousal", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+{0}")
    ElseIf option == arousalEffectDelayOption
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectDelay", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == arousalEffectCooldownOption
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectCooldown", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0} seconds")
    ElseIf option == arousalEffectCooldownVariationOption
        JsonUtil.SetFloatValue(SettingsFile, "arousalEffectCooldownVariation", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+/- {0} seconds")
    ElseIf option == arousalLowThresholdOption
        JsonUtil.SetIntValue(SettingsFile, "arousalLowThreshold", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}")
        MMEArousalEffects.ResetBaselines("low threshold changed")
    ElseIf option == arousalMediumThresholdOption
        JsonUtil.SetIntValue(SettingsFile, "arousalMediumThreshold", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}")
        MMEArousalEffects.ResetBaselines("medium threshold changed")
    ElseIf option == arousalHighThresholdOption
        JsonUtil.SetIntValue(SettingsFile, "arousalHighThreshold", value as Int)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}")
        MMEArousalEffects.ResetBaselines("high threshold changed")
    ElseIf option == nonMilkmaidFemaleArousalOption
        JsonUtil.SetFloatValue(SettingsFile, "nonMilkmaidFemaleArousal", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "+{0}")
    ElseIf option == nonMilkmaidMaleArousalOption
        JsonUtil.SetFloatValue(SettingsFile, "nonMilkmaidMaleArousal", value)
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
    ElseIf option == playerMilkMaidConversionChanceOption
        JsonUtil.SetIntValue(SettingsFile, "playerMilkMaidConversionChance", value as Int)
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

Function RefreshMovementSlapSettings()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.UpdatePolling()
    EndIf
EndFunction

; Common core uses only string/plugin checks and events; no optional UI script types.
Bool Function RosterUiAvailable()
    ; SKSE returns 256+ for ESL plugins; only 255 means absent.
    Return Game.GetModByName("MME Extensions - Maid Roster.esp") != 255 && SKSE.GetPluginVersion("Magelight") >= 0
EndFunction

Event OnOptionKeyMapChange(Int option, Int keyCode, String conflictControl, String conflictName)
    If option != rosterKeyOption
        Return
    EndIf
    If keyCode != -1 && (keyCode <= 0 || keyCode >= 256 || keyCode == 201)
        ShowMessage(MMELocalization.Text("Choose a keyboard key other than PageUp, or clear the mapping."), False)
        Return
    EndIf
    If conflictControl != "" || conflictName != ""
        If !ShowMessage(MMELocalization.Text("This key is already assigned. Use it for the roster too?"))
            Return
        EndIf
    EndIf
    JsonUtil.SetIntValue(SettingsFile, "maidRosterHotkey", keyCode)
    JsonUtil.Save(SettingsFile, False)
    SetKeyMapOptionValue(option, keyCode)
    SendModEvent("MMEExtensions_RosterSettings")
    MMELog.MasterDiagnostic("[MME Maid Roster UI] hotkey changed | key=" + keyCode)
EndEvent

Int Function TentacleOptionIndex(Int option, Bool duration)
    Int[] options = tentacleChanceOptions
    If duration
        options = tentacleDurationOptions
    EndIf
    Int index = 0
    While index < options.Length
        If option >= 0 && options[index] == option
            Return index
        EndIf
        index += 1
    EndWhile
    Return -1
EndFunction

; Original MME shortcut; no duplicate saved setting.
State OGMilkSelf
    Event OnSelectST()
        MMEOriginalSettings.Toggle(Self, "MilkSelf")
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Adds or removes the original MME self-milking spell from the player. This is the same spell toggle as the original MME menu."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGMilkFriend
    Event OnSelectST()
        MMEOriginalSettings.Toggle(Self, "MilkFriend")
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Adds or removes the original MME target-milking spell from the player. Cast it on a friend to use MME's normal milking route."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGMastery
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "Mastery")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "Mastery", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Directly sets global MME Milk Mastery (0-40). Higher mastery unlocks more Milk Maid slots, allowing you to have more Milk Maids within MME's limits. This is global progression, separate from each maid's individual level."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGLeveling
    Event OnMenuOpenST()
        MMEOriginalSettings.OpenDifficulty(Self)
    EndEvent
    Event OnMenuAcceptST(Int index)
        MMEOriginalSettings.SetDifficulty(Self, index)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Controls how much milking is required to progress. Faster presets require less milking. This original MME Difficulty setting also affects the economy and refreshes its market properties."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGSpeed
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "Speed")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "Speed", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Percentage of remaining milk extracted each cycle, with at least one unit extracted when milk is available. Higher values empty milk faster. Total time depends on milk amount and Milking Cycle Duration. Original name: Milking Gush Effect."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGDuration
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "Duration")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "Duration", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Seconds per milking cycle, not total session length. Total milking time depends on the amount of milk and Milking Speed."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGProduction
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "Production")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "Production", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Scales original MME milk production: 100% is normal, 0% stops production, 200% doubles it. Shared with original MME."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGFixed
    Event OnSelectST()
        MMEOriginalSettings.Toggle(Self, "Fixed")
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Uses MME's fixed production formula for all Milk Maids instead of its lactacid-dependent dynamic formula. The formula still respects MME modifiers and Milk Production Rate."))
    EndEvent
EndState

State FixedLactacidEnabled
    Event OnSelectST()
        MMEFixedLactacid.SetEnabled(!MMEFixedLactacid.IsEnabled())
        ForcePageReset()
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Default on. Only actors using fixed milk production gain the selected bonus while stored Lactacid lasts. Consumes 1 stored unit per simulated game hour, including sleep/wait catch-up. Does not drink inventory bottles. Off restores original MME fixed-mode consumption. Dynamic production is unchanged."))
    EndEvent
EndState

State FixedLactacidPercent
    Event OnSliderOpenST()
        SetSliderDialogStartValue(MMEFixedLactacid.BonusPercent())
        SetSliderDialogDefaultValue(50.0)
        SetSliderDialogRange(0.0, 200.0)
        SetSliderDialogInterval(5.0)
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEFixedLactacid.SetBonusPercent(value)
        ForcePageReset()
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Extra fixed-mode milk production while Lactacid is above zero: +50% makes 1.5 times normal production. Extra Lactacid extends duration without stacking strength. Production returns to normal when fuel reaches zero; a partial final hour receives a proportional bonus. At 0%, fuel still depletes hourly."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGPrices
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "Prices")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "Prices", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Multiplies original MME economy milk prices by this amount. Shared with the original Modify milk prices by setting."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGDebuffs
    Event OnSelectST()
        MMEOriginalSettings.Toggle(Self, "Debuffs")
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Controls original MME buffs AND debuffs. Original penalties can stack with Extensions penalties when both are enabled. Does not toggle Extensions effects."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGPerMilk
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "PerMilk")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "PerMilk", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Original MME global breast-growth increase per unit of milk. Existing individual-maid overrides remain in effect. Range and units follow MME's breast-volume scaling mode."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGPerLevel
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "PerLevel")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "PerLevel", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Original MME global breast-growth increase per Milk Maid level. Existing individual-maid overrides remain in effect. Range and units follow MME's breast-volume scaling mode."))
    EndEvent
EndState

; Original MME shortcut; no duplicate saved setting.
State OGMaxSize
    Event OnSliderOpenST()
        MMEOriginalSettings.OpenSlider(Self, "MaxSize")
    EndEvent
    Event OnSliderAcceptST(Float value)
        MMEOriginalSettings.SetSlider(Self, "MaxSize", value)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Original MME visual breast-size limit. Zero means unlimited. Refreshes current Milk Maids using MME's normal size calculation; breast scaling must be enabled in MME to see growth."))
    EndEvent
EndState

; Page builders own layout only. Existing setting keys and callbacks are retained.

Function DrawBodyPage()
    MMEOriginalSettings.DrawBody(Self)
    DrawMilkLeakOptions()
    AddHeaderOption(MMELocalization.Text("Milk Fullness Reactions"))
    capacityOption = AddToggleOption(MMELocalization.Text("Enable 50% Capacity Reactions"), JsonUtil.GetIntValue(SettingsFile, "enableCapacityReactions", 1) == 1)
    notificationOption = AddToggleOption(MMELocalization.Text("Enable Capacity Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableCapacityNotifications", 1) == 1)
    fullnessMoansOption = AddToggleOption(MMELocalization.Text("Milk Fullness Moans"), JsonUtil.GetIntValue(SettingsFile, "enableFullnessMoans", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Player Fullness"))
    playerHalfFullSelfMilkAnimationOption = AddToggleOption(MMELocalization.Text("Player Half-Full Animation"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerHalfFullSelfMilkAnimation", 0) == 1)
    playerFullSelfMilkAnimationOption = AddToggleOption(MMELocalization.Text("Player Full Animation"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerFullSelfMilkAnimation", 0) == 1)
    playerFullnessSelfMilkAnimationDurationOption = AddSliderOption(MMELocalization.Text("Player Fullness Animation Duration"), JsonUtil.GetFloatValue(SettingsFile, "playerFullnessSelfMilkAnimationDuration", 3.0), MMELocalization.Text("{0} seconds"))
    AddHeaderOption(MMELocalization.Text("NPC Fullness"))
    npcHalfFullSelfMilkAnimationOption = AddToggleOption(MMELocalization.Text("NPC Half-Full Animation"), JsonUtil.GetIntValue(SettingsFile, "enableNPCHalfFullSelfMilkAnimation", 1) == 1)
    npcFullSelfMilkAnimationOption = AddToggleOption(MMELocalization.Text("NPC Full Animation"), JsonUtil.GetIntValue(SettingsFile, "enableNPCFullSelfMilkAnimation", 1) == 1)
    npcFullnessSelfMilkAnimationDurationOption = AddSliderOption(MMELocalization.Text("NPC Fullness Animation Duration"), JsonUtil.GetFloatValue(SettingsFile, "npcFullnessSelfMilkAnimationDuration", 3.0), MMELocalization.Text("{0} seconds"))
    AddHeaderOption(MMELocalization.Text("Breast Bounce Reactions"))
    breastBounceNotificationOption = AddToggleOption(MMELocalization.Text("Breast Bounce Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableBreastBounceNotifications", 1) == 1)
    breastBounceSoundOption = AddToggleOption(MMELocalization.Text("Breast Bounce Sounds"), JsonUtil.GetIntValue(SettingsFile, "enableBreastBounceSounds", 1) == 1)
    breastBounceIntervalOption = AddSliderOption(MMELocalization.Text("Reaction Interval"), JsonUtil.GetFloatValue(SettingsFile, "breastBounceIntervalHours", 24.0), MMELocalization.Text("{0} game hours"))
    breastBounceVariationOption = AddSliderOption(MMELocalization.Text("Interval Variation"), JsonUtil.GetFloatValue(SettingsFile, "breastBounceVariationHours", 4.0), MMELocalization.Text("+/- {0} game hours"))
    breastBounceDelayOption = AddSliderOption(MMELocalization.Text("Maximum Reaction Delay"), JsonUtil.GetFloatValue(SettingsFile, "breastBounceMaximumDelaySeconds", 30.0), MMELocalization.Text("{0} seconds"))
    AddHeaderOption(MMELocalization.Text("Movement Slap"))
    movementSlapOption = AddToggleOption(MMELocalization.Text("Movement Slap Sounds"), JsonUtil.GetIntValue(SettingsFile, "enableMovementSlap", 1) == 1)
    Int movementSoundFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableMovementSlap", 1) != 1 || JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) != 1
        movementSoundFlags = OPTION_FLAG_DISABLED
    EndIf
    movementSlapVolumeOption = AddSliderOption(MMELocalization.Text("Movement Slap Volume"), JsonUtil.GetFloatValue(SettingsFile, "movementSlapVolume", 100.0), "{0}%", movementSoundFlags)
    movementSlapNotificationsOption = AddToggleOption(MMELocalization.Text("Movement Slap Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableMovementSlapNotifications", 1) == 1)
    Int movementNotificationFlags = movementSoundFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableMovementSlapNotifications", 1) != 1
        movementNotificationFlags = OPTION_FLAG_DISABLED
    EndIf
    movementSlapNotificationCooldownOption = AddSliderOption(MMELocalization.Text("Notification Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "movementSlapNotificationCooldownHours", 8.0), MMELocalization.Text("{0} game hours"), movementNotificationFlags)
    AddHeaderOption(MMELocalization.Text("Advanced Fullness Monitoring"))
    pollingOption = AddToggleOption(MMELocalization.Text("Enable Capacity Polling"), JsonUtil.GetIntValue(SettingsFile, "enableCapacityPolling", 1) == 1)
    pollingIntervalOption = AddSliderOption(MMELocalization.Text("Capacity Polling Interval"), JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 15.0), MMELocalization.Text("{0} seconds"))
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("Milk Maid Appearance"))
    maidWeightScalingOption = AddToggleOption(MMELocalization.Text("Scale Weight with Maid Level"), MMEMaidWeightScaling.IsEnabled())
    Int maidWeightFlags = OPTION_FLAG_NONE
    If !MMEMaidWeightScaling.IsEnabled()
        maidWeightFlags = OPTION_FLAG_DISABLED
    EndIf
    maidWeightPerLevelOption = AddSliderOption(MMELocalization.Text("Weight per Maid Level"), MMEMaidWeightScaling.GetWeightPerLevel(), "+{0}", maidWeightFlags)
    AddHeaderOption(MMELocalization.Text("Milk Maid Body Morphs"))
    maidBodyScalingOption = AddToggleOption(MMELocalization.Text("Level-Based Body Scaling"), JsonUtil.GetIntValue(SettingsFile, "enableMaidBodyScaling", 0) == 1)
    Int bodyMorphFlags = OPTION_FLAG_DISABLED
    If JsonUtil.GetIntValue(SettingsFile, "enableMaidBodyScaling", 0) == 1
        bodyMorphFlags = OPTION_FLAG_NONE
    EndIf
    maidBodyMaxLevelOption = AddSliderOption(MMELocalization.Text("Maximum Scaling Maid Level"), MMEMaidBodyScaling.GetMaxLevel(), "{0}", bodyMorphFlags)
    maidBodyHipsOption = AddSliderOption(MMELocalization.Text("Hips at Maximum Level"), MMEMaidBodyScaling.GetMaximum("Hips"), "{0}%", bodyMorphFlags)
    maidBodyButtOption = AddSliderOption(MMELocalization.Text("Butt at Maximum Level"), MMEMaidBodyScaling.GetMaximum("Butt"), "{0}%", bodyMorphFlags)
    maidBodyThighsOption = AddSliderOption(MMELocalization.Text("Thighs at Maximum Level"), MMEMaidBodyScaling.GetMaximum("Thighs"), "{0}%", bodyMorphFlags)
    maidBodyCalfSizeOption = AddSliderOption(MMELocalization.Text("Calves at Maximum Level"), MMEMaidBodyScaling.GetMaximum("CalfSize"), "{0}%", bodyMorphFlags)
    maidBodyWaistOption = AddSliderOption(MMELocalization.Text("Waist at Maximum Level"), MMEMaidBodyScaling.GetMaximum("Waist"), "{0}%", bodyMorphFlags)
    maidBodyBellyOption = AddSliderOption(MMELocalization.Text("Belly at Maximum Level"), MMEMaidBodyScaling.GetMaximum("Belly"), "{0}%", bodyMorphFlags)
    maidBodyBigBellyOption = AddSliderOption(MMELocalization.Text("Big Belly at Maximum Level"), MMEMaidBodyScaling.GetMaximum("BigBelly"), "{0}%", bodyMorphFlags)
    maidBodyChubbyArmsOption = AddSliderOption(MMELocalization.Text("Chubby Arms at Maximum Level"), MMEMaidBodyScaling.GetMaximum("ChubbyArms"), "{0}%", bodyMorphFlags)
    maidBodyChubbyLegsOption = AddSliderOption(MMELocalization.Text("Chubby Legs at Maximum Level"), MMEMaidBodyScaling.GetMaximum("ChubbyLegs"), "{0}%", bodyMorphFlags)
    maidBodyChubbyWaistOption = AddSliderOption(MMELocalization.Text("Chubby Waist at Maximum Level"), MMEMaidBodyScaling.GetMaximum("ChubbyWaist"), "{0}%", bodyMorphFlags)

    AddHeaderOption(MMELocalization.Text("Milk Weight"))
    customMilkWeightOption = AddToggleOption(MMELocalization.Text("Milk Has Weight"), JsonUtil.GetIntValue(SettingsFile, "enableCustomMilkWeight", 0) == 1)
    Int milkWeightFlags = OPTION_FLAG_DISABLED
    If JsonUtil.GetIntValue(SettingsFile, "enableCustomMilkWeight", 0) == 1
        milkWeightFlags = OPTION_FLAG_NONE
    EndIf
    milkWeightMultiplierOption = AddSliderOption(MMELocalization.Text("Milk Weight Multiplier"), JsonUtil.GetFloatValue(SettingsFile, "milkWeightMultiplier", 1.0), "x{0}", milkWeightFlags)
    AddHeaderOption(MMELocalization.Text("Movement Speed"))
    customMilkSpeedDebuffOption = AddToggleOption(MMELocalization.Text("Custom Milk Speed Debuff"), JsonUtil.GetIntValue(SettingsFile, "enableCustomMilkSpeedDebuff", 0) == 1)
    Int speedFlags = OPTION_FLAG_DISABLED
    If JsonUtil.GetIntValue(SettingsFile, "enableCustomMilkSpeedDebuff", 0) == 1
        speedFlags = OPTION_FLAG_NONE
    EndIf
    milkSpeedMediumThresholdOption = AddSliderOption(MMELocalization.Text("Medium Milk Threshold"), JsonUtil.GetFloatValue(SettingsFile, "milkSpeedMediumThreshold", 50.0), "{0}%", speedFlags)
    milkSpeedMediumPenaltyOption = AddSliderOption(MMELocalization.Text("Medium Speed Debuff"), JsonUtil.GetFloatValue(SettingsFile, "milkSpeedMediumPenalty", 3.0), "{0}%", speedFlags)
    milkSpeedHighThresholdOption = AddSliderOption(MMELocalization.Text("High Milk Threshold"), JsonUtil.GetFloatValue(SettingsFile, "milkSpeedHighThreshold", 100.0), "{0}%", speedFlags)
    milkSpeedHighPenaltyOption = AddSliderOption(MMELocalization.Text("High Speed Debuff"), JsonUtil.GetFloatValue(SettingsFile, "milkSpeedHighPenalty", 10.0), "{0}%", speedFlags)
    maidLevelSpeedScalingOption = AddToggleOption(MMELocalization.Text("Milk Maid Level Speed Scaling"), JsonUtil.GetIntValue(SettingsFile, "enableMaidLevelSpeedScaling", 0) == 1, speedFlags)
EndFunction

Function DrawTrapsPage()
    AddHeaderOption(MMELocalization.Text("Trapped Armor Chests"))
    chestArmorTrapOption = AddToggleOption(MMELocalization.Text("Enable Trap Armor Chest"), JsonUtil.GetIntValue(SettingsFile, "enableChestArmorTrap", 1) == 1)
    Int armorTrapFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableChestArmorTrap", 1) != 1
        armorTrapFlags = OPTION_FLAG_DISABLED
    EndIf
    armorTrapNearbyAlliesOption = AddToggleOption(MMELocalization.Text("Armor Traps Target Nearby Allies"), JsonUtil.GetIntValue(SettingsFile, "enableArmorTrapNearbyAllies", 1) == 1, armorTrapFlags)
    repeatTrapArmorStoriesOption = AddToggleOption(MMELocalization.Text("Repeat Trap Armor Stories"), JsonUtil.GetIntValue(SettingsFile, "enableRepeatTrapArmorStories", 1) == 1, armorTrapFlags)
    livingArmorChestTrapOption = AddToggleOption(MMELocalization.Text("Living Armor Traps"), JsonUtil.GetIntValue(SettingsFile, "enableLivingArmorChestTrap", 1) == 1, armorTrapFlags)
    parasiteArmorChestTrapOption = AddToggleOption(MMELocalization.Text("Parasite Armor Traps"), JsonUtil.GetIntValue(SettingsFile, "enableParasiteArmorChestTrap", 1) == 1, armorTrapFlags)
    dwemerArmorChestTrapOption = AddToggleOption(MMELocalization.Text("Dwemer Armor Traps"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerArmorChestTrap", 1) == 1, armorTrapFlags)
    Int dwemerTrapFlags = armorTrapFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableDwemerArmorChestTrap", 1) != 1
        dwemerTrapFlags = OPTION_FLAG_DISABLED
    EndIf
    dwemerArmorOutsideRuinsOption = AddToggleOption(MMELocalization.Text("Dwemer Armor Outside Ruins"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerArmorOutsideRuins", 0) == 1, dwemerTrapFlags)
    dwemerRuinArmorTrapChanceOption = AddSliderOption(MMELocalization.Text("Dwemer Ruin Chance"), JsonUtil.GetIntValue(SettingsFile, "dwemerRuinArmorTrapChance", 25), "{0}%", dwemerTrapFlags)
    chestArmorTrapChanceOption = AddSliderOption(MMELocalization.Text("General Trap Chance"), JsonUtil.GetIntValue(SettingsFile, "chestArmorTrapChance", 5), "{0}%", armorTrapFlags)
    chestArmorTrapCooldownOption = AddSliderOption(MMELocalization.Text("Armor Trap Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "chestArmorTrapCooldownHours", 4.0), MMELocalization.Text("{0} game hours"), armorTrapFlags)
    AddHeaderOption(MMELocalization.Text("Exotic Milk Chest Trap"))
    chestMilkTrapOption = AddToggleOption(MMELocalization.Text("Enable Exotic Milk Trap"), JsonUtil.GetIntValue(SettingsFile, "enableChestMilkTrap", 1) == 1)
    Int chestMilkTrapFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableChestMilkTrap", 1) != 1
        chestMilkTrapFlags = OPTION_FLAG_DISABLED
    EndIf
    milkDrinkTrapNearbyAlliesOption = AddToggleOption(MMELocalization.Text("Milk Drink Curse Targets Nearby Allies"), JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkTrapNearbyAllies", 1) == 1, chestMilkTrapFlags)
    chestMilkTrapChanceOption = AddSliderOption(MMELocalization.Text("Chest Trap Chance"), JsonUtil.GetIntValue(SettingsFile, "chestMilkTrapChance", 33), "{0}%", chestMilkTrapFlags)
    chestMilkTrapCooldownOption = AddSliderOption(MMELocalization.Text("Base Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "chestMilkTrapCooldownHours", 1.0), MMELocalization.Text("{0} game hours"), chestMilkTrapFlags)
    chestMilkTrapVariationOption = AddSliderOption(MMELocalization.Text("Random Variation"), JsonUtil.GetFloatValue(SettingsFile, "chestMilkTrapCooldownVariation", 0.0), MMELocalization.Text("+/- {0} game hours"), chestMilkTrapFlags)
    chestMilkTrapNotificationOption = AddToggleOption(MMELocalization.Text("Chest Drink Notification"), JsonUtil.GetIntValue(SettingsFile, "enableChestMilkTrapNotification", 1) == 1, chestMilkTrapFlags)
    chestMilkTrapNarrationOption = AddToggleOption(MMELocalization.Text("Skyrim.Net Narration"), JsonUtil.GetIntValue(SettingsFile, "enableChestMilkTrapNarration", 1) == 1, chestMilkTrapFlags)
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("Milk Maid Curse Traps"))
    milkMaidCurseMasterOption = AddToggleOption(MMELocalization.Text("Enable Milk Maid Curse Trap"), JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidCurseTrap", 1) == 1)
    Int curseFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidCurseTrap", 1) != 1
        curseFlags = OPTION_FLAG_DISABLED
    EndIf
    milkMaidTrapNearbyAlliesOption = AddToggleOption(MMELocalization.Text("Milk Maid Curse Targets Nearby Allies"), JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidTrapNearbyAllies", 1) == 1, curseFlags)
    dungeonChestMilkMaidOption = AddToggleOption(MMELocalization.Text("Boss Chests"), JsonUtil.GetIntValue(SettingsFile, "enableDungeonChestMilkMaid", 1) == 1, curseFlags)
    Int dungeonChestChanceFlags = curseFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableDungeonChestMilkMaid", 1) != 1
        dungeonChestChanceFlags = OPTION_FLAG_DISABLED
    EndIf
    milkMaidCurseSurgeOption = AddSliderOption(MMELocalization.Text("Existing Maid Curse: Added Milk"), JsonUtil.GetIntValue(SettingsFile, "milkMaidCurseSurgePercent", 50), MMELocalization.Text("{0}% of capacity"), curseFlags)
    dungeonChestMilkMaidChanceOption = AddSliderOption(MMELocalization.Text("Boss Chest Chance"), JsonUtil.GetIntValue(SettingsFile, "dungeonChestMilkMaidChance", 100), "{0}%", dungeonChestChanceFlags)
    regularChestMilkMaidOption = AddToggleOption(MMELocalization.Text("Regular Chests"), JsonUtil.GetIntValue(SettingsFile, "enableRegularChestMilkMaid", 1) == 1, curseFlags)
    Int regularChestChanceFlags = curseFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableRegularChestMilkMaid", 1) != 1
        regularChestChanceFlags = OPTION_FLAG_DISABLED
    EndIf
    regularChestMilkMaidChanceOption = AddSliderOption(MMELocalization.Text("Regular Chest Chance"), JsonUtil.GetIntValue(SettingsFile, "regularChestMilkMaidChance", 10), "{0}%", regularChestChanceFlags)
    forcedMilkMaidNotificationOption = AddToggleOption(MMELocalization.Text("Enable Milk Maid Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidNotification", 1) == 1)
    forcedMilkMaidLactacidStoryOption = AddToggleOption(MMELocalization.Text("Enable Milk Maid Stories"), JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidStory", 1) == 1)
    forcedMilkMaidNarrationOption = AddToggleOption(MMELocalization.Text("Enable Skyrim.Net Narration"), JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidNarration", 1) == 1)
    Int chestNarrationFlags = curseFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidNarration", 1) != 1
        chestNarrationFlags = OPTION_FLAG_DISABLED
    EndIf
    chestCurseNarrationOption = AddToggleOption(MMELocalization.Text("Enable Chest Curse Narration"), JsonUtil.GetIntValue(SettingsFile, "enableChestCurseNarration", 1) == 1, chestNarrationFlags)
    forcedMilkMaidDiagnosticOption = AddToggleOption(MMELocalization.Text("Enable Milk Maid Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableForcedMilkMaidDiagnostic", 0) == 1)
    AddHeaderOption(MMELocalization.Text("Reverse Milk Maid Leveling"))
    reverseDurationOption = AddSliderOption(MMELocalization.Text("Reverse Leveling Duration"), MMEReverseLevel.GetDuration(), MMELocalization.Text("{0} game hours"))
    reversePlayerLevelOption = AddSliderOption(MMELocalization.Text("Minimum Milk Maid Level"), MMEReverseLevel.GetRequiredLevel(), "{0}")
EndFunction

Function DrawMilkDrinkingPage()
    AddHeaderOption(MMELocalization.Text("Inn and Palace Drinking"))
    innPalaceMilkDrinkingOption = AddToggleOption(MMELocalization.Text("Enable Inn and Palace Drinking"), JsonUtil.GetIntValue(SettingsFile, "enableInnPalaceMilkDrinking", 1) == 1)
    Int innPalaceFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableInnPalaceMilkDrinking", 1) != 1
        innPalaceFlags = OPTION_FLAG_DISABLED
    EndIf
    guildTavernMilkDrinkingOption = AddToggleOption(MMELocalization.Text("Guild and Tavern Locations"), JsonUtil.GetIntValue(SettingsFile, "enableGuildTavernMilkDrinking", 1) == 1, innPalaceFlags)
    jarlResidenceMilkDrinkingOption = AddToggleOption(MMELocalization.Text("Jarl Residences"), JsonUtil.GetIntValue(SettingsFile, "enableJarlResidenceMilkDrinking", 1) == 1, innPalaceFlags)
    townMilkDrinkOption = AddToggleOption(MMELocalization.Text("Town Milk Drink"), JsonUtil.GetIntValue(SettingsFile, "enableTownMilkDrink", 1) == 1)
    Int townDrinkFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableTownMilkDrink", 1) != 1
        townDrinkFlags = OPTION_FLAG_DISABLED
    EndIf
    townMilkDrinkChanceOption = AddSliderOption(MMELocalization.Text("Town Drink Chance"), JsonUtil.GetIntValue(SettingsFile, "townMilkDrinkChance", 25), "{0}%", townDrinkFlags)
    townUniqueNPCPreferenceOption = AddToggleOption(MMELocalization.Text("Favor Unique Town NPCs"), JsonUtil.GetIntValue(SettingsFile, "enableTownUniqueNPCPreference", 1) == 1, townDrinkFlags)
    Int uniquePreferenceFlags = townDrinkFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableTownUniqueNPCPreference", 1) != 1
        uniquePreferenceFlags = OPTION_FLAG_DISABLED
    EndIf
    townUniqueNPCPreferenceChanceOption = AddSliderOption(MMELocalization.Text("Unique NPC Preference"), JsonUtil.GetIntValue(SettingsFile, "townUniqueNPCPreferenceChance", 75), "{0}%", uniquePreferenceFlags)
    Int sharedVenueFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableInnPalaceMilkDrinking", 1) != 1 && JsonUtil.GetIntValue(SettingsFile, "enableTownMilkDrink", 1) != 1
        sharedVenueFlags = OPTION_FLAG_DISABLED
    EndIf
    innPalaceDrinkDelayOption = AddSliderOption(MMELocalization.Text("Drink Delay"), JsonUtil.GetFloatValue(SettingsFile, "innPalaceDrinkDelaySeconds", 11.0), MMELocalization.Text("{0} seconds"), sharedVenueFlags)
    innPalaceDrinkVariationOption = AddSliderOption(MMELocalization.Text("Delay Randomization"), JsonUtil.GetFloatValue(SettingsFile, "innPalaceDrinkDelayVariation", 10.0), MMELocalization.Text("+/-{0} seconds"), sharedVenueFlags)
    innPalaceDrinkCooldownOption = AddSliderOption(MMELocalization.Text("Shared Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "innPalaceDrinkCooldownHours", 4.0), MMELocalization.Text("{0} game hours"), sharedVenueFlags)
    AddHeaderOption(MMELocalization.Text("Milk Cravings"))
    milkCravingsOption = AddToggleOption(MMELocalization.Text("Enable Milk Cravings"), JsonUtil.GetIntValue(SettingsFile, "enableMilkCravings", 1) == 1)
    Int milkCravingFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkCravings", 1) != 1
        milkCravingFlags = OPTION_FLAG_DISABLED
    EndIf
    Int milkCravingNarrationFlags = milkCravingFlags
    If !MMEAlertsSkyrimNet.IsAvailable()
        milkCravingNarrationFlags = OPTION_FLAG_DISABLED
    EndIf
    milkCravingNarrationOption = AddToggleOption(MMELocalization.Text("Skyrim.Net Craving Narration"), JsonUtil.GetIntValue(SettingsFile, "enableMilkCravingNarration", 1) == 1, milkCravingNarrationFlags)
    milkCravingIntervalOption = AddSliderOption(MMELocalization.Text("Craving Interval"), JsonUtil.GetFloatValue(SettingsFile, "milkCravingIntervalHours", 48.0), MMELocalization.Text("{0} game hours"), milkCravingFlags)
    milkCravingVariationOption = AddSliderOption(MMELocalization.Text("Interval Randomization"), JsonUtil.GetFloatValue(SettingsFile, "milkCravingIntervalVariation", 24.0), MMELocalization.Text("+/-{0} game hours"), milkCravingFlags)
    milkCravingChanceOption = AddSliderOption(MMELocalization.Text("Trigger Chance"), JsonUtil.GetIntValue(SettingsFile, "milkCravingTriggerChance", 100), "{0}%", milkCravingFlags)
    milkCravingGiveInDelayOption = AddSliderOption(MMELocalization.Text("Maximum Give-In Delay"), JsonUtil.GetFloatValue(SettingsFile, "milkCravingGiveInDelayHours", 4.0), MMELocalization.Text("{0} game hours"), milkCravingFlags)
    AddHeaderOption(MMELocalization.Text("Auto Self-Milking"))
    autoSelfMilkingOption = AddToggleOption(MMELocalization.Text("Enable Auto Self-Milking"), JsonUtil.GetIntValue(SettingsFile, "enableAutoSelfMilking", 1) == 1)
    Int autoSelfMilkingFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableAutoSelfMilking", 1) != 1
        autoSelfMilkingFlags = OPTION_FLAG_DISABLED
    EndIf
    autoSelfMilkingDelayOption = AddSliderOption(MMELocalization.Text("Self-Milking Delay"), JsonUtil.GetFloatValue(SettingsFile, "autoSelfMilkingDelayHours", 1.0), MMELocalization.Text("{0} game hours"), autoSelfMilkingFlags)
    milkingMoansOption = AddToggleOption(MMELocalization.Text("Milking Start/End Moans"), JsonUtil.GetIntValue(SettingsFile, "enableMilkingMoans", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Milk Gain Per Drink"))
    milkmaidLevelBonusOption = AddToggleOption(MMELocalization.Text("MME Level Bonus"), JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidLevelBonus", 1) == 1)
    flatMilkBonusOption = AddSliderOption(MMELocalization.Text("Flat Milk Bonus"), JsonUtil.GetFloatValue(SettingsFile, "flatMilkBonus", 1.0), MMELocalization.Text("+{1} milk"))
    lactacidMultiplierOption = AddSliderOption(MMELocalization.Text("Lactacid Multiplier"), JsonUtil.GetFloatValue(SettingsFile, "lactacidFlatMultiplier", 2.0), "x{1}")
    AddHeaderOption(MMELocalization.Text("Drinking Feedback"))
    drinkMoansOption = AddToggleOption(MMELocalization.Text("Drink Milk Moans"), JsonUtil.GetIntValue(SettingsFile, "enableDrinkMoans", 1) == 1)
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("Breastfeeding"))
    breastfeedingMilkEffectsOption = AddToggleOption(MMELocalization.Text("Breastfeeding Gives Milk"), JsonUtil.GetIntValue(SettingsFile, "enableBreastfeedingMilkEffects", 1) == 1)
    Bool elsieDetected = MMEElsieBreastfeeding.IsDetected()
    elsieDetectedOption = AddToggleOption(MMELocalization.Text("Elsie LaVache Detected"), elsieDetected, OPTION_FLAG_DISABLED)
    Int elsieMilkFlags = OPTION_FLAG_NONE
    If !MMEElsieBreastfeeding.IsAvailable()
        elsieMilkFlags = OPTION_FLAG_DISABLED
    EndIf
    elsieBreastfeedingMilkEffectsOption = AddToggleOption(MMELocalization.Text("Elsie Breastfeeding Gives Milk"), JsonUtil.GetIntValue(SettingsFile, "enableElsieBreastfeedingMilkEffects", 1) == 1, elsieMilkFlags)
    Int ostimFlags = OPTION_FLAG_DISABLED
    If MMEOStimBreastfeeding.IsOStimDetected()
        ostimFlags = OPTION_FLAG_NONE
    EndIf
    ostimBreastfeedingDurationOption = AddSliderOption(MMELocalization.Text("OStim Breastfeeding Scene Duration"), JsonUtil.GetFloatValue(SettingsFile, "ostimBreastfeedingDuration", 20.0), MMELocalization.Text("{0} seconds"), ostimFlags)
    AddHeaderOption(MMELocalization.Text("Easy Mode"))
    giveMilkEasyModeOption = AddToggleOption(MMELocalization.Text("Free Jug for Give Milk"), JsonUtil.GetIntValue(SettingsFile, "enableGiveMilkEasyMode", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Player Milk Drinking"))
    playerDrinkNotificationsOption = AddToggleOption(MMELocalization.Text("Player Drink Notifications"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNotifications", 1) == 1)
    playerMilkMaidConversionOption = AddToggleOption(MMELocalization.Text("Milk Can Create Player Milk Maid"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkMaidConversion", 1) == 1)
    Int conversionChanceFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkMaidConversion", 1) != 1
        conversionChanceFlags = OPTION_FLAG_DISABLED
    EndIf
    playerMilkMaidConversionChanceOption = AddSliderOption(MMELocalization.Text("Milk Maid Conversion Chance"), JsonUtil.GetIntValue(SettingsFile, "playerMilkMaidConversionChance", 100), "{0}%", conversionChanceFlags)
    playerDrinkAnimationOption = AddToggleOption(MMELocalization.Text("Player Milk-Drink Animation"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkAnimation", 0) == 1)
    playerDrinkAnimationDurationOption = AddSliderOption(MMELocalization.Text("Player Milk-Drink Animation Duration"), JsonUtil.GetFloatValue(SettingsFile, "playerDrinkAnimationDuration", 3.0), MMELocalization.Text("{0} seconds"))
    AddHeaderOption(MMELocalization.Text("NPC Milk Drinking"))
    npcMilkEffectsOption = AddToggleOption(MMELocalization.Text("NPC Milk Effects"), JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkEffects", 1) == 1)
    npcDrinkNotificationsOption = AddToggleOption(MMELocalization.Text("NPC Drink Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNotifications", 1) == 1)
    npcDrinkAnimationOption = AddToggleOption(MMELocalization.Text("NPC Milk-Drink Animation"), JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkAnimation", 0) == 1)
    npcDrinkAnimationDurationOption = AddSliderOption(MMELocalization.Text("NPC Milk-Drink Animation Duration"), JsonUtil.GetFloatValue(SettingsFile, "npcDrinkAnimationDuration", 3.0), MMELocalization.Text("{0} seconds"))
    AddHeaderOption(MMELocalization.Text("Non-Milkmaid Drinking"))
    nonMilkmaidFemaleDrinkingOption = AddToggleOption(MMELocalization.Text("Allow Adult Women"), JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidFemaleDrinking", 1) == 1)
    nonMilkmaidFemaleArousalOption = AddSliderOption(MMELocalization.Text("Women Arousal Per Drink"), JsonUtil.GetFloatValue(SettingsFile, "nonMilkmaidFemaleArousal", 20.0), "+{0}")
    nonMilkmaidMaleDrinkingOption = AddToggleOption(MMELocalization.Text("Allow Adult Men"), JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidMaleDrinking", 1) == 1)
    nonMilkmaidMaleArousalOption = AddSliderOption(MMELocalization.Text("Men Arousal Per Drink"), JsonUtil.GetFloatValue(SettingsFile, "nonMilkmaidMaleArousal", 20.0), "+{0}")
    nonMilkmaidDrinkNotificationsOption = AddToggleOption(MMELocalization.Text("Flavor Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidDrinkNotifications", 1) == 1)
EndFunction

Function DrawArousalPage()
    Bool arousalAvailable = MMEArousalBridge.IsAvailable()
    Int arousalFlags = OPTION_FLAG_DISABLED
    If arousalAvailable
        arousalFlags = OPTION_FLAG_NONE
    EndIf
    AddHeaderOption(MMELocalization.Text("Integration Status"))
    arousalStatusOption = AddToggleOption(MMELocalization.Text("SexLab Arousal Detected"), arousalAvailable, OPTION_FLAG_DISABLED)
    AddHeaderOption(MMELocalization.Text("Milk Drinking"))
    milkDrinkArousalOption = AddToggleOption(MMELocalization.Text("Milk Raises Arousal"), JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkArousal", 1) == 1, arousalFlags)
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkArousal", 1) != 1
        arousalFlags = OPTION_FLAG_DISABLED
    EndIf
    milkDrinkArousalAmountOption = AddSliderOption(MMELocalization.Text("Arousal Per Milk"), JsonUtil.GetFloatValue(SettingsFile, "milkDrinkArousal", 10.0), "+{0}", arousalFlags)
    AddHeaderOption(MMELocalization.Text("Arousal Reactions"))
    Int arousalEffectMasterFlags = OPTION_FLAG_DISABLED
    If arousalAvailable
        arousalEffectMasterFlags = OPTION_FLAG_NONE
    EndIf
    arousalEffectsOption = AddToggleOption(MMELocalization.Text("Enable Arousal Reactions"), JsonUtil.GetIntValue(SettingsFile, "enableArousalEffects", 1) == 1, arousalEffectMasterFlags)
    Int arousalEffectFlags = arousalEffectMasterFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableArousalEffects", 1) != 1
        arousalEffectFlags = OPTION_FLAG_DISABLED
    EndIf
    arousalEffectNotificationsOption = AddToggleOption(MMELocalization.Text("Show Arousal Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableArousalEffectNotifications", 1) == 1, arousalEffectFlags)
    arousalEffectSoundsOption = AddToggleOption(MMELocalization.Text("Play Arousal Sounds"), JsonUtil.GetIntValue(SettingsFile, "enableArousalEffectSounds", 1) == 1, arousalEffectFlags)
    arousalEffectAnimationsOption = AddToggleOption(MMELocalization.Text("Play Arousal Animations"), JsonUtil.GetIntValue(SettingsFile, "enableArousalEffectAnimations", 1) == 1, arousalEffectFlags)
    arousalMilkMaidRouteOption = AddToggleOption(MMELocalization.Text("Always React for Milk Maids"), JsonUtil.GetIntValue(SettingsFile, "enableArousalMilkMaidRoute", 1) == 1, arousalEffectFlags)
    arousalMilkDrinkRouteOption = AddToggleOption(MMELocalization.Text("React After Milk Drinking"), JsonUtil.GetIntValue(SettingsFile, "enableArousalMilkDrinkRoute", 1) == 1, arousalEffectFlags)
    arousalEveryoneRouteOption = AddToggleOption(MMELocalization.Text("Include Everyone Else"), JsonUtil.GetIntValue(SettingsFile, "enableArousalEveryoneRoute", 0) == 1, arousalEffectFlags)
    arousalEffectDelayOption = AddSliderOption(MMELocalization.Text("Reaction Delay"), JsonUtil.GetFloatValue(SettingsFile, "arousalEffectDelay", 5.0), MMELocalization.Text("{0} seconds"), arousalEffectFlags)
    arousalEffectCooldownOption = AddSliderOption(MMELocalization.Text("Reaction Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "arousalEffectCooldown", 5.0), MMELocalization.Text("{0} seconds"), arousalEffectFlags)
    arousalEffectCooldownVariationOption = AddSliderOption(MMELocalization.Text("Cooldown Randomization"), JsonUtil.GetFloatValue(SettingsFile, "arousalEffectCooldownVariation", 0.0), MMELocalization.Text("+/- {0} seconds"), arousalEffectFlags)
    arousalLowThresholdOption = AddSliderOption(MMELocalization.Text("Low Threshold"), JsonUtil.GetIntValue(SettingsFile, "arousalLowThreshold", 20), "{0}", arousalEffectFlags)
    arousalMediumThresholdOption = AddSliderOption(MMELocalization.Text("Medium Threshold"), JsonUtil.GetIntValue(SettingsFile, "arousalMediumThreshold", 50), "{0}", arousalEffectFlags)
    arousalHighThresholdOption = AddSliderOption(MMELocalization.Text("High Threshold"), JsonUtil.GetIntValue(SettingsFile, "arousalHighThreshold", 80), "{0}", arousalEffectFlags)
EndFunction

Function DrawArmorPage()
    AddHeaderOption(MMELocalization.Text("Service Armor Checks"))
    armorCheckReminderOption = AddToggleOption(MMELocalization.Text("Armor Check Reminder"), JsonUtil.GetIntValue(SettingsFile, "enableArmorCheckReminder", 1) == 1)
    Int reminderFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableArmorCheckReminder", 1) != 1
        reminderFlags = OPTION_FLAG_DISABLED
    EndIf
    armorCheckReminderCooldownOption = AddSliderOption(MMELocalization.Text("Reminder Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "armorCheckReminderCooldown", 60.0), MMELocalization.Text("{0} seconds"), reminderFlags)
    AddHeaderOption(MMELocalization.Text("Armor Stripping"))
    extensionsArmorStrippingOption = AddToggleOption(MMELocalization.Text("Override MME Armor Stripping"), JsonUtil.GetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1) == 1)
    Int stripFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableExtensionsArmorStripping", 1) != 1
        stripFlags = OPTION_FLAG_DISABLED
    EndIf
    milkingEquipmentRefitOption = AddToggleOption(MMELocalization.Text("Require Milking Equipment Refits"), JsonUtil.GetIntValue(SettingsFile, "enableMilkingEquipmentRefits", 1) == 1, stripFlags)
    stripAllArmorOverrideOption = AddToggleOption(MMELocalization.Text("Strip All Armor / Ignore Protection"), JsonUtil.GetIntValue(SettingsFile, "enableStripAllArmor", 0) == 1, stripFlags)
    Int narrationFlags = stripFlags
    If narrationFlags == OPTION_FLAG_NONE && JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarration", 1) != 1
        narrationFlags = OPTION_FLAG_DISABLED
    EndIf
    armorStripHeavyEnabledOption = AddToggleOption(MMELocalization.Text("Enable Heavy Armor Stripping"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripHeavy", 1) == 1, stripFlags)
    Int heavyStripFlags = stripFlags
    If heavyStripFlags == OPTION_FLAG_NONE && JsonUtil.GetIntValue(SettingsFile, "enableArmorStripHeavy", 1) != 1
        heavyStripFlags = OPTION_FLAG_DISABLED
    EndIf
    armorStripHeavyThresholdOption = AddSliderOption(MMELocalization.Text("Heavy Armor Fullness Threshold"), JsonUtil.GetFloatValue(SettingsFile, "armorStripHeavyPercent", 70.0), "{0}%", heavyStripFlags)
    armorStripLightEnabledOption = AddToggleOption(MMELocalization.Text("Enable Light Armor Stripping"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripLight", 1) == 1, stripFlags)
    Int lightStripFlags = stripFlags
    If lightStripFlags == OPTION_FLAG_NONE && JsonUtil.GetIntValue(SettingsFile, "enableArmorStripLight", 1) != 1
        lightStripFlags = OPTION_FLAG_DISABLED
    EndIf
    armorStripLightThresholdOption = AddSliderOption(MMELocalization.Text("Light Armor Fullness Threshold"), JsonUtil.GetFloatValue(SettingsFile, "armorStripLightPercent", 85.0), "{0}%", lightStripFlags)
    armorStripClothingEnabledOption = AddToggleOption(MMELocalization.Text("Enable Clothing Stripping"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripClothing", 1) == 1, stripFlags)
    Int clothingStripFlags = stripFlags
    If clothingStripFlags == OPTION_FLAG_NONE && JsonUtil.GetIntValue(SettingsFile, "enableArmorStripClothing", 1) != 1
        clothingStripFlags = OPTION_FLAG_DISABLED
    EndIf
    armorStripClothingThresholdOption = AddSliderOption(MMELocalization.Text("Clothing Fullness Threshold"), JsonUtil.GetFloatValue(SettingsFile, "armorStripClothingPercent", 100.0), "{0}%", clothingStripFlags)
    flatMilkStrippingOption = AddToggleOption(MMELocalization.Text("Flat Milk Stripping"), JsonUtil.GetIntValue(SettingsFile, "enableFlatMilkStripping", 0) == 1, stripFlags)
    Int flatHeavyFlags = heavyStripFlags
    Int flatLightFlags = lightStripFlags
    Int flatClothingFlags = clothingStripFlags
    If JsonUtil.GetIntValue(SettingsFile, "enableFlatMilkStripping", 0) != 1
        flatHeavyFlags = OPTION_FLAG_DISABLED
        flatLightFlags = OPTION_FLAG_DISABLED
        flatClothingFlags = OPTION_FLAG_DISABLED
    EndIf
    flatMilkHeavyOption = AddSliderOption(MMELocalization.Text("Heavy Armor Milk Amount"), JsonUtil.GetFloatValue(SettingsFile, "armorStripHeavyMilk", 4.0), MMELocalization.Text("{0} milk"), flatHeavyFlags)
    flatMilkLightOption = AddSliderOption(MMELocalization.Text("Light Armor Milk Amount"), JsonUtil.GetFloatValue(SettingsFile, "armorStripLightMilk", 8.0), MMELocalization.Text("{0} milk"), flatLightFlags)
    flatMilkClothingOption = AddSliderOption(MMELocalization.Text("Clothing Milk Amount"), JsonUtil.GetFloatValue(SettingsFile, "armorStripClothingMilk", 12.0), MMELocalization.Text("{0} milk"), flatClothingFlags)
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("Armor Strip Reactions"))
    armorStripNotificationOption = AddToggleOption(MMELocalization.Text("Strip Notification"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNotification", 1) == 1, stripFlags)
    armorStripMoanOption = AddToggleOption(MMELocalization.Text("Strip Moan"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripMoan", 1) == 1, stripFlags)
    armorStripNarrationOption = AddToggleOption(MMELocalization.Text("Skyrim.Net Strip Narration"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarration", 1) == 1, stripFlags)
    armorStripNarrationChanceOption = AddSliderOption(MMELocalization.Text("Narration Chance"), JsonUtil.GetIntValue(SettingsFile, "armorStripNarrationChance", 100), "{0}%", narrationFlags)
    armorStripNarrationCooldownOption = AddSliderOption(MMELocalization.Text("Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "armorStripNarrationCooldown", 300.0) / 60.0, MMELocalization.Text("{0} minutes"), narrationFlags)
    AddHeaderOption(MMELocalization.Text("Timed Armor Bond"))
    timedArmorDurationOption = AddSliderOption(MMELocalization.Text("Lock Duration"), JsonUtil.GetFloatValue(SettingsFile, "timedArmorLockDays", 3.0), MMELocalization.Text("{0} game days"))
EndFunction

Function DrawSkyrimNetPage()
    AddHeaderOption(MMELocalization.Text("Integration Status"))
    skyrimNetStatusOption = AddToggleOption(MMELocalization.Text("Skyrim.Net Detected"), MMEAlertsSkyrimNet.IsAvailable(), OPTION_FLAG_DISABLED)
    AddHeaderOption(MMELocalization.Text("Event Tracking"))
    fullHistoryOption = AddToggleOption(MMELocalization.Text("Track Full Capacity"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetFullEvents", 1) == 1)
    skyrimNetMilkDrinksOption = AddToggleOption(MMELocalization.Text("Track Milk Drinks"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkDrinks", 1) == 1)
    skyrimNetMilkingEventsOption = AddToggleOption(MMELocalization.Text("Track Milking Start / Completion"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkingEvents", 1) == 1)
    skyrimNetMilkmaidCreatedOption = AddToggleOption(MMELocalization.Text("Track New Milkmaids"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkmaidCreated", 1) == 1)
    skyrimNetMilkStatusesOption = AddToggleOption(MMELocalization.Text("Milk Status in Actor Prompts"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1) == 1)
    ; Legacy interval field/handlers retained for save compatibility; no active control.
    AddHeaderOption(MMELocalization.Text("Milk Armor"))
    nearbyMilkArmorStatusOption = AddToggleOption(MMELocalization.Text("Armor Status in Actor Prompts"), JsonUtil.GetIntValue(SettingsFile, "enableNearbyMilkArmorStatus", 1) == 1)
    playerMilkArmorEquipNarrationOption = AddToggleOption(MMELocalization.Text("Player Milk Armor Equip Narration"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", 1) == 1)
    npcMilkArmorEquipNarrationOption = AddToggleOption(MMELocalization.Text("NPC Milk Armor Equip Narration"), JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", 1) == 1)
    Int playerArmorNarrationFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkArmorEquipNarration", 1) != 1
        playerArmorNarrationFlags = OPTION_FLAG_DISABLED
    EndIf
    Int npcArmorNarrationFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkArmorEquipNarration", 1) != 1
        npcArmorNarrationFlags = OPTION_FLAG_DISABLED
    EndIf
    playerMilkingArmorNarrationCooldownOption = AddSliderOption(MMELocalization.Text("Player Armor Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "playerMilkingArmorNarrationCooldown", 120.0), MMELocalization.Text("{0} seconds"), playerArmorNarrationFlags)
    npcMilkingArmorNarrationCooldownOption = AddSliderOption(MMELocalization.Text("NPC Armor Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "npcMilkingArmorNarrationCooldown", 300.0), MMELocalization.Text("{0} seconds"), npcArmorNarrationFlags)
    AddHeaderOption(MMELocalization.Text("Actions"))
    selfMilkingActionOption = AddToggleOption(MMELocalization.Text("Allow Self-Milking Action"), JsonUtil.GetIntValue(SettingsFile, "enableSelfMilkingAction", 1) == 1)
    pairedMilkingActionOption = AddToggleOption(MMELocalization.Text("Allow Paired Milking Action"), JsonUtil.GetIntValue(SettingsFile, "enablePairedMilkingAction", 1) == 1)
    giveMilkActionOption = AddToggleOption(MMELocalization.Text("Allow Give-and-Drink Actions"), JsonUtil.GetIntValue(SettingsFile, "enableGiveMilkAction", 1) == 1)
    createMilkMaidActionOption = AddToggleOption(MMELocalization.Text("Allow Create Milk Maid Action"), JsonUtil.GetIntValue(SettingsFile, "enableCreateMilkMaidAction", 1) == 1)
    actorDrinkMilkRemovalOption = AddToggleOption(MMELocalization.Text("Milkmaid Giver Spends Milk"), JsonUtil.GetIntValue(SettingsFile, "enableActorDrinkMilkRemoval", 1) == 1)
    Int breastfeedingCooldownFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enablePairedMilkingAction", 1) != 1
        breastfeedingCooldownFlags = OPTION_FLAG_DISABLED
    EndIf
    breastfeedingActionCooldownOption = AddSliderOption(MMELocalization.Text("Breastfeeding Action Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "breastfeedingActionCooldown", 45.0), MMELocalization.Text("{0} seconds"), breastfeedingCooldownFlags)
    Int giveMilkCooldownFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableGiveMilkAction", 1) != 1
        giveMilkCooldownFlags = OPTION_FLAG_DISABLED
    EndIf
    giveMilkActionCooldownOption = AddSliderOption(MMELocalization.Text("Give Milk Action Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "giveMilkActionCooldown", 0.0), MMELocalization.Text("{0} seconds"), giveMilkCooldownFlags)
    AddHeaderOption(MMELocalization.Text("Milking Completion"))
    postMilkingNarrationOption = AddToggleOption(MMELocalization.Text("Narrate Milking Completion"), JsonUtil.GetIntValue(SettingsFile, "enablePostMilkingNarration", 1) == 1)
    Int completionFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enablePostMilkingNarration", 1) != 1
        completionFlags = OPTION_FLAG_DISABLED
    EndIf
    postMilkingCooldownOption = AddSliderOption(MMELocalization.Text("Completion Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "postMilkingNarrationCooldown", 120.0), MMELocalization.Text("{0} seconds"), completionFlags)
    postMilkingChanceOption = AddSliderOption(MMELocalization.Text("Completion Chance"), JsonUtil.GetIntValue(SettingsFile, "postMilkingNarrationChance", 100), "{0}%", completionFlags)
    AddHeaderOption(MMELocalization.Text("AI Reactions"))
    milkFullNarrationOption = AddToggleOption(MMELocalization.Text("Narrate Milk Full"), JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarration", 1) == 1)
    Int narrationFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarration", 1) != 1
        narrationFlags = OPTION_FLAG_DISABLED
    EndIf
    milkFullNarrationChanceOption = AddSliderOption(MMELocalization.Text("Milk Full Narration Chance"), JsonUtil.GetIntValue(SettingsFile, "milkFullNarrationChance", 100), "{0}%", narrationFlags)
    milkFullNarrationCooldownOption = AddSliderOption(MMELocalization.Text("Milk Full Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "milkFullNarrationCooldown", 120.0), MMELocalization.Text("{0} seconds"), narrationFlags)
    milkHalfFullNarrationOption = AddToggleOption(MMELocalization.Text("Half-Full Milk Narration"), JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarration", 1) == 1)
    narrationFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarration", 1) != 1
        narrationFlags = OPTION_FLAG_DISABLED
    EndIf
    milkHalfFullNarrationCooldownOption = AddSliderOption(MMELocalization.Text("Half-Full Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "milkHalfFullNarrationCooldown", 60.0), MMELocalization.Text("{0} seconds"), narrationFlags)
    playerDrinkNarrationOption = AddToggleOption(MMELocalization.Text("Player Drink Narration"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarration", 0) == 1)
    narrationFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarration", 0) != 1
        narrationFlags = OPTION_FLAG_DISABLED
    EndIf
    playerDrinkNarrationCooldownOption = AddSliderOption(MMELocalization.Text("Player Drink Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "playerDrinkNarrationCooldown", 60.0), MMELocalization.Text("{0} seconds"), narrationFlags)
    playerDrinkNarrationChanceOption = AddSliderOption(MMELocalization.Text("Player Drink Narration Chance"), JsonUtil.GetIntValue(SettingsFile, "playerDrinkNarrationChance", 25), "{0}%", narrationFlags)
    milkmaidCreatedNarrationOption = AddToggleOption(MMELocalization.Text("New Milk Maid Narration"), JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", 1) == 1)
    narrationFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarration", 1) != 1
        narrationFlags = OPTION_FLAG_DISABLED
    EndIf
    milkmaidCreatedNarrationCooldownOption = AddSliderOption(MMELocalization.Text("New Milk Maid Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "milkmaidCreatedNarrationCooldown", 60.0), MMELocalization.Text("{0} seconds"), narrationFlags)
    npcDrinkNarrationOption = AddToggleOption(MMELocalization.Text("NPC Drink Narration"), JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarration", 1) == 1)
    narrationFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarration", 1) != 1
        narrationFlags = OPTION_FLAG_DISABLED
    EndIf
    npcDrinkNarrationCooldownOption = AddSliderOption(MMELocalization.Text("NPC Drink Narration Cooldown"), JsonUtil.GetFloatValue(SettingsFile, "npcDrinkNarrationCooldown", 60.0), MMELocalization.Text("{0} seconds"), narrationFlags)
EndFunction

Function DrawArmorThoughtsPage()
    AddHeaderOption(MMELocalization.Text("Milk Armor Thoughts"))
    milkMaidThoughtsOption = AddToggleOption(MMELocalization.Text("Enable Milk Armor Thoughts"), JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughts", 1) == 1)
    milkMaidThoughtsIntervalOption = AddSliderOption(MMELocalization.Text("Poll Interval"), JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsInterval", 12.0), MMELocalization.Text("{0} game hours"))
    milkMaidThoughtsRandomnessOption = AddSliderOption(MMELocalization.Text("Randomness (+/-)"), JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsRandomness", 4.0), MMELocalization.Text("{0} game hours"))
    milkMaidThoughtNarrationOption = AddToggleOption(MMELocalization.Text("Skyrim.Net Thought Narration"), JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtNarration", 1) == 1)
    armorThoughtSoundsOption = AddToggleOption(MMELocalization.Text("Armor Thought Sounds"), JsonUtil.GetIntValue(SettingsFile, "enableArmorThoughtSounds", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Devious Heavy Bondage"))
    boundMilkMaidThoughtsOption = AddToggleOption(MMELocalization.Text("Bound Milk Maid Thoughts"), JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkMaidThoughts", 1) == 1)
    boundMilkMaidThoughtsIntervalOption = AddSliderOption(MMELocalization.Text("Bound Thought Interval"), JsonUtil.GetFloatValue(SettingsFile, "boundMilkMaidThoughtsInterval", 24.0), MMELocalization.Text("{0} game hours"))
    boundMilkMaidThoughtsRandomnessOption = AddSliderOption(MMELocalization.Text("Bound Randomness (+/-)"), JsonUtil.GetFloatValue(SettingsFile, "boundMilkMaidThoughtsRandomness", 12.0), MMELocalization.Text("{0} game hours"))
    boundMilkMaidThoughtsChanceOption = AddSliderOption(MMELocalization.Text("Bound Thought Chance"), JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtsChance", 100), "{0}%")
    boundMilkMaidThoughtNarrationOption = AddToggleOption(MMELocalization.Text("Skyrim.Net Bound Narration"), JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkMaidThoughtNarration", 1) == 1)
    boundMilkMaidThoughtNarrationChanceOption = AddSliderOption(MMELocalization.Text("Bound Narration Chance"), JsonUtil.GetIntValue(SettingsFile, "boundMilkMaidThoughtNarrationChance", 100), "{0}%")
    boundMilkMaidThoughtSoundsOption = AddToggleOption(MMELocalization.Text("Devious Restraint Moans"), JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkMaidThoughtSounds", 1) == 1)
    boundMilkDrinkReactionOption = AddToggleOption(MMELocalization.Text("Milk Drink Restraint Reaction"), JsonUtil.GetIntValue(SettingsFile, "enableBoundMilkDrinkReaction", 1) == 1)
    boundMilkDrinkReactionChanceOption = AddSliderOption(MMELocalization.Text("Milk Drink Reaction Chance"), JsonUtil.GetIntValue(SettingsFile, "boundMilkDrinkReactionChance", 50), "{0}%")
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("Armor Story Reactions"))
    repeatOrdinaryArmorStoriesOption = AddToggleOption(MMELocalization.Text("Repeat Equipped Armor Stories"), JsonUtil.GetIntValue(SettingsFile, "enableRepeatOrdinaryArmorStories", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Milking Armor"))
    playerMilkingArmorEquipMoanOption = AddToggleOption(MMELocalization.Text("Player Equip Moan"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipMoan", 1) == 1)
    playerMilkingArmorEquipAnimationOption = AddToggleOption(MMELocalization.Text("Player Equip Animation"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerMilkingArmorEquipAnimation", 0) == 1)
    npcMilkingArmorEquipMoanOption = AddToggleOption(MMELocalization.Text("NPC Equip Moan"), JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkingArmorEquipMoan", 1) == 1)
    npcMilkingArmorEquipAnimationOption = AddToggleOption(MMELocalization.Text("NPC Equip Animation"), JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkingArmorEquipAnimation", 1) == 1)
    AddHeaderOption(MMELocalization.Text("AM Living Armor"))
    playerLivingArmorEquipMoanOption = AddToggleOption(MMELocalization.Text("Player Equip Moan"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingArmorEquipMoan", 1) == 1)
    playerLivingArmorEquipAnimationOption = AddToggleOption(MMELocalization.Text("Player Equip Animation"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingArmorEquipAnimation", 0) == 1)
    npcLivingArmorEquipMoanOption = AddToggleOption(MMELocalization.Text("NPC Equip Moan"), JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingArmorEquipMoan", 1) == 1)
    npcLivingArmorEquipAnimationOption = AddToggleOption(MMELocalization.Text("NPC Equip Animation"), JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingArmorEquipAnimation", 1) == 1)
    AddHeaderOption(MMELocalization.Text("AM Living Parasite"))
    playerLivingParasiteEquipMoanOption = AddToggleOption(MMELocalization.Text("Player Equip Moan"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipMoan", 1) == 1)
    playerLivingParasiteEquipAnimationOption = AddToggleOption(MMELocalization.Text("Player Equip Animation"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerLivingParasiteEquipAnimation", 0) == 1)
    npcLivingParasiteEquipMoanOption = AddToggleOption(MMELocalization.Text("NPC Equip Moan"), JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingParasiteEquipMoan", 1) == 1)
    npcLivingParasiteEquipAnimationOption = AddToggleOption(MMELocalization.Text("NPC Equip Animation"), JsonUtil.GetIntValue(SettingsFile, "enableNPCLivingParasiteEquipAnimation", 1) == 1)
EndFunction

Function DrawArmorEffectsPage()
    AddHeaderOption(MMELocalization.Text("Living / Parasite Armor"))
    armorInjectionOption = AddToggleOption(MMELocalization.Text("Enable Effects"), JsonUtil.GetIntValue(SettingsFile, "enableArmorInjections", 1) == 1)
    armorInjectionIntervalOption = AddSliderOption(MMELocalization.Text("Base Effect Interval"), JsonUtil.GetFloatValue(SettingsFile, "armorInjectionInterval", 12.0), MMELocalization.Text("{0} game hours"))
    armorInjectionVariationOption = AddSliderOption(MMELocalization.Text("Interval Variation (+/-)"), JsonUtil.GetFloatValue(SettingsFile, "armorInjectionVariation", 4.0), MMELocalization.Text("{0} game hours"))
    armorInjectionChanceOption = AddSliderOption(MMELocalization.Text("Effect Chance"), JsonUtil.GetIntValue(SettingsFile, "armorInjectionChance", 100), "{0}%")
    AddHeaderOption(MMELocalization.Text("Notifications"))
    armorInjectionNotificationOption = AddToggleOption(MMELocalization.Text("Show Effect Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionNotifications", 1) == 1)
    armorInjectionSoundOption = AddToggleOption(MMELocalization.Text("Notification Sound"), JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionSounds", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Skyrim.Net Narration"))
    armorInjectionNarrationOption = AddToggleOption(MMELocalization.Text("Enable Narration"), JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionNarration", 1) == 1)
    armorInjectionPlayerNarrationOption = AddToggleOption(MMELocalization.Text("Enable Player Narration"), JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionPlayerNarration", 1) == 1)
    armorInjectionNarrationChanceOption = AddSliderOption(MMELocalization.Text("Narration Chance"), JsonUtil.GetIntValue(SettingsFile, "armorInjectionNarrationChance", 100), "{0}%")
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("Dwemer Armor"))
    dwemerEffectOption = AddToggleOption(MMELocalization.Text("Enable Effects"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerEffects", 1) == 1)
    dwemerEffectIntervalOption = AddSliderOption(MMELocalization.Text("Base Effect Interval"), JsonUtil.GetFloatValue(SettingsFile, "dwemerEffectInterval", 12.0), MMELocalization.Text("{0} game hours"))
    dwemerEffectVariationOption = AddSliderOption(MMELocalization.Text("Interval Variation (+/-)"), JsonUtil.GetFloatValue(SettingsFile, "dwemerEffectVariation", 4.0), MMELocalization.Text("{0} game hours"))
    dwemerEffectChanceOption = AddSliderOption(MMELocalization.Text("Effect Chance"), JsonUtil.GetIntValue(SettingsFile, "dwemerEffectChance", 100), "{0}%")
    AddHeaderOption(MMELocalization.Text("Notifications"))
    dwemerEffectNotificationOption = AddToggleOption(MMELocalization.Text("Show Effect Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerEffectNotifications", 1) == 1)
    dwemerEffectSoundOption = AddToggleOption(MMELocalization.Text("Notification Sound"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerEffectSounds", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Skyrim.Net Narration"))
    dwemerEffectNarrationOption = AddToggleOption(MMELocalization.Text("Enable Narration"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerEffectNarration", 1) == 1)
    dwemerEffectPlayerNarrationOption = AddToggleOption(MMELocalization.Text("Enable Player Narration"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerEffectPlayerNarration", 1) == 1)
    dwemerEffectNarrationChanceOption = AddSliderOption(MMELocalization.Text("Narration Chance"), JsonUtil.GetIntValue(SettingsFile, "dwemerEffectNarrationChance", 100), "{0}%")
    ; Shared settings occupy twelve rows in each column. Tier settings
    ; belong only to Living/Parasite and share rows by intensity.
    SetCursorPosition(24)
    AddHeaderOption(MMELocalization.Text("Living / Parasite Tease Intensity"))
    SetCursorPosition(25)
    AddHeaderOption(MMELocalization.Text("Living / Parasite Animation Durations"))
    String[] tierLabels = new String[4]
    tierLabels[0] = MMELocalization.Text("Low")
    tierLabels[1] = MMELocalization.Text("Medium")
    tierLabels[2] = MMELocalization.Text("High")
    tierLabels[3] = MMELocalization.Text("Extreme")
    Int tierIndex = 0
    While tierIndex < 4
        SetCursorPosition(26 + tierIndex * 2)
        tentacleChanceOptions[tierIndex] = AddSliderOption(tierLabels[tierIndex] + MMELocalization.Text(" Tease Chance"), JsonUtil.GetIntValue(SettingsFile, MMETentacleTiers.ChanceKey(tierIndex + 1), MMETentacleTiers.DefaultChance(tierIndex + 1)), "{0}%")
        SetCursorPosition(27 + tierIndex * 2)
        tentacleDurationOptions[tierIndex] = AddSliderOption(tierLabels[tierIndex] + MMELocalization.Text(" Animation Duration"), MMETentacleTiers.Duration(tierIndex + 1), MMELocalization.Text("{1} seconds"))
        tierIndex += 1
    EndWhile
EndFunction

Function DrawTroubleshootPage()
    AddHeaderOption(MMELocalization.Text("Live Status"))
    diagnosticInstallStatusOption = AddTextOption(MMELocalization.Text("MME Extensions Records"), MMEDiagnostics.GetInstallStatus(), OPTION_FLAG_DISABLED)
    diagnosticOStimStatusOption = AddTextOption(MMELocalization.Text("OStim Integration"), MMEDiagnostics.GetOStimStatus(), OPTION_FLAG_DISABLED)
    diagnosticSexLabStatusOption = AddTextOption(MMELocalization.Text("SexLab Framework"), MMEDiagnostics.GetSexLabStatus(), OPTION_FLAG_DISABLED)
    diagnosticGateStatusOption = AddTextOption(MMELocalization.Text("OStim Dialogue Gate"), MMEDiagnostics.GetGateStatus(), OPTION_FLAG_DISABLED)
    diagnosticSexLabBusStateOption = AddTextOption(MMELocalization.Text("New Milk Maid SexLab Bus"), MMEDiagnostics.GetNewMilkMaidSexLabBusState(), OPTION_FLAG_DISABLED)
    diagnosticSexLabBusStopOption = AddTextOption(MMELocalization.Text("Last SexLab Bus Stop"), MMEDiagnostics.GetNewMilkMaidSexLabBusStop(), OPTION_FLAG_DISABLED)
    diagnosticSexLabBusFailureOption = AddTextOption(MMELocalization.Text("Last SexLab Bus Failure"), MMEDiagnostics.GetNewMilkMaidSexLabBusFailure(), OPTION_FLAG_DISABLED)
    diagnosticBlacksmithBusStateOption = AddTextOption(MMELocalization.Text("Blacksmith Dialogue Bus"), MMEDiagnostics.GetBlacksmithDialogueBusState(), OPTION_FLAG_DISABLED)
    diagnosticBlacksmithBusStopOption = AddTextOption(MMELocalization.Text("Last Blacksmith Bus Stop"), MMEDiagnostics.GetBlacksmithDialogueBusStop(), OPTION_FLAG_DISABLED)
    diagnosticBlacksmithBusFailureOption = AddTextOption(MMELocalization.Text("Last Blacksmith Bus Failure"), MMEDiagnostics.GetBlacksmithDialogueBusFailure(), OPTION_FLAG_DISABLED)
    diagnosticAlchemistBusStateOption = AddTextOption(MMELocalization.Text("Alchemist Dialogue Bus"), MMEDiagnostics.GetAlchemistDialogueBusState(), OPTION_FLAG_DISABLED)
    diagnosticAlchemistBusStopOption = AddTextOption(MMELocalization.Text("Last Alchemist Bus Stop"), MMEDiagnostics.GetAlchemistDialogueBusStop(), OPTION_FLAG_DISABLED)
    diagnosticAlchemistBusFailureOption = AddTextOption(MMELocalization.Text("Last Alchemist Bus Failure"), MMEDiagnostics.GetAlchemistDialogueBusFailure(), OPTION_FLAG_DISABLED)
    diagnosticMageBusStateOption = AddTextOption(MMELocalization.Text("Mage Dialogue Bus"), MMEDiagnostics.GetMageDialogueBusState(), OPTION_FLAG_DISABLED)
    diagnosticMageBusStopOption = AddTextOption(MMELocalization.Text("Last Mage Bus Stop"), MMEDiagnostics.GetMageDialogueBusStop(), OPTION_FLAG_DISABLED)
    diagnosticMageBusFailureOption = AddTextOption(MMELocalization.Text("Last Mage Bus Failure"), MMEDiagnostics.GetMageDialogueBusFailure(), OPTION_FLAG_DISABLED)
    AddHeaderOption(MMELocalization.Text("Audits & Reports"))
    diagnosticInstallAuditOption = AddTextOption(MMELocalization.Text("Run Install Audit"), MMELocalization.Text("RUN"))
    diagnosticMilkDrinkAuditOption = AddTextOption(MMELocalization.Text("Run Milk Drink Audit"), MMELocalization.Text("RUN"))
    diagnosticDialogueAuditOption = AddTextOption(MMELocalization.Text("Run Crosshair Dialogue Audit"), MMELocalization.Text("RUN"))
    diagnosticShowSexLabBusOption = AddTextOption(MMELocalization.Text("Show Last SexLab Bus Report"), MMELocalization.Text("RUN"))
    diagnosticShowBlacksmithBusOption = AddTextOption(MMELocalization.Text("Show Last Blacksmith Bus Report"), MMELocalization.Text("RUN"))
    diagnosticShowAlchemistBusOption = AddTextOption(MMELocalization.Text("Show Last Alchemist Bus Report"), MMELocalization.Text("RUN"))
    diagnosticShowMageBusOption = AddTextOption(MMELocalization.Text("Show Last Mage Bus Report"), MMELocalization.Text("RUN"))
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("Papyrus Logging"))
    papyrusTraceOption = AddToggleOption(MMELocalization.Text("Papyrus Logging"), JsonUtil.GetIntValue(SettingsFile, "enablePapyrusTrace", 0) == 1)
    Int verboseTraceFlags = OPTION_FLAG_NONE
    If JsonUtil.GetIntValue(SettingsFile, "enablePapyrusTrace", 0) != 1
        verboseTraceFlags = OPTION_FLAG_DISABLED
    EndIf
    verbosePapyrusTraceOption = AddToggleOption(MMELocalization.Text("Verbose Papyrus Logging"), JsonUtil.GetIntValue(SettingsFile, "enableVerbosePapyrusLogging", 0) == 1, verboseTraceFlags)
    AddHeaderOption(MMELocalization.Text("Narration JSON"))
    narrationReloadOption = AddTextOption(MMELocalization.Text("Reload Narration JSON"), MMELocalization.Text("RELOAD"))
    narrationImportOption = AddTextOption(MMELocalization.Text("Import Legacy Narration"), MMELocalization.Text("IMPORT"))
    AddHeaderOption(MMELocalization.Text("Output"))
    diagnosticNotificationsOption = AddToggleOption(MMELocalization.Text("In-Game Audit Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableDiagnosticNotifications", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Recovery"))
    Int timedArmorReleaseFlags = OPTION_FLAG_DISABLED
    If MMETimedArmorLock.IsLocked(Game.GetPlayer())
        timedArmorReleaseFlags = OPTION_FLAG_NONE
    EndIf
    timedArmorReleaseOption = AddTextOption(MMELocalization.Text("Release Player Armor"), MMELocalization.Text("RELEASE"), timedArmorReleaseFlags)
    timedNPCArmorReleaseOption = AddTextOption(MMELocalization.Text("Release Nearby NPC Armor"), MMELocalization.Text("RELEASE"))
    diagnosticRefreshGateOption = AddTextOption(MMELocalization.Text("Refresh OStim Dialogue Gate"), MMELocalization.Text("RUN"))
    diagnosticRefreshSexLabBusOption = AddTextOption(MMELocalization.Text("Refresh SexLab Bus Listeners"), MMELocalization.Text("RUN"))
    AddHeaderOption(MMELocalization.Text("Gameplay Tests"))
    estrusTestTypeOption = AddTextOption(MMELocalization.Text("Estrus Pregnancy Type"), MMEEstrusPregnancyTest.TypeName(estrusTestType))
    estrusTestRunOption = AddTextOption(MMELocalization.Text("Test Player Estrus Pregnancy"), MMELocalization.Text("RUN"))
    estrusTestResultOption = AddTextOption(MMELocalization.Text("Last Estrus Test"), estrusTestResult, OPTION_FLAG_DISABLED)
    diagnosticSpawnOManiaPotionOption = AddTextOption(MMELocalization.Text("Spawn OMania Dragon Egg Potion"), MMELocalization.Text("SPAWN"))
    diagnosticGlobalNPCDrinkTestOption = AddTextOption(MMELocalization.Text("Test Global NPC Milk Drink"), MMELocalization.Text("RUN"))
    diagnosticNewMilkmaidSexLabBusOption = AddTextOption(MMELocalization.Text("Run New Milk Maid Bus Test"), MMELocalization.Text("RUN"))
    diagnosticBlacksmithBusOption = AddTextOption(MMELocalization.Text("Run Blacksmith Dialogue Bus Test"), MMELocalization.Text("RUN"))
    diagnosticAlchemistBusOption = AddTextOption(MMELocalization.Text("Run Alchemist Dialogue Bus Test"), MMELocalization.Text("RUN"))
    diagnosticMageBusOption = AddTextOption(MMELocalization.Text("Run Mage Dialogue Bus Test"), MMELocalization.Text("RUN"))
    Int elsieMilkFlags = OPTION_FLAG_NONE
    If !MMEElsieBreastfeeding.IsAvailable()
        elsieMilkFlags = OPTION_FLAG_DISABLED
    EndIf
    elsieBreastfeedingTestOption = AddTextOption(MMELocalization.Text("Test Elsie Auto Breastfeeding"), MMELocalization.Text("RUN"), elsieMilkFlags)
    AddHeaderOption(MMELocalization.Text("Living / Parasite Diagnostics"))
    armorInjectionDiagnosticOption = AddToggleOption(MMELocalization.Text("Enable Effect Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableArmorInjectionDiagnostics", 0) == 1)
    runArmorInjectionCheckOption = AddTextOption(MMELocalization.Text("Run Effect Check Now"), MMELocalization.Text("RUN"))
    AddHeaderOption(MMELocalization.Text("Dwemer Diagnostics"))
    dwemerEffectDiagnosticOption = AddToggleOption(MMELocalization.Text("Enable Effect Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableDwemerEffectDiagnostics", 0) == 1)
    runDwemerEffectCheckOption = AddTextOption(MMELocalization.Text("Run Effect Check Now"), MMELocalization.Text("RUN"))
    AddHeaderOption(MMELocalization.Text("Reverse Leveling Tests"))
    reverseApplyOption = AddTextOption(MMELocalization.Text("Apply Reverse Leveling"), MMELocalization.Text("APPLY"))
    reverseRemoveOption = AddTextOption(MMELocalization.Text("Remove Reverse Leveling"), MMELocalization.Text("REMOVE"))
    reverseTraceOption = AddToggleOption(MMELocalization.Text("Reverse Leveling Trace"), JsonUtil.GetIntValue(SettingsFile, "enableReverseLevelTrace", 0) == 1)
EndFunction

Function DrawDebugPage()
    AddHeaderOption(MMELocalization.Text("Core / Development"))
    lifecycleDiagnosticOption = AddToggleOption(MMELocalization.Text("Location Wait Load"), JsonUtil.GetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0) == 1)
    milkmaidCreationDiagnosticOption = AddToggleOption(MMELocalization.Text("Milkmaid Creation Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 1) == 1)
    nativeScanDiagnosticOption = AddToggleOption(MMELocalization.Text("Native Actor Scan Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0) == 1)
    debugMilkingEventsOption = AddToggleOption(MMELocalization.Text("Report Milking Start/End"), JsonUtil.GetIntValue(SettingsFile, "enableMilkingEventDebug", 1) == 1)
    debugMilkReportOption = AddToggleOption(MMELocalization.Text("Milk Status Every 5 Seconds"), JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1)
    AddHeaderOption(MMELocalization.Text("Milk Drinking"))
    addMilkDebugOption = AddToggleOption(MMELocalization.Text("Milk Drinking Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1)
    breastfeedingMilkEffectsDebugOption = AddToggleOption(MMELocalization.Text("Breastfeeding Milk Effects"), JsonUtil.GetIntValue(SettingsFile, "enableBreastfeedingMilkEffectsDebug", 0) == 1)
    npcMilkConsumptionDiagnosticOption = AddToggleOption(MMELocalization.Text("NPC Milk Consumption"), JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0) == 1)
    npcDrinkNotificationsDiagnosticOption = AddToggleOption(MMELocalization.Text("NPC Drink Notifications"), JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNotificationsDiagnostic", 0) == 1)
    AddHeaderOption(MMELocalization.Text("Armor Debug"))
    armorStrippingCheckDiagnosticOption = AddToggleOption(MMELocalization.Text("Armor Stripping Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableArmorOverflowDiagnostic", 0) == 1)
    armorStripNotificationDiagnosticOption = AddToggleOption(MMELocalization.Text("Strip Notification Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNotificationDiagnostic", 0) == 1)
    armorStripMoanDiagnosticOption = AddToggleOption(MMELocalization.Text("Strip Moan Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripMoanDiagnostic", 0) == 1)
    armorStripNarrationDiagnosticOption = AddToggleOption(MMELocalization.Text("Strip Narration Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableArmorStripNarrationDiagnostic", 0) == 1)
    armorDebugOption = AddToggleOption(MMELocalization.Text("Equip Reaction Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableArmorDebug", 0) == 1)
    armorLookupForensicsOption = AddToggleOption(MMELocalization.Text("Armor Lookup Forensics"), JsonUtil.GetIntValue(SettingsFile, "enableArmorLookupForensics", 0) == 1)
    AddHeaderOption(MMELocalization.Text("A") + MMELocalization.Text("nimations "))
    milkDrinkAnimationDiagnosticOption = AddToggleOption(MMELocalization.Text("Milk Drink Animation"), JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0) == 1)
    fullnessSelfMilkAnimationDiagnosticOption = AddToggleOption(MMELocalization.Text("Fullness Animation"), JsonUtil.GetIntValue(SettingsFile, "enableFullnessSelfMilkAnimationDiagnostic", 0) == 1)
    selfMilkingActionDiagnosticOption = AddToggleOption(MMELocalization.Text("Self-Milking Action Diagnostic"), JsonUtil.GetIntValue(SettingsFile, "enableSelfMilkingActionDiagnostic", 0) == 1)
    pairedMilkingActionDiagnosticOption = AddToggleOption(MMELocalization.Text("Paired Milking Action Diagnostic"), JsonUtil.GetIntValue(SettingsFile, "enablePairedMilkingActionDiagnostic", 0) == 1)
    giveMilkActionDiagnosticOption = AddToggleOption(MMELocalization.Text("Give Milk Action Diagnostic"), JsonUtil.GetIntValue(SettingsFile, "enableGiveMilkActionDiagnostic", 0) == 1)
    SetCursorPosition(1)
    AddHeaderOption("Skyrim.Net")
    skyrimNetDrinkDiagnosticOption = AddToggleOption(MMELocalization.Text("Milk Drink Events"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetDrinkDiagnostic", 0) == 1)
    skyrimNetMilkingDiagnosticOption = AddToggleOption(MMELocalization.Text("Milking Start/End Events"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkingDiagnostic", 0) == 1)
    skyrimNetCreationDiagnosticOption = AddToggleOption(MMELocalization.Text("New Milkmaid Events"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetCreationDiagnostic", 0) == 1)
    skyrimNetStatusDiagnosticOption = AddToggleOption(MMELocalization.Text("Nearby Milk Status Events"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetStatusDiagnostic", 0) == 1)
    skyrimNetPromptDiagnosticOption = AddToggleOption(MMELocalization.Text("Milkmaid Bio Prompt"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetPromptDiagnostic", 0) == 1)
    skyrimNetOStimTraceOption = AddToggleOption(MMELocalization.Text("Skyrim.Net OStim Trace"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetOStimTrace", 0) == 1)
    skyrimNetSexLabTraceOption = AddToggleOption(MMELocalization.Text("Skyrim.Net SexLab Trace"), JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetSexLabTrace", 0) == 1)
    milkFullNarrationDiagnosticOption = AddToggleOption(MMELocalization.Text("Milk Full Narration Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableMilkFullNarrationDiagnostic", 0) == 1)
    milkHalfFullNarrationDiagnosticOption = AddToggleOption(MMELocalization.Text("Half-Full Narration Diagnostic"), JsonUtil.GetIntValue(SettingsFile, "enableMilkHalfFullNarrationDiagnostic", 0) == 1)
    playerDrinkNarrationDiagnosticOption = AddToggleOption(MMELocalization.Text("Player Drink Narration Diagnostic"), JsonUtil.GetIntValue(SettingsFile, "enablePlayerDrinkNarrationDiagnostic", 0) == 1)
    npcDrinkNarrationDiagnosticOption = AddToggleOption(MMELocalization.Text("NPC Drink Narration Diagnostics"), JsonUtil.GetIntValue(SettingsFile, "enableNPCDrinkNarrationDiagnostic", 0) == 1)
    milkmaidCreatedNarrationDiagnosticOption = AddToggleOption(MMELocalization.Text("New Milk Maid Narration Diagnostic"), JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreatedNarrationDiagnostic", 0) == 1)
    AddHeaderOption(MMELocalization.Text("Dialogue"))
    sexLabBreastfeedingDebugOption = AddToggleOption(MMELocalization.Text("SexLab Breastfeeding Debug"), JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0) == 1)
    ostimDebugOption = AddToggleOption(MMELocalization.Text("OStim Breastfeeding Debug"), JsonUtil.GetIntValue(SettingsFile, "enableOStimDebug", 0) == 1)
    newMilkmaidDialogueTraceOption = AddToggleOption(MMELocalization.Text("New Milkmaid Dialogue Trace"), JsonUtil.GetIntValue(SettingsFile, "enableNewMilkmaidDialogueTrace", 0) == 1)
    newMilkmaidSexLabTraceOption = AddToggleOption(MMELocalization.Text("New Milk Maid SexLab Trace"), JsonUtil.GetIntValue(SettingsFile, "enableNewMilkmaidSexLabTrace", 0) == 1)
    blacksmithDialogueTraceOption = AddToggleOption(MMELocalization.Text("Blacksmith Dialogue Live Trace"), JsonUtil.GetIntValue(SettingsFile, "enableBlacksmithDialogueTrace", 0) == 1)
    alchemistDialogueTraceOption = AddToggleOption(MMELocalization.Text("Alchemist Dialogue Live Trace"), JsonUtil.GetIntValue(SettingsFile, "enableAlchemistDialogueTrace", 0) == 1)
    mageDialogueTraceOption = AddToggleOption(MMELocalization.Text("Mage Dialogue Live Trace"), JsonUtil.GetIntValue(SettingsFile, "enableMageDialogueTrace", 0) == 1)
    AddHeaderOption(MMELocalization.Text("Milk Armor Thoughts"))
    milkMaidThoughtsDebugOption = AddToggleOption(MMELocalization.Text("15 Second Thoughts"), JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0) == 1)
    traceMilkMaidThoughtsLogicOption = AddToggleOption(MMELocalization.Text("Trace Thoughts Logic"), JsonUtil.GetIntValue(SettingsFile, "traceMilkMaidThoughtsLogic", 0) == 1)
EndFunction

Function DrawGeneralPage()
    AddHeaderOption(MMELocalization.Text("Framework & Integration"))
    installedBackendOption = AddTextOption(MMELocalization.Text("Installed Backend"), InstalledBackendLabel(), OPTION_FLAG_DISABLED)
    Bool ostimAvailable = MMEOStimBreastfeeding.IsOStimDetected()
    Int ostimFlags = OPTION_FLAG_DISABLED
    If ostimAvailable
        ostimFlags = OPTION_FLAG_NONE
    EndIf
    ostimStatusOption = AddToggleOption(MMELocalization.Text("OStim Detected"), ostimAvailable, OPTION_FLAG_DISABLED)
    ostimBreastfeedingOption = AddToggleOption(MMELocalization.Text("Use OStim Breastfeeding"), JsonUtil.GetIntValue(SettingsFile, "enableOStimBreastfeeding", 0) == 1, ostimFlags)
    SetCursorPosition(1)
    AddHeaderOption(MMELocalization.Text("MME Extensions"))
    masterEnableOption = AddToggleOption(MMELocalization.Text("Enable MME Extensions"), JsonUtil.GetIntValue(SettingsFile, "enableMMEExtensions", 1) == 1)
    AddHeaderOption(MMELocalization.Text("Global Audio"))
    soundsOption = AddToggleOption(MMELocalization.Text("Enable Moaning Sounds"), JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) == 1)
    volumeOption = AddSliderOption(MMELocalization.Text("Moaning Sound Volume"), JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0), "{0}%")
    newMilkMaidMoansOption = AddToggleOption(MMELocalization.Text("New Milk Maid Moans"), JsonUtil.GetIntValue(SettingsFile, "enableNewMilkMaidMoans", 1) == 1)
    MMEOriginalSettings.DrawGeneralAt(Self, 7)
    AddHeaderOption(MMELocalization.Text("Milk Maid Roster"))
    rosterEnabledOption = AddToggleOption(MMELocalization.Text("Enable Milk Maid Roster"), JsonUtil.GetIntValue(SettingsFile, "maidRosterUiEnabled", 1) == 1)
    Int rosterFlags = OPTION_FLAG_NONE
    If !RosterUiAvailable() || JsonUtil.GetIntValue(SettingsFile, "maidRosterUiEnabled", 1) != 1 || JsonUtil.GetIntValue(SettingsFile, "enableMMEExtensions", 1) != 1
        rosterFlags = OPTION_FLAG_DISABLED
    EndIf
    rosterOpenOption = AddTextOption(MMELocalization.Text("Open Milk Maid Roster"), MMELocalization.Text("OPEN"), rosterFlags)
    rosterKeyOption = AddKeyMapOption(MMELocalization.Text("Milk Maid Roster Hotkey"), JsonUtil.GetIntValue(SettingsFile, "maidRosterHotkey", -1))
EndFunction

String Function InstalledBackendLabel()
    String backend = MMESexLabBreastfeedingBackend.GetBackendName()
    If backend == "OStim-only (legacy route disabled)"
        Return "OStim-only"
    EndIf
    Return backend
EndFunction


Function DrawMilkLeakOptions()
    AddHeaderOption(MMELocalization.Text("Milk Leaking"))
    AddToggleOptionST("LeakDetected", MMELocalization.Text("Oninus Lactis Detected"), MMEMilkLeakAPI.IsDetected(), OPTION_FLAG_DISABLED)
    Int flags = OPTION_FLAG_NONE
    If !MMEMilkLeakAPI.IsDetected() || MMEMilkLeakAPI.Manager() == None
        flags = OPTION_FLAG_DISABLED
    EndIf
    AddToggleOptionST("LeakEnabled", MMELocalization.Text("Enable Milk Leaking"), JsonUtil.GetIntValue(SettingsFile, "enableMilkLeaks", 1) == 1, flags)
    AddToggleOptionST("LeakClothing", MMELocalization.Text("Leak Through Clothing"), JsonUtil.GetIntValue(SettingsFile, "milkLeakThroughClothing", 1) == 1, flags)
    AddSliderOptionST("LeakThreshold", MMELocalization.Text("Milk Fullness Threshold"), JsonUtil.GetFloatValue(SettingsFile, "milkLeakThreshold", 100.0), "{0}%", flags)
EndFunction

State LeakDetected
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Read-only detection of Oninus Lactis. If the leak controls are grey, install and enable the Milk Leaks compatibility plugin, then restart Skyrim. Detection does not certify visual alignment."))
    EndEvent
EndState


State LeakEnabled
    Event OnSelectST()
        JsonUtil.SetIntValue(SettingsFile, "enableMilkLeaks", 1 - JsonUtil.GetIntValue(SettingsFile, "enableMilkLeaks", 1))
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValueST(JsonUtil.GetIntValue(SettingsFile, "enableMilkLeaks", 1) == 1)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Optional visual-only leaks for the player and nearby MME Milk Maids. One burst per fullness crossing; no milk is removed. Existing Oninus sprays take priority."))
    EndEvent
EndState

State LeakClothing
    Event OnSelectST()
        JsonUtil.SetIntValue(SettingsFile, "milkLeakThroughClothing", 1 - JsonUtil.GetIntValue(SettingsFile, "milkLeakThroughClothing", 1))
        JsonUtil.Save(SettingsFile, False)
        SetToggleOptionValueST(JsonUtil.GetIntValue(SettingsFile, "milkLeakThroughClothing", 1) == 1)
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Slot 32 occupied means covered: Low intensity throughout. Removing clothing reveals the current taper stage. When disabled, covering the chest stops our leak."))
    EndEvent
EndState



State LeakThreshold
    Event OnSliderOpenST()
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "milkLeakThreshold", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(1.0, 100.0)
        SetSliderDialogInterval(1.0)
    EndEvent
    Event OnSliderAcceptST(Float value)
        If value < 1.0
            value = 1.0
        ElseIf value > 100.0
            value = 100.0
        EndIf
        JsonUtil.SetFloatValue(SettingsFile, "milkLeakThreshold", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValueST(value, "{0}%")
    EndEvent
    Event OnHighlightST()
        SetInfoText(MMELocalization.Text("Default 100% of MME milk capacity. At or above this threshold: 5 seconds High, 5 Medium, then sustained Low. Stops below the threshold. Interrupted leaks resume Low; loading full starts a fresh taper."))
    EndEvent
EndState

Event OnConfigClose()
    ; Publish final toggles after the paused menu closes, including master OFF.
    MMEActorPromptState.Initialize()
EndEvent
