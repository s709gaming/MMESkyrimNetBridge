Scriptname MMEFixedLactacid Hidden

; Fixed-mode fuel: one stored unit lasts one simulated MME hour. No inventory,
; actor registration, dynamic MilkGen writes, timers or persistent actor indices.
Bool Function IsEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableFixedLactacidBoost", 1) == 1
EndFunction

Float Function BonusPercent() Global
    Float percent = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "fixedLactacidBonusPercent", 50.0)
    Bool invalid = percent < 0.0 || percent > 200.0
    Failure("percent", invalid, None, "read production bonus", "percentage outside 0-200: " + percent)
    If invalid
        Return 50.0
    EndIf
    Return percent
EndFunction

Function EnsureDefaults() Global
    String settingsFile = "/MMEAlerts/Settings"
    Bool changed = False
    If !JsonUtil.HasIntValue(settingsFile, "enableFixedLactacidBoost")
        JsonUtil.SetIntValue(settingsFile, "enableFixedLactacidBoost", 1)
        changed = True
    EndIf
    If !JsonUtil.HasFloatValue(settingsFile, "fixedLactacidBonusPercent")
        JsonUtil.SetFloatValue(settingsFile, "fixedLactacidBonusPercent", 50.0)
        changed = True
    EndIf
    If changed
        Bool saved = JsonUtil.Save(settingsFile, False)
        Failure("save", !saved, None, "initialize settings", "settings JSON could not be saved")
        MMELog.MasterDiagnostic("[MME Fixed Lactacid] initialized missing settings | saved=" + saved)
    EndIf
EndFunction

Function SetEnabled(Bool enabled) Global
    Int enabledValue = 0
    If enabled
        enabledValue = 1
    EndIf
    JsonUtil.SetIntValue("/MMEAlerts/Settings", "enableFixedLactacidBoost", enabledValue)
    Bool saved = JsonUtil.Save("/MMEAlerts/Settings", False)
    Failure("save", !saved, None, "set enabled", "settings JSON could not be saved")
    MMELog.MasterDiagnostic("[MME Fixed Lactacid] setting | enabled=" + enabled + " | saved=" + saved)
EndFunction

Function SetBonusPercent(Float percent) Global
    If percent < 0.0
        percent = 0.0
    ElseIf percent > 200.0
        percent = 200.0
    EndIf
    JsonUtil.SetFloatValue("/MMEAlerts/Settings", "fixedLactacidBonusPercent", percent)
    Bool saved = JsonUtil.Save("/MMEAlerts/Settings", False)
    Failure("save", !saved, None, "set production bonus", "settings JSON could not be saved")
    MMELog.MasterDiagnostic("[MME Fixed Lactacid] setting | bonusPercent=" + percent + " | saved=" + saved)
EndFunction

; Pure production calculation, also used by original MME's hourly MCM preview.
; Caller chooses the fixed branch. Only hours with fuel receive the bonus.
Float Function BonusMilk(Actor target, Float normalMilk, Float lactacid, Int hours) Global
    Bool invalid = target == None || normalMilk < 0.0 || lactacid < 0.0 || hours < 0
    Failure("input", invalid, target, "calculate fixed production bonus", "invalid actor, milk, Lactacid or elapsed hours")
    If invalid || hours == 0 || lactacid == 0.0 || !IsEnabled()
        Return 0.0
    EndIf
    Float activeHours = lactacid
    If activeHours > hours
        activeHours = hours
    EndIf
    Return normalMilk * (activeHours / hours) * (BonusPercent() / 100.0)
EndFunction

Function TraceCycle(Actor target, Float before, Float after, Int elapsedHours, Float bonusMilk) Global
    If before > 0.0
        MMELog.MasterDiagnostic("[MME Fixed Lactacid] cycle | actor=" + target + " | eligible=fixed+enabled | elapsedHours=" + elapsedHours + " | before=" + before + " | remaining=" + after + " | bonusMilk=" + bonusMilk + " | expired=" + (after <= 0.0))
    EndIf
EndFunction

Function Failure(String reasonKey, Bool failed, Actor target, String operation, String reason) Global
    String alarmKey = "MMEExtensions.FixedLactacid.Alarm." + reasonKey
    If failed
        If StorageUtil.GetIntValue(None, alarmKey, 0) == 0
            MMELog.Alarm("[MME Fixed Lactacid] failure | operation=" + operation + " | actor=" + target + " | reason=" + reason)
            StorageUtil.SetIntValue(None, alarmKey, 1)
        EndIf
    ElseIf StorageUtil.GetIntValue(None, alarmKey, 0) != 0
        StorageUtil.SetIntValue(None, alarmKey, 0)
    EndIf
EndFunction
