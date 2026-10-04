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
    If StorageUtil.GetIntValue(None, resolvedKey, 0) == 1 || StorageUtil.GetIntValue(None, pendingKey, 0) == 1
        Return 0
    EndIf

    ; Eligibility is established before rolling. Existing Milk Maids are
    ; excluded individually, allowing the curse to leap to another nearby
    ; allied woman without consuming this chest's one-shot conversion roll.
    Actor conversionTarget = MMEChestTrapTargets.SelectTarget(targetActor, 2, 1500.0)
    If conversionTarget == None
        Report("conversion skipped; no eligible nearby allied non-Milk-Maid | kind=" + chestKind + " | chest=" + chestIdentity)
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
    Report("conversion requested | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(conversionTarget) + " | chance=" + chance)
    Bool created = MMEExtensionsAPI.TryCreateMilkMaidForcedAnimated(conversionTarget)
    StorageUtil.UnsetIntValue(None, pendingKey)
    If created
        StorageUtil.SetIntValue(None, resolvedKey, 1)
        Report("conversion complete | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(conversionTarget))
        Return 1
    Else
        ; Capacity and temporary actor-state failures do not consume the chest.
        ; It may be tried again after the underlying condition is corrected.
        Report("conversion rejected | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(conversionTarget))
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
