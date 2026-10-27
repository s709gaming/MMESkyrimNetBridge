Scriptname MMEDungeonChestConversion Hidden

; Handles the gameplay side of native treasure-chest activation events. The
; DLL identifies curated boss and ordinary treasure families; this script owns
; category settings, chance, per-reference one-shot state, and conversion.
Int Function HandleActivation(Actor targetActor, String chestIdentity, Bool bossChest) Global
    String settingsFile = "/MMEAlerts/Settings"
    If !MMEAlertsController.IsExtensionsEnabled()
        Return 0
    EndIf
    String chestKind = "regular"
    String enabledKey = "enableRegularChestMilkMaid"
    String chanceKey = "regularChestMilkMaidChance"
    Int defaultChance = 10
    If bossChest
        chestKind = "boss"
        enabledKey = "enableDungeonChestMilkMaid"
        chanceKey = "dungeonChestMilkMaidChance"
        defaultChance = 100
    EndIf
    If JsonUtil.GetIntValue(settingsFile, enabledKey, 1) != 1
        Return 0
    EndIf
    If targetActor == None || chestIdentity == ""
        Report("ignored malformed activation")
        Return 0
    EndIf

    String resolvedKey = "MMEExtensions.DungeonChest.Resolved." + chestIdentity
    String pendingKey = "MMEExtensions.DungeonChest.Pending." + chestIdentity
    If StorageUtil.GetIntValue(None, resolvedKey, 0) == 1
        Return 0
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float pendingAt = StorageUtil.GetFloatValue(None, pendingKey + ".Time", -1.0)
    If StorageUtil.GetIntValue(None, pendingKey, 0) == 1 && pendingAt >= 0.0 && now >= pendingAt && now - pendingAt < 60.0
        Report("skip pending curse | chest=" + chestIdentity)
        Return 1
    EndIf

    ; Eligibility is established before rolling. Existing Milk Maids are
    ; excluded individually, allowing the curse to leap to another nearby
    ; allied woman without consuming this chest's one-shot conversion roll.
    Actor conversionTarget = MMEChestTrapTargets.SelectTarget(targetActor, 2, 1500.0)
    Bool surge = False
    If conversionTarget == None && JsonUtil.GetIntValue(settingsFile, "milkMaidCurseSurgePercent", 50) > 0
        conversionTarget = MMEChestTrapTargets.SelectTarget(targetActor, 4, 1500.0)
        surge = conversionTarget != None
    EndIf
    If conversionTarget == None
        Report("curse skipped; no eligible allied conversion or surge target | kind=" + chestKind + " | chest=" + chestIdentity)
        Return 0
    EndIf

    Int chance = JsonUtil.GetIntValue(settingsFile, chanceKey, defaultChance)
    If chance < 0
        chance = 0
    ElseIf chance > 100
        chance = 100
    EndIf
    If chance == 0 || Utility.RandomInt(1, 100) > chance
        ; Resolve a failed roll permanently so repeatedly opening one chest
        ; cannot be used to reroll the configured probability.
        StorageUtil.SetIntValue(None, resolvedKey, 1)
        Report("chance missed | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(conversionTarget) + " | chance=" + chance)
        Return 0
    EndIf

    StorageUtil.SetIntValue(None, pendingKey, 1)
    StorageUtil.SetFloatValue(None, pendingKey + ".Time", now)
    Report("curse requested | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(conversionTarget) + " | chance=" + chance)
    Bool created = False
    Report("selected outcome | surge=" + surge + " | actor=" + conversionTarget)
    If surge
        created = MMEMilkCurse.ApplySurge(conversionTarget, JsonUtil.GetIntValue(settingsFile, "milkMaidCurseSurgePercent", 50), resolvedKey)
    Else
        created = MMENewMilkMaid.TryCreateMilkMaidWithContext(conversionTarget, True, resolvedKey)
    EndIf
    StorageUtil.UnsetIntValue(None, pendingKey)
    StorageUtil.UnsetFloatValue(None, pendingKey + ".Time")
    If created || StorageUtil.GetIntValue(None, resolvedKey, 0) == 1
        StorageUtil.SetIntValue(None, resolvedKey, 1)
        Report("curse complete | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(conversionTarget))
        Return 1
    Else
        ; Capacity and temporary actor-state failures do not consume the chest.
        ; It may be tried again after the underlying condition is corrected.
        Report("curse rejected | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(conversionTarget))
    EndIf
    Return 0
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<missing actor>"
    EndIf
    String actorName = target.GetDisplayName()
    If actorName == ""
        ActorBase baseInfo = target.GetLeveledActorBase()
        If baseInfo != None
            actorName = baseInfo.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

Function Report(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Dungeon Chest] " + detail)
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableForcedMilkMaidDiagnostic", 0) == 1
        MMELog.Diagnostic("[MME Extensions Dungeon Chest Detail] " + detail)
    EndIf
EndFunction
