Scriptname MMEMilkBoost extends Quest

; Applies the configured bonus through MME's capacity-enforcing storage API.
Function ApplyMilkDrinkBonus(Actor drinker, Int drinkKind) Global
    String settingsFile = "/MMEAlerts/Settings"
    Bool showDebug = JsonUtil.GetIntValue(settingsFile, "enableAddMilkDebug", 0) == 1
    If drinker == None || drinker != Game.GetPlayer()
        If showDebug
            Debug.Notification("Milk Debug: boost failed (drinker is not player)")
        EndIf
        Return
    EndIf
    ApplyMilkDrinkBonusForActor(drinker, drinkKind, showDebug)
EndFunction

; Shared actor-safe calculation used by validated player and NPC entry points.
Float Function ApplyMilkDrinkBonusForActor(Actor drinker, Int drinkKind, Bool showDebug = False) Global
    String settingsFile = "/MMEAlerts/Settings"
    If drinker == None
        Return 0.0
    EndIf
    If !StorageUtil.HasFloatValue(drinker, "MME.MilkMaid.Level")
        If showDebug
            Debug.Notification("Milk Debug: boost failed (player is not an MME Milkmaid)")
        EndIf
        Return 0.0
    EndIf

    Float flatBonus = JsonUtil.GetFloatValue(settingsFile, "flatMilkBonus", 1.0)
    Float milkAdded = flatBonus
    Int maidLevel = MME_Storage.getMaidLevel(drinker)
    Float levelBonus = 0.0
    Float lactacidMultiplier = 1.0
    Bool levelBonusEnabled = JsonUtil.GetIntValue(settingsFile, "enableMilkmaidLevelBonus", 1) == 1
    String calculationMode = "level bonus OFF"
    If drinkKind == 2
        lactacidMultiplier = JsonUtil.GetFloatValue(settingsFile, "lactacidFlatMultiplier", 2.0)
        milkAdded = flatBonus * lactacidMultiplier
        calculationMode = "Lactacid x" + lactacidMultiplier
    EndIf
    If levelBonusEnabled
        levelBonus = maidLevel as Float / 2.0
        milkAdded += levelBonus
        If drinkKind == 2
            calculationMode = "Lactacid x" + lactacidMultiplier + " + level"
        Else
            calculationMode = "MME level ON"
        EndIf
    EndIf

    If showDebug
        Debug.Notification("Milk Debug: " + calculationMode + " | level " + maidLevel + " | flat +" + flatBonus + " | level +" + levelBonus + " | total +" + milkAdded)
    EndIf

    If milkAdded > 0.0
        ; True asks MME to clamp the new value to its normal capacity limit.
        Float milkBefore = MME_Storage.getMilkCurrent(drinker)
        MME_Storage.changeMilkCurrent(drinker, milkAdded, True)
        Float milkAfter = MME_Storage.getMilkCurrent(drinker)
        If showDebug
            Debug.Notification("Milk Debug: MME add called | " + milkBefore + " -> " + milkAfter + " (wanted +" + milkAdded + ")")
        EndIf
        Debug.Trace("[MMEAlert MilkBoost] Requested +" + milkAdded + " milk for the player")
        Return milkAfter - milkBefore
    ElseIf showDebug
        Debug.Notification("Milk Debug: MME add not called (total is zero)")
    EndIf
    Return 0.0
EndFunction
