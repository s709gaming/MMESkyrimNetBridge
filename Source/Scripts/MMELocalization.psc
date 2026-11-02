Scriptname MMELocalization Hidden

; Language data only. Never changes gameplay, settings, actor identity or presets.
Function Initialize() Global
    StorageUtil.SetIntValue(None, "MME.Localization.Ready", 1)
    If SKSE.GetPluginVersion("MMEExtensions") < 0
        Alarm("required MMEExtensions DLL is unavailable")
        Return
    EndIf
    StorageUtil.SetIntValue(None, "MME.Localization.MissingReported", 0)
    MMEExtensionsNative.ReloadLocalization()
    String failure = MMEExtensionsNative.GetLocalizationError()
    If failure != ""
        Alarm(failure)
    Else
        StorageUtil.UnsetStringValue(None, "MME.Localization.LastFailure")
    EndIf
    MMELog.MasterDiagnostic("[MME Localization] initialized | language=" + MMEExtensionsNative.GetLocalizationLanguage() + " | English fallback=" + (failure != ""))
EndFunction

String Function Text(String english) Global
    If StorageUtil.GetIntValue(None, "MME.Localization.Ready", 0) != 1
        Initialize()
    EndIf
    If SKSE.GetPluginVersion("MMEExtensions") < 0
        Return english
    EndIf
    String translated = MMEExtensionsNative.Localize(english)
    If translated == "" && english != ""
        If StorageUtil.GetIntValue(None, "MME.Localization.MissingReported", 0) == 0
            StorageUtil.SetIntValue(None, "MME.Localization.MissingReported", 1)
            Alarm("missing Russian text; using English | entry=" + StringUtil.Substring(english, 0, 80))
        EndIf
        Return english
    EndIf
    Return translated
EndFunction

Function Alarm(String reason) Global
    If StorageUtil.GetStringValue(None, "MME.Localization.LastFailure", "") != reason
        StorageUtil.SetStringValue(None, "MME.Localization.LastFailure", reason)
        MMELog.Alarm("[MME Localization] language load/lookup failed | actor=N/A | " + reason)
    EndIf
EndFunction
