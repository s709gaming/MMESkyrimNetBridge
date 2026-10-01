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

    ; An already registered Milk Maid cannot benefit from this conversion.
    ; Resolve the chest quietly so repeated activation cannot spam the generic
    ; forced-conversion rejection notification. Report() keeps the reason in
    ; the existing Papyrus diagnostic channels without adding another toggle.
    If MMEExtensionsAPI.IsMilkMaid(targetActor)
        StorageUtil.SetIntValue(None, resolvedKey, 1)
        Report("conversion skipped because target is already a Milk Maid | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(targetActor))
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
        Report("chance missed | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(targetActor) + " | chance=" + chance)
        Return 0
    EndIf

    StorageUtil.SetIntValue(None, pendingKey, 1)
    Report("conversion requested | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(targetActor) + " | chance=" + chance)
    Bool created = MMEExtensionsAPI.TryCreateMilkMaidForcedAnimated(targetActor)
    StorageUtil.UnsetIntValue(None, pendingKey)
    If created
        StorageUtil.SetIntValue(None, resolvedKey, 1)
        Report("conversion complete | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(targetActor))
        Return 1
    Else
        ; Capacity and temporary actor-state failures do not consume the chest.
        ; It may be tried again after the underlying condition is corrected.
        Report("conversion rejected | kind=" + chestKind + " | chest=" + chestIdentity + " | target=" + GetActorName(targetActor))
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
