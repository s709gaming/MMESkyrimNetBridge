Scriptname MMEAlertsMCM extends SKI_ConfigBase

String SettingsFile = "/MMEAlerts/Settings"
Int soundsOption
Int volumeOption
Int capacityOption
Int debugLoopOption
Int debugSoundOption

Int Function GetVersion()
    Return 6
EndFunction

Event OnConfigInit()
    ModName = "MME Alerts"
    EnsureDefaults()
    (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController).InitializeController()
EndEvent

Event OnVersionUpdate(Int newVersion)
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
        JsonUtil.SetIntValue(SettingsFile, "enableCapacityPolling", 0)
        JsonUtil.SetFloatValue(SettingsFile, "pollingInterval", 15.0)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugSoundLoop", 1)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugSoundTest", 0)
        JsonUtil.Save(SettingsFile, False)
    EndIf
    ; Version-five migration: enable the recognition diagnostic once for existing
    ; test installs. The player may turn it off afterward and that choice persists.
    If JsonUtil.GetIntValue(SettingsFile, "recognitionDebugDefaultApplied", 0) == 0
        JsonUtil.SetIntValue(SettingsFile, "enableDebugSoundLoop", 1)
        JsonUtil.SetIntValue(SettingsFile, "recognitionDebugDefaultApplied", 1)
        JsonUtil.Save(SettingsFile, False)
    EndIf
EndFunction

Event OnPageReset(String page)
    EnsureDefaults()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Sounds")
    soundsOption = AddToggleOption("Enable Reaction Sounds", JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) == 1)
    volumeOption = AddSliderOption("Reaction Sound Volume", JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0), "{0}%")
    AddHeaderOption("Capacity Tracker")
    capacityOption = AddToggleOption("Enable 50% Capacity Reactions", JsonUtil.GetIntValue(SettingsFile, "enableCapacityReactions", 1) == 1)
    AddHeaderOption("Debug")
    debugLoopOption = AddToggleOption("Debug Milk Report Every 5 Seconds", JsonUtil.GetIntValue(SettingsFile, "enableDebugSoundLoop", 0) == 1)
    debugSoundOption = AddToggleOption("Debug Test Reaction Sound", JsonUtil.GetIntValue(SettingsFile, "enableDebugSoundTest", 0) == 1)
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
    ElseIf option == debugLoopOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDebugSoundLoop", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugSoundLoop", value)
        SetToggleOptionValue(option, value == 1)
        (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).UpdateDebugLoop()
    ElseIf option == debugSoundOption
        Int value = 1 - JsonUtil.GetIntValue(SettingsFile, "enableDebugSoundTest", 0)
        JsonUtil.SetIntValue(SettingsFile, "enableDebugSoundTest", value)
        SetToggleOptionValue(option, value == 1)
        If value == 1
            (Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug).TestReactionSound()
        EndIf
    EndIf
    JsonUtil.Save(SettingsFile, False)
EndEvent

Event OnOptionSliderOpen(Int option)
    If option == volumeOption
        SetSliderDialogStartValue(JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0))
        SetSliderDialogDefaultValue(100.0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)
    EndIf
EndEvent

Event OnOptionSliderAccept(Int option, Float value)
    If option == volumeOption
        JsonUtil.SetFloatValue(SettingsFile, "reactionSoundVolume", value)
        JsonUtil.Save(SettingsFile, False)
        SetSliderOptionValue(option, value, "{0}%")
    EndIf
EndEvent
