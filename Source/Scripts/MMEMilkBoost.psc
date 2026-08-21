Scriptname MMEMilkBoost extends Quest

; Calculates Extensions drink bonuses but commits them only through MME_Storage.
; MME remains authoritative for limits, current size, and Milk Maid state.

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
    ; Phase 1: require MME's level key, then calculate the configured flat,
    ; Lactacid, and optional maid-level components without changing state.
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

    ; Phase 2: snapshot capacity before the enforcing MME write. When the desired
    ; result exceeds maximum, preserve that attempt for the delayed overflow/leak
    ; reconciliation because the stored post-write value may already be clamped.
    If milkAdded > 0.0
        ; MME's changeMilkCurrent boolean is a direct enforcement switch; it
        ; does not read the MCM option itself. Mirror the current MME setting.
        MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
        Bool enforceMilkLimit = milkController != None && milkController.BreastScaleLimit
        Float milkBefore = MME_Storage.getMilkCurrent(drinker)
        Float attemptedMilk = milkBefore + milkAdded
        Bool attemptedOverflow = False
        If milkController != None
            Float milkMaximum = MME_Storage.getMilkMaximum(drinker)
            attemptedOverflow = milkMaximum > 0.0 && attemptedMilk > milkMaximum
        EndIf
        ; Preserve the attempted post-drink value independently of MME's real
        ; stored value. Only the delayed armor threshold check uses this value.
        MMEArmorScript.MarkPlayerDrinkAttempt(drinker, attemptedMilk, attemptedOverflow)
        MME_Storage.changeMilkCurrent(drinker, milkAdded, enforceMilkLimit)
        ; Phase 3: refresh MME visual size only after a real stored increase and
        ; return the actual delta, not the requested amount.
        Float milkAfter = MME_Storage.getMilkCurrent(drinker)
        If milkAfter > milkBefore
            If milkController != None
                milkController.CurrentSize(drinker)
            EndIf
        EndIf
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
