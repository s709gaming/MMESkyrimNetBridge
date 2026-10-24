Scriptname MMEBodyEffects Hidden

; Player-only, opt-in replacements for MME's original unmilked speed and
; carry-weight penalties.  Both features default off and never change MME's
; own settings, so users can choose which implementation owns each penalty.

String Function SettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

String Function SpeedOwnedKey() Global
    Return "MMEExtensions.Body.SpeedPenalty"
EndFunction

String Function WeightOwnedKey() Global
    Return "MMEExtensions.Body.CarryPenalty"
EndFunction

String Function SpeedDisplayKey() Global
    Return "MMEExtensions.Body.SpeedDisplay"
EndFunction

String Function WeightDisplayKey() Global
    Return "MMEExtensions.Body.WeightDisplay"
EndFunction

Bool Function IsAnyFeatureEnabled() Global
    String settings = SettingsFile()
    Return JsonUtil.GetIntValue(settings, "enableCustomMilkSpeedDebuff", 0) == 1 || JsonUtil.GetIntValue(settings, "enableCustomMilkWeight", 0) == 1
EndFunction

Float Function GetUpdateInterval() Global
    Return 15.0
EndFunction

Function Reconcile(String source = "unspecified") Global
    Actor player = Game.GetPlayer()
    If player == None
        AlarmOnce("player", "reconcile failed; player unavailable | source=" + source)
        Return
    EndIf

    If JsonUtil.GetIntValue(SettingsFile(), "enableMMEExtensions", 1) != 1
        ClearOwnedEffects(player, source + "; Extensions disabled")
        Return
    EndIf

    MilkQUEST controller = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If controller == None
        ClearOwnedEffects(player, source + "; MME controller unavailable")
        AlarmOnce("controller", "MME controller unavailable; custom body penalties were removed")
        Return
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(player, controller)
        ClearOwnedEffects(player, source + "; player is not a Milk Maid")
        Return
    EndIf

    Float maximum = MME_Storage.getMilkMaximum(player)
    If maximum <= 0.0
        ClearOwnedEffects(player, source + "; invalid capacity")
        AlarmOnce("capacity", "MME returned an invalid maximum milk capacity; custom body penalties were removed")
        Return
    EndIf

    Float current = MME_Storage.getMilkCurrent(player)
    If current < 0.0
        current = 0.0
    EndIf
    Float fullness = (current / maximum) * 100.0
    If fullness < 0.0
        fullness = 0.0
    ElseIf fullness > 100.0
        fullness = 100.0
    EndIf

    String settings = SettingsFile()
    Float speedPenalty = 0.0
    String tier = "none"
    If JsonUtil.GetIntValue(settings, "enableCustomMilkSpeedDebuff", 0) == 1
        Float mediumThreshold = Clamp(JsonUtil.GetFloatValue(settings, "milkSpeedMediumThreshold", 50.0), 0.0, 100.0)
        Float highThreshold = Clamp(JsonUtil.GetFloatValue(settings, "milkSpeedHighThreshold", 100.0), mediumThreshold, 100.0)
        If fullness >= highThreshold
            tier = "high"
            speedPenalty = Clamp(JsonUtil.GetFloatValue(settings, "milkSpeedHighPenalty", 10.0), 0.0, 100.0)
        ElseIf fullness >= mediumThreshold
            tier = "medium"
            speedPenalty = Clamp(JsonUtil.GetFloatValue(settings, "milkSpeedMediumPenalty", 3.0), 0.0, 100.0)
        EndIf
        If speedPenalty > 0.0 && JsonUtil.GetIntValue(settings, "enableMaidLevelSpeedScaling", 0) == 1
            Int maidLevel = MME_Storage.getMaidLevel(player)
            If maidLevel < 0
                maidLevel = 0
            ElseIf maidLevel > 100
                maidLevel = 100
            EndIf
            speedPenalty *= 1.0 + (maidLevel as Float / 100.0)
            speedPenalty = Clamp(speedPenalty, 0.0, 100.0)
        EndIf
    EndIf

    Float carryPenalty = 0.0
    If JsonUtil.GetIntValue(settings, "enableCustomMilkWeight", 0) == 1
        Float multiplier = Clamp(JsonUtil.GetFloatValue(settings, "milkWeightMultiplier", 1.0), 1.0, 10.0)
        carryPenalty = current * multiplier
        If carryPenalty < 0.0
            carryPenalty = 0.0
        EndIf
    EndIf

    ApplyOwnedModifier(player, "SpeedMult", SpeedOwnedKey(), speedPenalty)
    ApplyOwnedModifier(player, "CarryWeight", WeightOwnedKey(), carryPenalty)
    RefreshDisplayEffects(player, speedPenalty, carryPenalty)
    Trace("reconciled | milk=" + current + "/" + maximum + " | fullness=" + fullness + "% | tier=" + tier + " | speed=" + speedPenalty + "% | carry=" + carryPenalty + " | source=" + source)
EndFunction

Function ApplyOwnedModifier(Actor player, String actorValue, String keyName, Float requestedPenalty) Global
    Float previousPenalty = StorageUtil.GetFloatValue(None, keyName, 0.0)
    If previousPenalty > 0.0
        player.ModActorValue(actorValue, previousPenalty)
    EndIf
    If requestedPenalty > 0.0
        player.ModActorValue(actorValue, 0.0 - requestedPenalty)
        StorageUtil.SetFloatValue(None, keyName, requestedPenalty)
    Else
        StorageUtil.UnsetFloatValue(None, keyName)
    EndIf
EndFunction

Function ClearOwnedEffects(Actor player, String source = "unspecified") Global
    If player == None
        Return
    EndIf
    Float previousSpeed = StorageUtil.GetFloatValue(None, SpeedOwnedKey(), 0.0)
    Float previousWeight = StorageUtil.GetFloatValue(None, WeightOwnedKey(), 0.0)
    If previousSpeed > 0.0
        player.ModActorValue("SpeedMult", previousSpeed)
        StorageUtil.UnsetFloatValue(None, SpeedOwnedKey())
    EndIf
    If previousWeight > 0.0
        player.ModActorValue("CarryWeight", previousWeight)
        StorageUtil.UnsetFloatValue(None, WeightOwnedKey())
    EndIf
    RefreshDisplayEffects(player, 0.0, 0.0)
    If previousSpeed > 0.0 || previousWeight > 0.0
        Trace("owned penalties removed | speed=" + previousSpeed + " | carry=" + previousWeight + " | source=" + source)
    EndIf
EndFunction

Function RefreshDisplayEffects(Actor player, Float speedPenalty, Float carryPenalty) Global
    RefreshOneDisplay(player, 0x0008C1, "Milk Burden", SpeedDisplayKey(), speedPenalty)
    RefreshOneDisplay(player, 0x0008C3, "Milk Weight", WeightDisplayKey(), carryPenalty)
EndFunction

Function RefreshOneDisplay(Actor player, Int localFormID, String displayName, String displayKey, Float magnitude) Global
    Spell displayAbility = Game.GetFormFromFile(localFormID, "MMEAlert.esp") as Spell
    If displayAbility == None
        If magnitude > 0.0
            AlarmOnce("display-" + localFormID, displayName + " display ability " + localFormID + " did not resolve")
        EndIf
        Return
    EndIf

    Float previousMagnitude = StorageUtil.GetFloatValue(None, displayKey, 0.0)
    Bool magnitudeChanged = previousMagnitude < (magnitude - 0.001) || previousMagnitude > (magnitude + 0.001)
    If magnitude <= 0.0
        If player.HasSpell(displayAbility)
            player.RemoveSpell(displayAbility)
        EndIf
        StorageUtil.UnsetFloatValue(None, displayKey)
        If previousMagnitude > 0.0
            Trace(displayName + " display removed | previous=" + previousMagnitude)
        EndIf
        Return
    EndIf

    If magnitudeChanged || !player.HasSpell(displayAbility)
        If player.HasSpell(displayAbility)
            player.RemoveSpell(displayAbility)
        EndIf
        displayAbility.SetNthEffectMagnitude(0, magnitude)
        If player.AddSpell(displayAbility, False)
            StorageUtil.SetFloatValue(None, displayKey, magnitude)
            Trace(displayName + " display updated | magnitude=" + magnitude)
        Else
            AlarmOnce("display-add-" + localFormID, displayName + " display ability could not be added")
        EndIf
    EndIf
EndFunction

Float Function Clamp(Float value, Float minimum, Float maximum) Global
    If value < minimum
        Return minimum
    ElseIf value > maximum
        Return maximum
    EndIf
    Return value
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Body] " + detail)
EndFunction

Function AlarmOnce(String keyName, String detail) Global
    String alarmKey = "MMEExtensions.Body.Alarm." + keyName
    If StorageUtil.GetIntValue(None, alarmKey, 0) == 0
        StorageUtil.SetIntValue(None, alarmKey, 1)
        MMELog.Alarm("[MME Extensions Body] FAILURE: " + detail)
    EndIf
EndFunction
