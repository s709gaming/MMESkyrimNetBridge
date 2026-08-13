Scriptname MMEAlertsMCM extends SKI_ConfigBase

String SettingsFile = "/MMEAlerts/Settings"
Int soundsOption
Int volumeOption
Int capacityOption
Int pollingOption
Int notificationOption
Int pollingIntervalOption
Int debugMilkReportOption
Int debugDrinkDetectionOption
Int debugDrinkDiagnosticsOption

Int Function GetVersion()
    Return 12
EndFunction

Event OnConfigInit()
    ModName = "MME Alerts"
    Pages = new String[2]
    Pages[0] = "General"
    Pages[1] = "Debug"
    EnsureDefaults()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).InitializeController()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).UpdateDebugLoop()
EndEvent

Event OnVersionUpdate(Int newVersion)
    Pages = new String[2]
    Pages[0] = "General"
    Pages[1] = "Debug"
    EnsureDefaults()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).InitializeController()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).UpdateDebugLoop()
EndEvent

Function EnsureDefaults()
    If !JsonUtil.IsPendingSave(SettingsFile) && JsonUtil.GetIntValue(SettingsFile, "initialized", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "initialized", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableReactionSounds", 1)
        JsonUtil.SetFloatValue(SettingsFile, "reactionSoundVolume", 100.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityReactions", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", 1)
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", 5.0)
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityNotifications", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugMilkReport", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 1)
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
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 1)
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

Event OnPageReset(String page)
    EnsureDefaults()
    soundsOption = -1
    volumeOption = -1
    capacityOption = -1
    pollingOption = -1
    pollingIntervalOption = -1
    notificationOption = -1
    debugMilkReportOption = -1
    debugDrinkDetectionOption = -1
    debugDrinkDiagnosticsOption = -1
    SetCursorFillMode(TOP_TO_BOTTOM)
    If page == "Debug"
        AddHeaderOption("Development Diagnostics")
        debugMilkReportOption = AddToggleOption("Milk Status Every 5 Seconds", JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1)
        debugDrinkDetectionOption = AddToggleOption("Report Detected Milk Drinking", JsonUtil.GetIntValue(SettingsFile, "enableDrinkDetectionDebug", 1) == 1)
        debugDrinkDiagnosticsOption = AddToggleOption("Drink Tracker Diagnostics", JsonUtil.GetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 1) == 1)
        Return
    EndIf
    AddHeaderOption("Sounds")
    soundsOption = AddToggleOption("Enable Reaction Sounds", JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) == 1)
    volumeOption = AddSliderOption("Reaction Sound Volume", JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0), "{0}%")
    AddHeaderOption("Capacity Tracker")
    capacityOption = AddToggleOption("Enable 50% Capacity Reactions", JsonUtil.GetIntValue(SettingsFile, "enableCapacityReactions", 1) == 1)
    pollingOption = AddToggleOption("Enable Capacity Polling", JsonUtil.GetIntValue(SettingsFile, "enableCapacityPolling", 1) == 1)
    pollingIntervalOption = AddSliderOption("Capacity Polling Interval", JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 5.0), "{0} seconds")
    notificationOption = AddToggleOption("Enable Capacity Notifications", JsonUtil.GetIntValue(SettingsFile, "enableCapacityNotifications", 1) == 1)
EndEvent

Event OnOptionSelect(Int option)
    If option == soundsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableReactionSounds", value)
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
    ElseIf option == debugDrinkDetectionOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDrinkDetectionDebug", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkDetectionDebug", value)
        SetToggleOptionValue(option, value == 1)
    ElseIf option == debugDrinkDiagnosticsOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDrinkTrackerDiagnostics", value)
        SetToggleOptionValue(option, value == 1)
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).UpdateDebugLoop()
    EndIf
    JsonUtil.Save(SettingsFile, False)
EndEvent

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
    EndIf
EndEvent

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
    EndIf
EndEvent
